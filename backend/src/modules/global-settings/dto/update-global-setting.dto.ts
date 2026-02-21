import { Type } from 'class-transformer';
import {
  Allow,
  IsBoolean,
  IsEnum,
  IsOptional,
  IsString,
  MaxLength,
} from 'class-validator';
import { ApiPropertyOptional } from '@nestjs/swagger';
import { SettingValueType } from '@prisma/client';

export class UpdateGlobalSettingDto {
  @ApiPropertyOptional({ enum: SettingValueType })
  @IsOptional()
  @IsEnum(SettingValueType)
  valueType?: SettingValueType;

  @ApiPropertyOptional({
    description:
      'Setting value. If valueType is omitted, existing type is used.',
    example: true,
  })
  @IsOptional()
  @Allow()
  value?: unknown;

  @ApiPropertyOptional({ example: 'Updated setting description' })
  @IsOptional()
  @IsString()
  @MaxLength(255)
  description?: string;

  @ApiPropertyOptional({ example: true })
  @IsOptional()
  @Type(() => Boolean)
  @IsBoolean()
  isPublic?: boolean;
}
