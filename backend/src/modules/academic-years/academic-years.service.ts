import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import {
  AcademicYear,
  AcademicYearStatus,
  AuditStatus,
  Prisma,
} from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { AuditLogsService } from '../audit-logs/audit-logs.service';
import { CreateAcademicYearDto } from './dto/create-academic-year.dto';
import { ListAcademicYearsDto } from './dto/list-academic-years.dto';
import { UpdateAcademicYearDto } from './dto/update-academic-year.dto';

@Injectable()
export class AcademicYearsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly auditLogsService: AuditLogsService,
  ) {}

  async create(payload: CreateAcademicYearDto, actorUserId: string) {
    const code = payload.code.trim().toLowerCase();
    const name = payload.name.trim();
    const startDate = new Date(payload.startDate);
    const endDate = new Date(payload.endDate);

    try {
      this.assertValidDateRange(startDate, endDate);

      const resolvedStatus = payload.status ?? AcademicYearStatus.PLANNED;
      let resolvedIsCurrent = payload.isCurrent ?? false;

      if (resolvedStatus === AcademicYearStatus.ACTIVE) {
        resolvedIsCurrent = true;
      }

      if (resolvedIsCurrent && resolvedStatus !== AcademicYearStatus.ACTIVE) {
        throw new BadRequestException(
          'Current academic year must have ACTIVE status',
        );
      }

      await this.ensureNoDateOverlap(startDate, endDate);

      if (resolvedStatus === AcademicYearStatus.ACTIVE) {
        await this.ensureNoOtherActiveYear();
      }

      const academicYear = await this.prisma.$transaction(async (tx) => {
        if (resolvedIsCurrent) {
          await tx.academicYear.updateMany({
            where: {
              deletedAt: null,
              isCurrent: true,
            },
            data: {
              isCurrent: false,
              updatedById: actorUserId,
            },
          });
        }

        return tx.academicYear.create({
          data: {
            code,
            name,
            startDate,
            endDate,
            status: resolvedStatus,
            isCurrent: resolvedIsCurrent,
            createdById: actorUserId,
            updatedById: actorUserId,
          },
        });
      });

      await this.auditLogsService.record({
        actorUserId,
        action: 'ACADEMIC_YEAR_CREATE',
        resource: 'academic-years',
        resourceId: academicYear.id,
        details: {
          code: academicYear.code,
          status: academicYear.status,
          isCurrent: academicYear.isCurrent,
        },
      });

      return academicYear;
    } catch (error) {
      await this.auditLogsService.record({
        actorUserId,
        action: 'ACADEMIC_YEAR_CREATE_FAILED',
        resource: 'academic-years',
        status: AuditStatus.FAILURE,
        details: {
          code,
          reason: this.extractErrorMessage(error),
        },
      });

      this.throwKnownDatabaseErrors(error);
    }
  }

  async findAll(query: ListAcademicYearsDto) {
    const page = query.page ?? 1;
    const limit = query.limit ?? 20;

    const where: Prisma.AcademicYearWhereInput = {
      deletedAt: null,
      status: query.status,
      isCurrent: query.isCurrent,
      OR: query.search
        ? [
            { code: { contains: query.search } },
            { name: { contains: query.search } },
          ]
        : undefined,
    };

    const [total, items] = await this.prisma.$transaction([
      this.prisma.academicYear.count({ where }),
      this.prisma.academicYear.findMany({
        where,
        orderBy: {
          startDate: 'desc',
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
    const academicYear = await this.prisma.academicYear.findFirst({
      where: {
        id,
        deletedAt: null,
      },
      include: {
        terms: {
          where: {
            deletedAt: null,
          },
          orderBy: {
            sequence: 'asc',
          },
        },
      },
    });

    if (!academicYear) {
      throw new NotFoundException('Academic year not found');
    }

    return academicYear;
  }

  async update(
    id: string,
    payload: UpdateAcademicYearDto,
    actorUserId: string,
  ) {
    const existing = await this.ensureAcademicYearExists(id);

    const startDate = payload.startDate
      ? new Date(payload.startDate)
      : existing.startDate;
    const endDate = payload.endDate
      ? new Date(payload.endDate)
      : existing.endDate;

    try {
      this.assertValidDateRange(startDate, endDate);

      const resolvedStatus = payload.status ?? existing.status;
      let resolvedIsCurrent = payload.isCurrent ?? existing.isCurrent;

      if (resolvedStatus === AcademicYearStatus.ACTIVE) {
        resolvedIsCurrent = true;
      }

      if (resolvedIsCurrent && resolvedStatus !== AcademicYearStatus.ACTIVE) {
        throw new BadRequestException(
          'Current academic year must have ACTIVE status',
        );
      }

      await this.ensureNoDateOverlap(startDate, endDate, id);

      if (resolvedStatus === AcademicYearStatus.ACTIVE) {
        await this.ensureNoOtherActiveYear(id);
      }

      const academicYear = await this.prisma.$transaction(async (tx) => {
        if (resolvedIsCurrent) {
          await tx.academicYear.updateMany({
            where: {
              deletedAt: null,
              isCurrent: true,
              id: {
                not: id,
              },
            },
            data: {
              isCurrent: false,
              updatedById: actorUserId,
            },
          });
        }

        return tx.academicYear.update({
          where: {
            id,
          },
          data: {
            code: payload.code,
            name: payload.name,
            startDate: payload.startDate ? startDate : undefined,
            endDate: payload.endDate ? endDate : undefined,
            status: resolvedStatus,
            isCurrent: resolvedIsCurrent,
            updatedById: actorUserId,
          },
        });
      });

      await this.auditLogsService.record({
        actorUserId,
        action: 'ACADEMIC_YEAR_UPDATE',
        resource: 'academic-years',
        resourceId: id,
        details: {
          ...payload,
          status: resolvedStatus,
          isCurrent: resolvedIsCurrent,
        } as Prisma.InputJsonValue,
      });

      return academicYear;
    } catch (error) {
      this.throwKnownDatabaseErrors(error);
    }
  }

  async remove(id: string, actorUserId: string) {
    await this.ensureAcademicYearExists(id);

    const now = new Date();

    await this.prisma.$transaction(async (tx) => {
      await tx.academicYear.update({
        where: { id },
        data: {
          status: AcademicYearStatus.ARCHIVED,
          isCurrent: false,
          deletedAt: now,
          updatedById: actorUserId,
        },
      });

      await tx.academicTerm.updateMany({
        where: {
          academicYearId: id,
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
      action: 'ACADEMIC_YEAR_DELETE',
      resource: 'academic-years',
      resourceId: id,
    });

    return {
      success: true,
      id,
    };
  }

  private async ensureAcademicYearExists(id: string): Promise<AcademicYear> {
    const academicYear = await this.prisma.academicYear.findFirst({
      where: {
        id,
        deletedAt: null,
      },
    });

    if (!academicYear) {
      throw new NotFoundException('Academic year not found');
    }

    return academicYear;
  }

  private async ensureNoDateOverlap(
    startDate: Date,
    endDate: Date,
    excludeId?: string,
  ): Promise<void> {
    const overlapping = await this.prisma.academicYear.findFirst({
      where: {
        deletedAt: null,
        id: excludeId
          ? {
              not: excludeId,
            }
          : undefined,
        startDate: {
          lte: endDate,
        },
        endDate: {
          gte: startDate,
        },
      },
      select: {
        id: true,
      },
    });

    if (overlapping) {
      throw new BadRequestException(
        'Academic year dates overlap with existing year',
      );
    }
  }

  private async ensureNoOtherActiveYear(excludeId?: string): Promise<void> {
    const existingActiveYear = await this.prisma.academicYear.findFirst({
      where: {
        deletedAt: null,
        status: AcademicYearStatus.ACTIVE,
        id: excludeId
          ? {
              not: excludeId,
            }
          : undefined,
      },
      select: {
        id: true,
      },
    });

    if (existingActiveYear) {
      throw new BadRequestException(
        'Another active academic year already exists',
      );
    }
  }

  private assertValidDateRange(startDate: Date, endDate: Date): void {
    if (startDate >= endDate) {
      throw new BadRequestException('startDate must be earlier than endDate');
    }
  }

  private throwKnownDatabaseErrors(error: unknown): never {
    if (
      error instanceof Prisma.PrismaClientKnownRequestError &&
      error.code === 'P2002'
    ) {
      throw new ConflictException('Academic year code must be unique');
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
