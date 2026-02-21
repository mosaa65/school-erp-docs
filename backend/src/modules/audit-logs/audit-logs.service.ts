import { Injectable, NotFoundException } from '@nestjs/common';
import { AuditStatus, Prisma } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { CreateAuditLogDto } from './dto/create-audit-log.dto';
import { ListAuditLogsDto } from './dto/list-audit-logs.dto';

export interface RecordAuditLogInput {
  actorUserId?: string;
  action: string;
  resource: string;
  resourceId?: string;
  status?: AuditStatus;
  details?: Prisma.InputJsonValue;
  ipAddress?: string;
  userAgent?: string;
  createdById?: string;
  updatedById?: string;
}

@Injectable()
export class AuditLogsService {
  constructor(private readonly prisma: PrismaService) {}

  async createManual(
    createAuditLogDto: CreateAuditLogDto,
    actorUserId: string,
    ipAddress?: string,
    userAgent?: string,
  ) {
    return this.record({
      actorUserId,
      action: createAuditLogDto.action,
      resource: createAuditLogDto.resource,
      resourceId: createAuditLogDto.resourceId,
      status: createAuditLogDto.status ?? AuditStatus.SUCCESS,
      details: createAuditLogDto.details as Prisma.InputJsonValue | undefined,
      ipAddress,
      userAgent,
      createdById: actorUserId,
      updatedById: actorUserId,
    });
  }

  async record(input: RecordAuditLogInput) {
    return this.prisma.auditLog.create({
      data: {
        actorUserId: input.actorUserId,
        action: input.action,
        resource: input.resource,
        resourceId: input.resourceId,
        status: input.status ?? AuditStatus.SUCCESS,
        details: input.details,
        ipAddress: input.ipAddress,
        userAgent: input.userAgent,
        createdById: input.createdById ?? input.actorUserId,
        updatedById: input.updatedById ?? input.actorUserId,
      },
    });
  }

  async findAll(query: ListAuditLogsDto) {
    const page = query.page ?? 1;
    const limit = query.limit ?? 20;

    const where: Prisma.AuditLogWhereInput = {
      deletedAt: null,
      resource: query.resource,
      action: query.action,
      status: query.status,
      actorUserId: query.actorUserId,
      occurredAt:
        query.from || query.to
          ? {
              gte: query.from ? new Date(query.from) : undefined,
              lte: query.to ? new Date(query.to) : undefined,
            }
          : undefined,
    };

    const [total, items] = await this.prisma.$transaction([
      this.prisma.auditLog.count({ where }),
      this.prisma.auditLog.findMany({
        where,
        orderBy: {
          occurredAt: 'desc',
        },
        skip: (page - 1) * limit,
        take: limit,
        include: {
          actorUser: {
            select: {
              id: true,
              email: true,
              firstName: true,
              lastName: true,
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
    const auditLog = await this.prisma.auditLog.findFirst({
      where: {
        id,
        deletedAt: null,
      },
      include: {
        actorUser: {
          select: {
            id: true,
            email: true,
            firstName: true,
            lastName: true,
          },
        },
      },
    });

    if (!auditLog) {
      throw new NotFoundException('Audit log not found');
    }

    return auditLog;
  }

  async remove(id: string, actorUserId: string) {
    const result = await this.prisma.auditLog.updateMany({
      where: {
        id,
        deletedAt: null,
      },
      data: {
        deletedAt: new Date(),
        updatedById: actorUserId,
      },
    });

    if (!result.count) {
      throw new NotFoundException('Audit log not found');
    }

    return {
      success: true,
      id,
    };
  }
}
