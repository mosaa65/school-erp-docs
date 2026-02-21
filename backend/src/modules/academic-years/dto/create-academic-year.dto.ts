import { Transform, Type } from 'class-transformer';
import {
  IsBoolean,
  IsDateString,
  IsEnum,
  IsOptional,
  IsString,
  Matches,
  MaxLength,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { AcademicYearStatus } from '@prisma/client';

export class CreateAcademicYearDto {
  @ApiProperty({ example: 'ay-2026-2027' })
  @Transform(({ value }: { value: string }) => value?.trim().toLowerCase())
  @IsString()
  @Matches(/^[a-z0-9_.:-]+$/)
  @MaxLength(40)
  code!: string;

  @ApiProperty({ example: 'Academic Year 2026/2027' })
  @Transform(({ value }: { value: string }) => value?.trim())
  @IsString()
  @MaxLength(120)
  name!: string;

  @ApiProperty({ example: '2026-09-01T00:00:00.000Z' })
  @IsDateString()
  startDate!: string;

  @ApiProperty({ example: '2027-06-30T23:59:59.000Z' })
  @IsDateString()
  endDate!: string;

  @ApiPropertyOptional({
    enum: AcademicYearStatus,
    example: AcademicYearStatus.PLANNED,
  })
  @IsOptional()
  @IsEnum(AcademicYearStatus)
  status?: AcademicYearStatus;

  @ApiPropertyOptional({ example: false })
  @IsOptional()
  @Type(() => Boolean)
  @IsBoolean()
  isCurrent?: boolean;
}
