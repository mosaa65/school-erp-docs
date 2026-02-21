import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  Put,
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
import { AssignRolePermissionsDto } from './dto/assign-role-permissions.dto';
import { CreateRoleDto } from './dto/create-role.dto';
import { ListRolesDto } from './dto/list-roles.dto';
import { UpdateRoleDto } from './dto/update-role.dto';
import { RolesService } from './roles.service';

@ApiTags('Roles')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, PermissionsGuard)
@Controller('roles')
export class RolesController {
  constructor(private readonly rolesService: RolesService) {}

  @Post()
  @RequirePermissions('roles.create')
  @ApiOperation({ summary: 'Create role' })
  create(@Body() createRoleDto: CreateRoleDto, @CurrentUser() user: AuthUser) {
    return this.rolesService.create(createRoleDto, user.userId);
  }

  @Get()
  @RequirePermissions('roles.read')
  @ApiOperation({ summary: 'Get paginated roles' })
  @ApiQuery({ name: 'page', required: false, type: Number })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  @ApiQuery({ name: 'search', required: false, type: String })
  findAll(@Query() query: ListRolesDto) {
    return this.rolesService.findAll(query);
  }

  @Get(':id')
  @RequirePermissions('roles.read')
  @ApiOperation({ summary: 'Get role by ID' })
  findOne(@Param('id') id: string) {
    return this.rolesService.findOne(id);
  }

  @Patch(':id')
  @RequirePermissions('roles.update')
  @ApiOperation({ summary: 'Update role' })
  update(
    @Param('id') id: string,
    @Body() updateRoleDto: UpdateRoleDto,
    @CurrentUser() user: AuthUser,
  ) {
    return this.rolesService.update(id, updateRoleDto, user.userId);
  }

  @Put(':id/permissions')
  @RequirePermissions('roles.assign-permissions')
  @ApiOperation({ summary: 'Replace active role-permission assignments' })
  assignPermissions(
    @Param('id') id: string,
    @Body() assignRolePermissionsDto: AssignRolePermissionsDto,
    @CurrentUser() user: AuthUser,
  ) {
    return this.rolesService.assignPermissions(
      id,
      assignRolePermissionsDto,
      user.userId,
    );
  }

  @Delete(':id')
  @RequirePermissions('roles.delete')
  @ApiOperation({ summary: 'Soft delete role' })
  remove(@Param('id') id: string, @CurrentUser() user: AuthUser) {
    return this.rolesService.remove(id, user.userId);
  }
}
