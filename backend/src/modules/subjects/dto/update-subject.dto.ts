import { Transform, Type } from 'class-transformer';
import {
  IsBoolean,
  IsEnum,
  IsOptional,
  IsString,
  Matches,
  MaxLength,
} from 'class-validator';
import { ApiPropertyOptional } from '@nestjs/swagger';
import { SubjectCategory } from '@prisma/client';

export class UpdateSubjectDto {
  @ApiPropertyOptional({ example: 'math-101' })
  @IsOptional()
  @Transform(({ value }: { value: string }) => value?.trim().toLowerCase())
  @IsString()
  @Matches(/^[a-z0-9_.:-]+$/)
  @MaxLength(40)
  code?: string;

  @ApiPropertyOptional({ example: 'Mathematics' })
  @IsOptional()
  @Transform(({ value }: { value: string }) => value?.trim())
  @IsString()
  @MaxLength(120)
  name?: string;

  @ApiPropertyOptional({ example: 'MATH' })
  @IsOptional()
  @Transform(({ value }: { value: string }) => value?.trim())
  @IsString()
  @MaxLength(50)
  shortName?: string;

  @ApiPropertyOptional({
    enum: SubjectCategory,
    example: SubjectCategory.MATHEMATICS,
  })
  @IsOptional()
  @IsEnum(SubjectCategory)
  category?: SubjectCategory;

  @ApiPropertyOptional({ example: true })
  @IsOptional()
  @Type(() => Boolean)
  @IsBoolean()
  isActive?: boolean;
}
