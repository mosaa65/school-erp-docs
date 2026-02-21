import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import {
  AuditStatus,
  Prisma,
  SettingValueType,
  type GlobalSetting,
} from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { AuditLogsService } from '../audit-logs/audit-logs.service';
import { CreateGlobalSettingDto } from './dto/create-global-setting.dto';
import { ListGlobalSettingsDto } from './dto/list-global-settings.dto';
import { UpdateGlobalSettingDto } from './dto/update-global-setting.dto';

@Injectable()
export class GlobalSettingsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly auditLogsService: AuditLogsService,
  ) {}

  async create(payload: CreateGlobalSettingDto, actorUserId: string) {
    const key = payload.key.trim().toLowerCase();
    this.assertValueMatchesType(payload.valueType, payload.value);

    try {
      const setting = await this.prisma.globalSetting.create({
        data: {
          key,
          valueType: payload.valueType,
          value: payload.value as Prisma.InputJsonValue,
          description: payload.description,
          isPublic: payload.isPublic ?? false,
          createdById: actorUserId,
          updatedById: actorUserId,
        },
      });

      await this.auditLogsService.record({
        actorUserId,
        action: 'GLOBAL_SETTING_CREATE',
        resource: 'global-settings',
        resourceId: setting.id,
        details: {
          key: setting.key,
          valueType: setting.valueType,
        },
      });

      return setting;
    } catch (error) {
      await this.auditLogsService.record({
        actorUserId,
        action: 'GLOBAL_SETTING_CREATE_FAILED',
        resource: 'global-settings',
        status: AuditStatus.FAILURE,
        details: {
          key,
          reason: this.extractErrorMessage(error),
        },
      });

      this.throwKnownDatabaseErrors(error);
    }
  }

  async findAll(query: ListGlobalSettingsDto) {
    const page = query.page ?? 1;
    const limit = query.limit ?? 20;

    const where: Prisma.GlobalSettingWhereInput = {
      deletedAt: null,
      isPublic: query.isPublic,
      OR: query.search
        ? [
            { key: { contains: query.search } },
            { description: { contains: query.search } },
          ]
        : undefined,
    };

    const [total, items] = await this.prisma.$transaction([
      this.prisma.globalSetting.count({ where }),
      this.prisma.globalSetting.findMany({
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
    const setting = await this.prisma.globalSetting.findFirst({
      where: {
        id,
        deletedAt: null,
      },
    });

    if (!setting) {
      throw new NotFoundException('Global setting not found');
    }

    return setting;
  }

  async update(
    id: string,
    payload: UpdateGlobalSettingDto,
    actorUserId: string,
  ) {
    const existing = await this.ensureExists(id);

    const resolvedValueType = payload.valueType ?? existing.valueType;
    const resolvedValue = payload.value ?? existing.value;

    this.assertValueMatchesType(resolvedValueType, resolvedValue);

    try {
      const setting = await this.prisma.globalSetting.update({
        where: { id },
        data: {
          valueType: payload.valueType,
          value: payload.value as Prisma.InputJsonValue | undefined,
          description: payload.description,
          isPublic: payload.isPublic,
          updatedById: actorUserId,
        },
      });

      await this.auditLogsService.record({
        actorUserId,
        action: 'GLOBAL_SETTING_UPDATE',
        resource: 'global-settings',
        resourceId: id,
        details: payload as Prisma.InputJsonValue,
      });

      return setting;
    } catch (error) {
      this.throwKnownDatabaseErrors(error);
    }
  }

  async remove(id: string, actorUserId: string) {
    await this.ensureExists(id);

    await this.prisma.globalSetting.update({
      where: {
        id,
      },
      data: {
        deletedAt: new Date(),
        updatedById: actorUserId,
      },
    });

    await this.auditLogsService.record({
      actorUserId,
      action: 'GLOBAL_SETTING_DELETE',
      resource: 'global-settings',
      resourceId: id,
    });

    return {
      success: true,
      id,
    };
  }

  private async ensureExists(id: string): Promise<GlobalSetting> {
    const setting = await this.prisma.globalSetting.findFirst({
      where: {
        id,
        deletedAt: null,
      },
    });

    if (!setting) {
      throw new NotFoundException('Global setting not found');
    }

    return setting;
  }

  private assertValueMatchesType(valueType: SettingValueType, value: unknown) {
    const isValid =
      (valueType === SettingValueType.STRING && typeof value === 'string') ||
      (valueType === SettingValueType.NUMBER && typeof value === 'number') ||
      (valueType === SettingValueType.BOOLEAN && typeof value === 'boolean') ||
      (valueType === SettingValueType.JSON && this.isJsonCompatible(value));

    if (!isValid) {
      throw new BadRequestException(
        `Value does not match valueType ${valueType}`,
      );
    }
  }

  private isJsonCompatible(value: unknown): boolean {
    if (value === null) {
      return true;
    }

    if (
      typeof value === 'string' ||
      typeof value === 'number' ||
      typeof value === 'boolean'
    ) {
      return true;
    }

    if (Array.isArray(value)) {
      return value.every((item) => this.isJsonCompatible(item));
    }

    if (typeof value === 'object') {
      const obj = value as Record<string, unknown>;
      return Object.values(obj).every((item) => this.isJsonCompatible(item));
    }

    return false;
  }

  private throwKnownDatabaseErrors(error: unknown): never {
    if (
      error instanceof Prisma.PrismaClientKnownRequestError &&
      error.code === 'P2002'
    ) {
      throw new ConflictException('Global setting key must be unique');
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
