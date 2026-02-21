import {
  IsEnum,
  IsObject,
  IsOptional,
  IsString,
  MaxLength,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { AuditStatus } from '@prisma/client';

export class CreateAuditLogDto {
  @ApiProperty({ example: 'USER_CREATE' })
  @IsString()
  @MaxLength(120)
  action!: string;

  @ApiProperty({ example: 'users' })
  @IsString()
  @MaxLength(120)
  resource!: string;

  @ApiPropertyOptional({ example: 'clxuser01...' })
  @IsOptional()
  @IsString()
  @MaxLength(191)
  resourceId?: string;

  @ApiPropertyOptional({ enum: AuditStatus, example: AuditStatus.SUCCESS })
  @IsOptional()
  @IsEnum(AuditStatus)
  status?: AuditStatus;

  @ApiPropertyOptional({
    type: Object,
    example: { changedFields: ['email', 'roles'] },
  })
  @IsOptional()
  @IsObject()
  details?: Record<string, unknown>;
}
