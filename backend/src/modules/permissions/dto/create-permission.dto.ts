import { Transform, Type } from 'class-transformer';
import {
  IsBoolean,
  IsOptional,
  IsString,
  Matches,
  MaxLength,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class CreatePermissionDto {
  @ApiProperty({ example: 'users.create' })
  @Transform(({ value }: { value: string }) => value?.trim().toLowerCase())
  @IsString()
  @Matches(/^[a-z0-9_.:-]+$/)
  @MaxLength(120)
  code!: string;

  @ApiProperty({ example: 'users' })
  @Transform(({ value }: { value: string }) => value?.trim().toLowerCase())
  @IsString()
  @MaxLength(120)
  resource!: string;

  @ApiProperty({ example: 'create' })
  @Transform(({ value }: { value: string }) => value?.trim().toLowerCase())
  @IsString()
  @MaxLength(120)
  action!: string;

  @ApiPropertyOptional({ example: 'Ability to create new users' })
  @IsOptional()
  @Transform(({ value }: { value: string }) => value?.trim())
  @IsString()
  @MaxLength(255)
  description?: string;

  @ApiPropertyOptional({ example: false })
  @IsOptional()
  @Type(() => Boolean)
  @IsBoolean()
  isSystem?: boolean;
}
