import {
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { AuditStatus, Prisma, type Permission } from '@prisma/client';
import { AuditLogsService } from '../audit-logs/audit-logs.service';
import { PrismaService } from '../../prisma/prisma.service';
import { CreatePermissionDto } from './dto/create-permission.dto';
import { ListPermissionsDto } from './dto/list-permissions.dto';
import { UpdatePermissionDto } from './dto/update-permission.dto';

@Injectable()
export class PermissionsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly auditLogsService: AuditLogsService,
  ) {}

  async create(createPermissionDto: CreatePermissionDto, actorUserId: string) {
    try {
      const permission = await this.prisma.permission.create({
        data: {
          code: createPermissionDto.code,
          resource: createPermissionDto.resource,
          action: createPermissionDto.action,
          description: createPermissionDto.description,
          isSystem: createPermissionDto.isSystem ?? false,
          createdById: actorUserId,
          updatedById: actorUserId,
        },
      });

      await this.auditLogsService.record({
        actorUserId,
        action: 'PERMISSION_CREATE',
        resource: 'permissions',
        resourceId: permission.id,
        details: {
          code: permission.code,
          resource: permission.resource,
          action: permission.action,
        },
      });

      return permission;
    } catch (error) {
      await this.auditLogsService.record({
        actorUserId,
        action: 'PERMISSION_CREATE_FAILED',
        resource: 'permissions',
        status: AuditStatus.FAILURE,
        details: {
          code: createPermissionDto.code,
          reason: this.extractErrorMessage(error),
        },
      });

      this.throwKnownDatabaseErrors(error);
    }
  }

  async findAll(query: ListPermissionsDto) {
    const page = query.page ?? 1;
    const limit = query.limit ?? 20;

    const where: Prisma.PermissionWhereInput = {
      deletedAt: null,
      OR: query.search
        ? [
            { code: { contains: query.search } },
            { resource: { contains: query.search } },
            { action: { contains: query.search } },
            { description: { contains: query.search } },
          ]
        : undefined,
    };

    const [total, items] = await this.prisma.$transaction([
      this.prisma.permission.count({ where }),
      this.prisma.permission.findMany({
        where,
        orderBy: {
          createdAt: 'desc',
        },
        skip: (page - 1) * limit,
        take: limit,
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
    const permission = await this.prisma.permission.findFirst({
      where: {
        id,
        deletedAt: null,
      },
    });

    if (!permission) {
      throw new NotFoundException('Permission not found');
    }

    return permission;
  }

  async update(
    id: string,
    updatePermissionDto: UpdatePermissionDto,
    actorUserId: string,
  ) {
    await this.ensurePermissionExists(id);

    try {
      const permission = await this.prisma.permission.update({
        where: { id },
        data: {
          code: updatePermissionDto.code,
          resource: updatePermissionDto.resource,
          action: updatePermissionDto.action,
          description: updatePermissionDto.description,
          isSystem: updatePermissionDto.isSystem,
          updatedById: actorUserId,
        },
      });

      await this.auditLogsService.record({
        actorUserId,
        action: 'PERMISSION_UPDATE',
        resource: 'permissions',
        resourceId: id,
        details: updatePermissionDto as Prisma.InputJsonValue,
      });

      return permission;
    } catch (error) {
      this.throwKnownDatabaseErrors(error);
    }
  }

  async remove(id: string, actorUserId: string) {
    await this.ensurePermissionExists(id);

    await this.prisma.$transaction(async (tx) => {
      await tx.permission.update({
        where: { id },
        data: {
          deletedAt: new Date(),
          updatedById: actorUserId,
        },
      });

      await tx.rolePermission.updateMany({
        where: {
          permissionId: id,
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
      action: 'PERMISSION_DELETE',
      resource: 'permissions',
      resourceId: id,
    });

    return {
      success: true,
      id,
    };
  }

  private async ensurePermissionExists(id: string): Promise<Permission> {
    const permission = await this.prisma.permission.findFirst({
      where: {
        id,
        deletedAt: null,
      },
    });

    if (!permission) {
      throw new NotFoundException('Permission not found');
    }

    return permission;
  }

  private throwKnownDatabaseErrors(error: unknown): never {
    if (
      error instanceof Prisma.PrismaClientKnownRequestError &&
      error.code === 'P2002'
    ) {
      throw new ConflictException('Permission code must be unique');
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
