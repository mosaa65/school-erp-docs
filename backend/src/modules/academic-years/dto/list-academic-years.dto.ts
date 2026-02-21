import { Type } from 'class-transformer';
import {
  IsBoolean,
  IsEnum,
  IsInt,
  IsOptional,
  IsString,
  Max,
  Min,
} from 'class-validator';
import { ApiPropertyOptional } from '@nestjs/swagger';
import { AcademicYearStatus } from '@prisma/client';

export class ListAcademicYearsDto {
  @ApiPropertyOptional({ example: 1 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  page?: number = 1;

  @ApiPropertyOptional({ example: 20 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(100)
  limit?: number = 20;

  @ApiPropertyOptional({ example: '2026' })
  @IsOptional()
  @IsString()
  search?: string;

  @ApiPropertyOptional({
    enum: AcademicYearStatus,
    example: AcademicYearStatus.ACTIVE,
  })
  @IsOptional()
  @IsEnum(AcademicYearStatus)
  status?: AcademicYearStatus;

  @ApiPropertyOptional({ example: true })
  @IsOptional()
  @Type(() => Boolean)
  @IsBoolean()
  isCurrent?: boolean;
}
