import { Transform, Type } from 'class-transformer';
import {
  IsBoolean,
  IsEnum,
  IsOptional,
  IsString,
  Matches,
  MaxLength,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { SubjectCategory } from '@prisma/client';

export class CreateSubjectDto {
  @ApiProperty({ example: 'math-101' })
  @Transform(({ value }: { value: string }) => value?.trim().toLowerCase())
  @IsString()
  @Matches(/^[a-z0-9_.:-]+$/)
  @MaxLength(40)
  code!: string;

  @ApiProperty({ example: 'Mathematics' })
  @Transform(({ value }: { value: string }) => value?.trim())
  @IsString()
  @MaxLength(120)
  name!: string;

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
