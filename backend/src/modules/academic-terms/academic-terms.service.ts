import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { AcademicTerm, AuditStatus, Prisma } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { AuditLogsService } from '../audit-logs/audit-logs.service';
import { CreateAcademicTermDto } from './dto/create-academic-term.dto';
import { ListAcademicTermsDto } from './dto/list-academic-terms.dto';
import { UpdateAcademicTermDto } from './dto/update-academic-term.dto';

@Injectable()
export class AcademicTermsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly auditLogsService: AuditLogsService,
  ) {}

  async create(payload: CreateAcademicTermDto, actorUserId: string) {
    const code = payload.code.trim().toLowerCase();
    const name = payload.name.trim();
    const startDate = new Date(payload.startDate);
    const endDate = new Date(payload.endDate);

    try {
      this.assertValidDateRange(startDate, endDate);

      const academicYear = await this.ensureAcademicYearExists(
        payload.academicYearId,
      );
      this.assertDatesWithinAcademicYear(startDate, endDate, academicYear);
      await this.ensureNoDateOverlap(
        payload.academicYearId,
        startDate,
        endDate,
      );

      const academicTerm = await this.prisma.academicTerm.create({
        data: {
          academicYearId: payload.academicYearId,
          code,
          name,
          termType: payload.termType,
          sequence: payload.sequence,
          startDate,
          endDate,
          isActive: payload.isActive ?? true,
          createdById: actorUserId,
          updatedById: actorUserId,
        },
        include: {
          academicYear: {
            select: {
              id: true,
              code: true,
              name: true,
              status: true,
              isCurrent: true,
            },
          },
        },
      });

      await this.auditLogsService.record({
        actorUserId,
        action: 'ACADEMIC_TERM_CREATE',
        resource: 'academic-terms',
        resourceId: academicTerm.id,
        details: {
          academicYearId: academicTerm.academicYearId,
          code: academicTerm.code,
          sequence: academicTerm.sequence,
        },
      });

      return academicTerm;
    } catch (error) {
      await this.auditLogsService.record({
        actorUserId,
        action: 'ACADEMIC_TERM_CREATE_FAILED',
        resource: 'academic-terms',
        status: AuditStatus.FAILURE,
        details: {
          academicYearId: payload.academicYearId,
          code,
          reason: this.extractErrorMessage(error),
        },
      });

      this.throwKnownDatabaseErrors(error);
    }
  }

  async findAll(query: ListAcademicTermsDto) {
    const page = query.page ?? 1;
    const limit = query.limit ?? 20;

    const where: Prisma.AcademicTermWhereInput = {
      deletedAt: null,
      academicYearId: query.academicYearId,
      termType: query.termType,
      isActive: query.isActive,
      OR: query.search
        ? [
            { code: { contains: query.search } },
            { name: { contains: query.search } },
          ]
        : undefined,
    };

    const [total, items] = await this.prisma.$transaction([
      this.prisma.academicTerm.count({ where }),
      this.prisma.academicTerm.findMany({
        where,
        orderBy: [
          {
            sequence: 'asc',
          },
          {
            createdAt: 'desc',
          },
        ],
        skip: (page - 1) * limit,
        take: limit,
        include: {
          academicYear: {
            select: {
              id: true,
              code: true,
              name: true,
              status: true,
              isCurrent: true,
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
    const academicTerm = await this.prisma.academicTerm.findFirst({
      where: {
        id,
        deletedAt: null,
      },
      include: {
        academicYear: {
          select: {
            id: true,
            code: true,
            name: true,
            status: true,
            isCurrent: true,
          },
        },
      },
    });

    if (!academicTerm) {
      throw new NotFoundException('Academic term not found');
    }

    return academicTerm;
  }

  async update(
    id: string,
    payload: UpdateAcademicTermDto,
    actorUserId: string,
  ) {
    const existing = await this.ensureAcademicTermExists(id);

    const resolvedAcademicYearId =
      payload.academicYearId ?? existing.academicYearId;
    const startDate = payload.startDate
      ? new Date(payload.startDate)
      : existing.startDate;
    const endDate = payload.endDate
      ? new Date(payload.endDate)
      : existing.endDate;

    try {
      this.assertValidDateRange(startDate, endDate);

      const academicYear = await this.ensureAcademicYearExists(
        resolvedAcademicYearId,
      );
      this.assertDatesWithinAcademicYear(startDate, endDate, academicYear);
      await this.ensureNoDateOverlap(
        resolvedAcademicYearId,
        startDate,
        endDate,
        id,
      );

      const academicTerm = await this.prisma.academicTerm.update({
        where: { id },
        data: {
          academicYearId: payload.academicYearId,
          code: payload.code,
          name: payload.name,
          termType: payload.termType,
          sequence: payload.sequence,
          startDate: payload.startDate ? startDate : undefined,
          endDate: payload.endDate ? endDate : undefined,
          isActive: payload.isActive,
          updatedById: actorUserId,
        },
        include: {
          academicYear: {
            select: {
              id: true,
              code: true,
              name: true,
              status: true,
              isCurrent: true,
            },
          },
        },
      });

      await this.auditLogsService.record({
        actorUserId,
        action: 'ACADEMIC_TERM_UPDATE',
        resource: 'academic-terms',
        resourceId: id,
        details: payload as Prisma.InputJsonValue,
      });

      return academicTerm;
    } catch (error) {
      this.throwKnownDatabaseErrors(error);
    }
  }

  async remove(id: string, actorUserId: string) {
    await this.ensureAcademicTermExists(id);

    await this.prisma.academicTerm.update({
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
      action: 'ACADEMIC_TERM_DELETE',
      resource: 'academic-terms',
      resourceId: id,
    });

    return {
      success: true,
      id,
    };
  }

  private async ensureAcademicTermExists(id: string): Promise<AcademicTerm> {
    const academicTerm = await this.prisma.academicTerm.findFirst({
      where: {
        id,
        deletedAt: null,
      },
    });

    if (!academicTerm) {
      throw new NotFoundException('Academic term not found');
    }

    return academicTerm;
  }

  private async ensureAcademicYearExists(id: string) {
    const academicYear = await this.prisma.academicYear.findFirst({
      where: {
        id,
        deletedAt: null,
      },
      select: {
        id: true,
        startDate: true,
        endDate: true,
      },
    });

    if (!academicYear) {
      throw new BadRequestException('Academic year is invalid or deleted');
    }

    return academicYear;
  }

  private assertValidDateRange(startDate: Date, endDate: Date): void {
    if (startDate >= endDate) {
      throw new BadRequestException('startDate must be earlier than endDate');
    }
  }

  private assertDatesWithinAcademicYear(
    startDate: Date,
    endDate: Date,
    academicYear: {
      startDate: Date;
      endDate: Date;
    },
  ): void {
    if (startDate < academicYear.startDate || endDate > academicYear.endDate) {
      throw new BadRequestException(
        'Academic term dates must be within academic year date range',
      );
    }
  }

  private async ensureNoDateOverlap(
    academicYearId: string,
    startDate: Date,
    endDate: Date,
    excludeId?: string,
  ) {
    const overlapping = await this.prisma.academicTerm.findFirst({
      where: {
        deletedAt: null,
        academicYearId,
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
        'Academic term dates overlap within the same year',
      );
    }
  }

  private throwKnownDatabaseErrors(error: unknown): never {
    if (
      error instanceof Prisma.PrismaClientKnownRequestError &&
      error.code === 'P2002'
    ) {
      throw new ConflictException(
        'Academic term code and sequence must be unique within the academic year',
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
