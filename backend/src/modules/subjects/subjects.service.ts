import {
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { AuditStatus, Prisma, Subject } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { AuditLogsService } from '../audit-logs/audit-logs.service';
import { CreateSubjectDto } from './dto/create-subject.dto';
import { ListSubjectsDto } from './dto/list-subjects.dto';
import { UpdateSubjectDto } from './dto/update-subject.dto';

@Injectable()
export class SubjectsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly auditLogsService: AuditLogsService,
  ) {}

  async create(payload: CreateSubjectDto, actorUserId: string) {
    const code = payload.code.trim().toLowerCase();
    const name = payload.name.trim();

    try {
      const subject = await this.prisma.subject.create({
        data: {
          code,
          name,
          shortName: payload.shortName,
          category: payload.category,
          isActive: payload.isActive ?? true,
          createdById: actorUserId,
          updatedById: actorUserId,
        },
      });

      await this.auditLogsService.record({
        actorUserId,
        action: 'SUBJECT_CREATE',
        resource: 'subjects',
        resourceId: subject.id,
        details: {
          code: subject.code,
          category: subject.category,
        },
      });

      return subject;
    } catch (error) {
      await this.auditLogsService.record({
        actorUserId,
        action: 'SUBJECT_CREATE_FAILED',
        resource: 'subjects',
        status: AuditStatus.FAILURE,
        details: {
          code,
          reason: this.extractErrorMessage(error),
        },
      });

      this.throwKnownDatabaseErrors(error);
    }
  }

  async findAll(query: ListSubjectsDto) {
    const page = query.page ?? 1;
    const limit = query.limit ?? 20;

    const where: Prisma.SubjectWhereInput = {
      deletedAt: null,
      category: query.category,
      isActive: query.isActive,
      OR: query.search
        ? [
            { code: { contains: query.search } },
            { name: { contains: query.search } },
            { shortName: { contains: query.search } },
          ]
        : undefined,
    };

    const [total, items] = await this.prisma.$transaction([
      this.prisma.subject.count({ where }),
      this.prisma.subject.findMany({
        where,
        orderBy: [{ category: 'asc' }, { name: 'asc' }],
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
    const subject = await this.prisma.subject.findFirst({
      where: {
        id,
        deletedAt: null,
      },
    });

    if (!subject) {
      throw new NotFoundException('Subject not found');
    }

    return subject;
  }

  async update(id: string, payload: UpdateSubjectDto, actorUserId: string) {
    await this.ensureSubjectExists(id);

    try {
      const subject = await this.prisma.subject.update({
        where: {
          id,
        },
        data: {
          code: payload.code,
          name: payload.name,
          shortName: payload.shortName,
          category: payload.category,
          isActive: payload.isActive,
          updatedById: actorUserId,
        },
      });

      await this.auditLogsService.record({
        actorUserId,
        action: 'SUBJECT_UPDATE',
        resource: 'subjects',
        resourceId: id,
        details: payload as Prisma.InputJsonValue,
      });

      return subject;
    } catch (error) {
      this.throwKnownDatabaseErrors(error);
    }
  }

  async remove(id: string, actorUserId: string) {
    await this.ensureSubjectExists(id);

    await this.prisma.subject.update({
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
      action: 'SUBJECT_DELETE',
      resource: 'subjects',
      resourceId: id,
    });

    return {
      success: true,
      id,
    };
  }

  private async ensureSubjectExists(id: string): Promise<Subject> {
    const subject = await this.prisma.subject.findFirst({
      where: {
        id,
        deletedAt: null,
      },
    });

    if (!subject) {
      throw new NotFoundException('Subject not found');
    }

    return subject;
  }

  private throwKnownDatabaseErrors(error: unknown): never {
    if (
      error instanceof Prisma.PrismaClientKnownRequestError &&
      error.code === 'P2002'
    ) {
      throw new ConflictException('Subject code must be unique');
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
