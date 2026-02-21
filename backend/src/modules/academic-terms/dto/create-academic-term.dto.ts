import { Transform, Type } from 'class-transformer';
import {
  IsBoolean,
  IsDateString,
  IsEnum,
  IsInt,
  IsOptional,
  IsString,
  Matches,
  Max,
  MaxLength,
  Min,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { AcademicTermType } from '@prisma/client';

export class CreateAcademicTermDto {
  @ApiProperty({ example: 'cmf2f32b60000uvh95h7tk7q1' })
  @IsString()
  academicYearId!: string;

  @ApiProperty({ example: 'term-1' })
  @Transform(({ value }: { value: string }) => value?.trim().toLowerCase())
  @IsString()
  @Matches(/^[a-z0-9_.:-]+$/)
  @MaxLength(40)
  code!: string;

  @ApiProperty({ example: 'Term 1' })
  @Transform(({ value }: { value: string }) => value?.trim())
  @IsString()
  @MaxLength(120)
  name!: string;

  @ApiPropertyOptional({
    enum: AcademicTermType,
    example: AcademicTermType.SEMESTER,
  })
  @IsOptional()
  @IsEnum(AcademicTermType)
  termType?: AcademicTermType;

  @ApiProperty({ example: 1 })
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(20)
  sequence!: number;

  @ApiProperty({ example: '2026-09-01T00:00:00.000Z' })
  @IsDateString()
  startDate!: string;

  @ApiProperty({ example: '2026-12-31T23:59:59.000Z' })
  @IsDateString()
  endDate!: string;

  @ApiPropertyOptional({ example: true })
  @IsOptional()
  @Type(() => Boolean)
  @IsBoolean()
  isActive?: boolean;
}
