import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { AuditStatus, Prisma, type Role } from '@prisma/client';
import { AuditLogsService } from '../audit-logs/audit-logs.service';
import { PrismaService } from '../../prisma/prisma.service';
import { AssignRolePermissionsDto } from './dto/assign-role-permissions.dto';
import { CreateRoleDto } from './dto/create-role.dto';
import { ListRolesDto } from './dto/list-roles.dto';
import { UpdateRoleDto } from './dto/update-role.dto';

@Injectable()
export class RolesService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly auditLogsService: AuditLogsService,
  ) {}

  async create(createRoleDto: CreateRoleDto, actorUserId: string) {
    try {
      const role = await this.prisma.$transaction(async (tx) => {
        const createdRole = await tx.role.create({
          data: {
            code: createRoleDto.code,
            name: createRoleDto.name,
            description: createRoleDto.description,
            isActive: createRoleDto.isActive ?? true,
            createdById: actorUserId,
            updatedById: actorUserId,
          },
        });

        if (createRoleDto.permissionIds) {
          await this.syncRolePermissions(
            tx,
            createdRole.id,
            createRoleDto.permissionIds,
            actorUserId,
          );
        }

        return tx.role.findUniqueOrThrow({
          where: { id: createdRole.id },
          include: {
            rolePermissions: {
              where: {
                deletedAt: null,
              },
              include: {
                permission: true,
              },
            },
          },
        });
      });

      await this.auditLogsService.record({
        actorUserId,
        action: 'ROLE_CREATE',
        resource: 'roles',
        resourceId: role.id,
        details: {
          code: role.code,
          permissionsCount: role.rolePermissions.length,
        },
      });

      return role;
    } catch (error) {
      await this.auditLogsService.record({
        actorUserId,
        action: 'ROLE_CREATE_FAILED',
        resource: 'roles',
        status: AuditStatus.FAILURE,
        details: {
          code: createRoleDto.code,
          reason: this.extractErrorMessage(error),
        },
      });

      this.throwKnownDatabaseErrors(error);
    }
  }

  async findAll(query: ListRolesDto) {
    const page = query.page ?? 1;
    const limit = query.limit ?? 20;

    const where: Prisma.RoleWhereInput = {
      deletedAt: null,
      OR: query.search
        ? [
            { code: { contains: query.search } },
            { name: { contains: query.search } },
            { description: { contains: query.search } },
          ]
        : undefined,
    };

    const [total, items] = await this.prisma.$transaction([
      this.prisma.role.count({ where }),
      this.prisma.role.findMany({
        where,
        orderBy: {
          createdAt: 'desc',
        },
        skip: (page - 1) * limit,
        take: limit,
        include: {
          rolePermissions: {
            where: {
              deletedAt: null,
            },
            include: {
              permission: true,
            },
          },
        },
      }),
    ]);

    return {
      data: items,
      pagination: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  async findOne(id: string) {
    return this.getRoleOrFail(id);
  }

  async update(id: string, updateRoleDto: UpdateRoleDto, actorUserId: string) {
    await this.ensureRoleExists(id);

    try {
      const role = await this.prisma.$transaction(async (tx) => {
        await tx.role.update({
          where: { id },
          data: {
            code: updateRoleDto.code,
            name: updateRoleDto.name,
            description: updateRoleDto.description,
            isActive: updateRoleDto.isActive,
            updatedById: actorUserId,
          },
        });

        if (updateRoleDto.permissionIds) {
          await this.syncRolePermissions(
            tx,
            id,
            updateRoleDto.permissionIds,
            actorUserId,
          );
        }

        return tx.role.findUniqueOrThrow({
          where: { id },
          include: {
            rolePermissions: {
              where: {
                deletedAt: null,
              },
              include: {
                permission: true,
              },
            },
          },
        });
      });

      await this.auditLogsService.record({
        actorUserId,
        action: 'ROLE_UPDATE',
        resource: 'roles',
        resourceId: role.id,
        details: updateRoleDto as Prisma.InputJsonValue,
      });

      return role;
    } catch (error) {
      this.throwKnownDatabaseErrors(error);
    }
  }

  async assignPermissions(
    roleId: string,
    payload: AssignRolePermissionsDto,
    actorUserId: string,
  ) {
    await this.ensureRoleExists(roleId);

    const role = await this.prisma.$transaction(async (tx) => {
      await this.syncRolePermissions(
        tx,
        roleId,
        payload.permissionIds,
        actorUserId,
      );

      return tx.role.findUniqueOrThrow({
        where: {
          id: roleId,
        },
        include: {
          rolePermissions: {
            where: {
              deletedAt: null,
            },
            include: {
              permission: true,
            },
          },
        },
      });
    });

    await this.auditLogsService.record({
      actorUserId,
      action: 'ROLE_ASSIGN_PERMISSIONS',
      resource: 'roles',
      resourceId: roleId,
      details: {
        permissionIds: payload.permissionIds,
      },
    });

    return role;
  }

  async remove(id: string, actorUserId: string) {
    await this.ensureRoleExists(id);

    await this.prisma.$transaction(async (tx) => {
      await tx.role.update({
        where: { id },
        data: {
          deletedAt: new Date(),
          updatedById: actorUserId,
        },
      });

      await tx.userRole.updateMany({
        where: {
          roleId: id,
          deletedAt: null,
        },
        data: {
          deletedAt: new Date(),
          updatedById: actorUserId,
        },
      });

      await tx.rolePermission.updateMany({
        where: {
          roleId: id,
          deletedAt: null,
        },
        data: {
          deletedAt: new Date(),
          updatedById: actorUserId,
        },
      });
    });

    await this.auditLogsService.record({
      actorUserId,
      action: 'ROLE_DELETE',
      resource: 'roles',
      resourceId: id,
    });

    return {
      success: true,
      id,
    };
  }

  private async getRoleOrFail(id: string) {
    const role = await this.prisma.role.findFirst({
      where: {
        id,
        deletedAt: null,
      },
      include: {
        rolePermissions: {
          where: {
            deletedAt: null,
          },
          include: {
            permission: true,
          },
        },
        userRoles: {
          where: {
            deletedAt: null,
          },
          select: {
            id: true,
            userId: true,
          },
        },
      },
    });

    if (!role) {
      throw new NotFoundException('Role not found');
    }

    return role;
  }

  private async ensureRoleExists(id: string): Promise<Role> {
    const role = await this.prisma.role.findFirst({
      where: {
        id,
        deletedAt: null,
      },
    });

    if (!role) {
      throw new NotFoundException('Role not found');
    }

    return role;
  }

  private async syncRolePermissions(
    tx: Prisma.TransactionClient,
    roleId: string,
    permissionIds: string[],
    actorUserId: string,
  ): Promise<void> {
    if (permissionIds.length > 0) {
      const activePermissions = await tx.permission.count({
        where: {
          id: {
            in: permissionIds,
          },
          deletedAt: null,
        },
      });

      if (activePermissions !== permissionIds.length) {
        throw new BadRequestException(
          'One or more permissions are invalid or deleted',
        );
      }
    }

    const existing = await tx.rolePermission.findMany({
      where: {
        roleId,
      },
    });

    const existingByPermissionId = new Map(
      existing.map((item) => [item.permissionId, item]),
    );
    const requestedPermissionIdSet = new Set(permissionIds);

    for (const item of existing) {
      if (!item.deletedAt && !requestedPermissionIdSet.has(item.permissionId)) {
        await tx.rolePermission.update({
          where: {
            id: item.id,
          },
          data: {
            deletedAt: new Date(),
            updatedById: actorUserId,
          },
        });
      }
    }

    for (const permissionId of permissionIds) {
      const existingAssignment = existingByPermissionId.get(permissionId);

      if (!existingAssignment) {
        await tx.rolePermission.create({
          data: {
            roleId,
            permissionId,
            createdById: actorUserId,
            updatedById: actorUserId,
          },
        });
        continue;
      }

      if (existingAssignment.deletedAt) {
        await tx.rolePermission.update({
          where: {
            id: existingAssignment.id,
          },
          data: {
            deletedAt: null,
            updatedById: actorUserId,
          },
        });
      }
    }
  }

  private throwKnownDatabaseErrors(error: unknown): never {
    if (
      error instanceof Prisma.PrismaClientKnownRequestError &&
      error.code === 'P2002'
    ) {
      throw new ConflictException('Role code must be unique');
    }

    throw error;
  }

  private extractErrorMessage(error: unknown): string {
    if (error instanceof Error) {
      return error.message;
    }

    return 'Unknown error';
  }
}
