import {
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { AuditStatus, GradeLevel, Prisma } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { AuditLogsService } from '../audit-logs/audit-logs.service';
import { CreateGradeLevelDto } from './dto/create-grade-level.dto';
import { ListGradeLevelsDto } from './dto/list-grade-levels.dto';
import { UpdateGradeLevelDto } from './dto/update-grade-level.dto';

@Injectable()
export class GradeLevelsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly auditLogsService: AuditLogsService,
  ) {}

  async create(payload: CreateGradeLevelDto, actorUserId: string) {
    const code = payload.code.trim().toLowerCase();
    const name = payload.name.trim();

    try {
      const gradeLevel = await this.prisma.gradeLevel.create({
        data: {
          code,
          name,
          stage: payload.stage,
          sequence: payload.sequence,
          isActive: payload.isActive ?? true,
          createdById: actorUserId,
          updatedById: actorUserId,
        },
      });

      await this.auditLogsService.record({
        actorUserId,
        action: 'GRADE_LEVEL_CREATE',
        resource: 'grade-levels',
        resourceId: gradeLevel.id,
        details: {
          code: gradeLevel.code,
          stage: gradeLevel.stage,
          sequence: gradeLevel.sequence,
        },
      });

      return gradeLevel;
    } catch (error) {
      await this.auditLogsService.record({
        actorUserId,
        action: 'GRADE_LEVEL_CREATE_FAILED',
        resource: 'grade-levels',
        status: AuditStatus.FAILURE,
        details: {
          code,
          reason: this.extractErrorMessage(error),
        },
      });

      this.throwKnownDatabaseErrors(error);
    }
  }

  async findAll(query: ListGradeLevelsDto) {
    const page = query.page ?? 1;
    const limit = query.limit ?? 20;

    const where: Prisma.GradeLevelWhereInput = {
      deletedAt: null,
      stage: query.stage,
      isActive: query.isActive,
      OR: query.search
        ? [
            { code: { contains: query.search } },
            { name: { contains: query.search } },
          ]
        : undefined,
    };

    const [total, items] = await this.prisma.$transaction([
      this.prisma.gradeLevel.count({ where }),
      this.prisma.gradeLevel.findMany({
        where,
        orderBy: [{ stage: 'asc' }, { sequence: 'asc' }],
        skip: (page - 1) * limit,
        take: limit,
        include: {
          sections: {
            where: {
              deletedAt: null,
            },
            select: {
              id: true,
              code: true,
              name: true,
              capacity: true,
              isActive: true,
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
    const gradeLevel = await this.prisma.gradeLevel.findFirst({
      where: {
        id,
        deletedAt: null,
      },
      include: {
        sections: {
          where: {
            deletedAt: null,
          },
          orderBy: {
            createdAt: 'asc',
          },
        },
      },
    });

    if (!gradeLevel) {
      throw new NotFoundException('Grade level not found');
    }

    return gradeLevel;
  }

  async update(id: string, payload: UpdateGradeLevelDto, actorUserId: string) {
    await this.ensureGradeLevelExists(id);

    try {
      const gradeLevel = await this.prisma.gradeLevel.update({
        where: {
          id,
        },
        data: {
          code: payload.code,
          name: payload.name,
          stage: payload.stage,
          sequence: payload.sequence,
          isActive: payload.isActive,
          updatedById: actorUserId,
        },
      });

      await this.auditLogsService.record({
        actorUserId,
        action: 'GRADE_LEVEL_UPDATE',
        resource: 'grade-levels',
        resourceId: id,
        details: payload as Prisma.InputJsonValue,
      });

      return gradeLevel;
    } catch (error) {
      this.throwKnownDatabaseErrors(error);
    }
  }

  async remove(id: string, actorUserId: string) {
    await this.ensureGradeLevelExists(id);

    const now = new Date();

    await this.prisma.$transaction(async (tx) => {
      await tx.gradeLevel.update({
        where: {
          id,
        },
        data: {
          isActive: false,
          deletedAt: now,
          updatedById: actorUserId,
        },
      });

      await tx.section.updateMany({
        where: {
          gradeLevelId: id,
          deletedAt: null,
        },
        data: {
          isActive: false,
          deletedAt: now,
          updatedById: actorUserId,
        },
      });
    });

    await this.auditLogsService.record({
      actorUserId,
      action: 'GRADE_LEVEL_DELETE',
      resource: 'grade-levels',
      resourceId: id,
    });

    return {
      success: true,
      id,
    };
  }

  private async ensureGradeLevelExists(id: string): Promise<GradeLevel> {
    const gradeLevel = await this.prisma.gradeLevel.findFirst({
      where: {
        id,
        deletedAt: null,
      },
    });

    if (!gradeLevel) {
      throw new NotFoundException('Grade level not found');
    }

    return gradeLevel;
  }

  private throwKnownDatabaseErrors(error: unknown): never {
    if (
      error instanceof Prisma.PrismaClientKnownRequestError &&
      error.code === 'P2002'
    ) {
      throw new ConflictException(
        'Grade level code and stage/sequence combination must be unique',
      );
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
