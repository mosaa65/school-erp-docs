import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { AuditStatus, Prisma, Section } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { AuditLogsService } from '../audit-logs/audit-logs.service';
import { CreateSectionDto } from './dto/create-section.dto';
import { ListSectionsDto } from './dto/list-sections.dto';
import { UpdateSectionDto } from './dto/update-section.dto';

@Injectable()
export class SectionsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly auditLogsService: AuditLogsService,
  ) {}

  async create(payload: CreateSectionDto, actorUserId: string) {
    const code = payload.code.trim().toLowerCase();
    const name = payload.name.trim();

    try {
      await this.ensureGradeLevelExistsAndActive(payload.gradeLevelId);

      const section = await this.prisma.section.create({
        data: {
          gradeLevelId: payload.gradeLevelId,
          code,
          name,
          capacity: payload.capacity,
          isActive: payload.isActive ?? true,
          createdById: actorUserId,
          updatedById: actorUserId,
        },
        include: {
          gradeLevel: {
            select: {
              id: true,
              code: true,
              name: true,
              stage: true,
              sequence: true,
            },
          },
        },
      });

      await this.auditLogsService.record({
        actorUserId,
        action: 'SECTION_CREATE',
        resource: 'sections',
        resourceId: section.id,
        details: {
          gradeLevelId: section.gradeLevelId,
          code: section.code,
        },
      });

      return section;
    } catch (error) {
      await this.auditLogsService.record({
        actorUserId,
        action: 'SECTION_CREATE_FAILED',
        resource: 'sections',
        status: AuditStatus.FAILURE,
        details: {
          gradeLevelId: payload.gradeLevelId,
          code,
          reason: this.extractErrorMessage(error),
        },
      });

      this.throwKnownDatabaseErrors(error);
    }
  }

  async findAll(query: ListSectionsDto) {
    const page = query.page ?? 1;
    const limit = query.limit ?? 20;

    const where: Prisma.SectionWhereInput = {
      deletedAt: null,
      gradeLevelId: query.gradeLevelId,
      isActive: query.isActive,
      OR: query.search
        ? [
            { code: { contains: query.search } },
            { name: { contains: query.search } },
            {
              gradeLevel: {
                name: {
                  contains: query.search,
                },
              },
            },
          ]
        : undefined,
    };

    const [total, items] = await this.prisma.$transaction([
      this.prisma.section.count({ where }),
      this.prisma.section.findMany({
        where,
        orderBy: [{ gradeLevel: { sequence: 'asc' } }, { code: 'asc' }],
        skip: (page - 1) * limit,
        take: limit,
        include: {
          gradeLevel: {
            select: {
              id: true,
              code: true,
              name: true,
              stage: true,
              sequence: true,
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
    const section = await this.prisma.section.findFirst({
      where: {
        id,
        deletedAt: null,
      },
      include: {
        gradeLevel: {
          select: {
            id: true,
            code: true,
            name: true,
            stage: true,
            sequence: true,
            isActive: true,
          },
        },
      },
    });

    if (!section) {
      throw new NotFoundException('Section not found');
    }

    return section;
  }

  async update(id: string, payload: UpdateSectionDto, actorUserId: string) {
    const existing = await this.ensureSectionExists(id);
    const resolvedGradeLevelId = payload.gradeLevelId ?? existing.gradeLevelId;

    try {
      await this.ensureGradeLevelExistsAndActive(resolvedGradeLevelId);

      const section = await this.prisma.section.update({
        where: {
          id,
        },
        data: {
          gradeLevelId: payload.gradeLevelId,
          code: payload.code,
          name: payload.name,
          capacity: payload.capacity,
          isActive: payload.isActive,
          updatedById: actorUserId,
        },
        include: {
          gradeLevel: {
            select: {
              id: true,
              code: true,
              name: true,
              stage: true,
              sequence: true,
              isActive: true,
            },
          },
        },
      });

      await this.auditLogsService.record({
        actorUserId,
        action: 'SECTION_UPDATE',
        resource: 'sections',
        resourceId: id,
        details: payload as Prisma.InputJsonValue,
      });

      return section;
    } catch (error) {
      this.throwKnownDatabaseErrors(error);
    }
  }

  async remove(id: string, actorUserId: string) {
    await this.ensureSectionExists(id);

    await this.prisma.section.update({
      where: {
        id,
      },
      data: {
        isActive: false,
        deletedAt: new Date(),
        updatedById: actorUserId,
      },
    });

    await this.auditLogsService.record({
      actorUserId,
      action: 'SECTION_DELETE',
      resource: 'sections',
      resourceId: id,
    });

    return {
      success: true,
      id,
    };
  }

  private async ensureSectionExists(id: string): Promise<Section> {
    const section = await this.prisma.section.findFirst({
      where: {
        id,
        deletedAt: null,
      },
    });

    if (!section) {
      throw new NotFoundException('Section not found');
    }

    return section;
  }

  private async ensureGradeLevelExistsAndActive(gradeLevelId: string) {
    const gradeLevel = await this.prisma.gradeLevel.findFirst({
      where: {
        id: gradeLevelId,
        deletedAt: null,
      },
      select: {
        id: true,
        isActive: true,
      },
    });

    if (!gradeLevel) {
      throw new BadRequestException('Grade level is invalid or deleted');
    }

    if (!gradeLevel.isActive) {
      throw new BadRequestException(
        'Cannot assign section to inactive grade level',
      );
    }
  }

  private throwKnownDatabaseErrors(error: unknown): never {
    if (
      error instanceof Prisma.PrismaClientKnownRequestError &&
      error.code === 'P2002'
    ) {
      throw new ConflictException(
        'Section code must be unique within the same grade level',
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
