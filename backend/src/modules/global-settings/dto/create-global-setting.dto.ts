import { Type } from 'class-transformer';
import {
  Allow,
  IsBoolean,
  IsEnum,
  IsOptional,
  IsString,
  Matches,
  MaxLength,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { SettingValueType } from '@prisma/client';

export class CreateGlobalSettingDto {
  @ApiProperty({ example: 'school.name' })
  @IsString()
  @Matches(/^[a-z0-9_.:-]+$/)
  @MaxLength(120)
  key!: string;

  @ApiProperty({ enum: SettingValueType, example: SettingValueType.STRING })
  @IsEnum(SettingValueType)
  valueType!: SettingValueType;

  @ApiProperty({
    description: 'Setting value. Must match valueType.',
    example: 'Naseem International School',
  })
  @Allow()
  value!: unknown;

  @ApiPropertyOptional({
    example: 'Displayed in official documents and reports.',
  })
  @IsOptional()
  @IsString()
  @MaxLength(255)
  description?: string;

  @ApiPropertyOptional({ example: false })
  @IsOptional()
  @Type(() => Boolean)
  @IsBoolean()
  isPublic?: boolean;
}
