import { ArrayNotEmpty, ArrayUnique, IsArray, IsString } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class AssignRolePermissionsDto {
  @ApiProperty({
    type: [String],
    description: 'Permission IDs that should remain active on role',
  })
  @IsArray()
  @ArrayNotEmpty()
  @ArrayUnique()
  @IsString({ each: true })
  permissionIds!: string[];
}
