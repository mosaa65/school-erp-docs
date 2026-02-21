import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOperation,
  ApiQuery,
  ApiTags,
} from '@nestjs/swagger';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { RequirePermissions } from '../../common/decorators/permissions.decorator';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { PermissionsGuard } from '../../common/guards/permissions.guard';
import type { AuthUser } from '../../common/interfaces/auth-user.interface';
import { CreatePermissionDto } from './dto/create-permission.dto';
import { ListPermissionsDto } from './dto/list-permissions.dto';
import { UpdatePermissionDto } from './dto/update-permission.dto';
import { PermissionsService } from './permissions.service';

@ApiTags('Permissions')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, PermissionsGuard)
@Controller('permissions')
export class PermissionsController {
  constructor(private readonly permissionsService: PermissionsService) {}

  @Post()
  @RequirePermissions('permissions.create')
  @ApiOperation({ summary: 'Create permission' })
  create(
    @Body() createPermissionDto: CreatePermissionDto,
    @CurrentUser() user: AuthUser,
  ) {
    return this.permissionsService.create(createPermissionDto, user.userId);
  }

  @Get()
  @RequirePermissions('permissions.read')
  @ApiOperation({ summary: 'Get paginated permissions' })
  @ApiQuery({ name: 'page', required: false, type: Number })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  @ApiQuery({ name: 'search', required: false, type: String })
  findAll(@Query() query: ListPermissionsDto) {
    return this.permissionsService.findAll(query);
  }

  @Get(':id')
  @RequirePermissions('permissions.read')
  @ApiOperation({ summary: 'Get permission by ID' })
  findOne(@Param('id') id: string) {
    return this.permissionsService.findOne(id);
  }

  @Patch(':id')
  @RequirePermissions('permissions.update')
  @ApiOperation({ summary: 'Update permission' })
  update(
    @Param('id') id: string,
    @Body() updatePermissionDto: UpdatePermissionDto,
    @CurrentUser() user: AuthUser,
  ) {
    return this.permissionsService.update(id, updatePermissionDto, user.userId);
  }

  @Delete(':id')
  @RequirePermissions('permissions.delete')
  @ApiOperation({ summary: 'Soft delete permission' })
  remove(@Param('id') id: string, @CurrentUser() user: AuthUser) {
    return this.permissionsService.remove(id, user.userId);
  }
}
