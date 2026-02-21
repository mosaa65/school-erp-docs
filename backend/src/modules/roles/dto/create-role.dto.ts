import { Transform, Type } from 'class-transformer';
import {
  ArrayUnique,
  IsArray,
  IsBoolean,
  IsOptional,
  IsString,
  Matches,
  MaxLength,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class CreateRoleDto {
  @ApiProperty({ example: 'school_admin' })
  @Transform(({ value }: { value: string }) => value?.trim().toLowerCase())
  @IsString()
  @Matches(/^[a-z0-9_.:-]+$/)
  @MaxLength(120)
  code!: string;

  @ApiProperty({ example: 'School Administrator' })
  @Transform(({ value }: { value: string }) => value?.trim())
  @IsString()
  @MaxLength(120)
  name!: string;

  @ApiPropertyOptional({
    example: 'Full administration access for school operations.',
  })
  @IsOptional()
  @Transform(({ value }: { value: string }) => value?.trim())
  @IsString()
  @MaxLength(255)
  description?: string;

  @ApiPropertyOptional({ example: true })
  @IsOptional()
  @Type(() => Boolean)
  @IsBoolean()
  isActive?: boolean;

  @ApiPropertyOptional({
    type: [String],
    description: 'Permission IDs assigned to role',
  })
  @IsOptional()
  @IsArray()
  @ArrayUnique()
  @IsString({ each: true })
  permissionIds?: string[];
}
