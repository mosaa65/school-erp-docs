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
import { CreateGlobalSettingDto } from './dto/create-global-setting.dto';
import { ListGlobalSettingsDto } from './dto/list-global-settings.dto';
import { UpdateGlobalSettingDto } from './dto/update-global-setting.dto';
import { GlobalSettingsService } from './global-settings.service';

@ApiTags('Global Settings')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, PermissionsGuard)
@Controller('global-settings')
export class GlobalSettingsController {
  constructor(private readonly globalSettingsService: GlobalSettingsService) {}

  @Post()
  @RequirePermissions('global-settings.create')
  @ApiOperation({ summary: 'Create global setting' })
  create(
    @Body() payload: CreateGlobalSettingDto,
    @CurrentUser() user: AuthUser,
  ) {
    return this.globalSettingsService.create(payload, user.userId);
  }

  @Get()
  @RequirePermissions('global-settings.read')
  @ApiOperation({ summary: 'Get paginated global settings' })
  @ApiQuery({ name: 'page', required: false, type: Number })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  @ApiQuery({ name: 'search', required: false, type: String })
  @ApiQuery({ name: 'isPublic', required: false, type: Boolean })
  findAll(@Query() query: ListGlobalSettingsDto) {
    return this.globalSettingsService.findAll(query);
  }

  @Get(':id')
  @RequirePermissions('global-settings.read')
  @ApiOperation({ summary: 'Get global setting by ID' })
  findOne(@Param('id') id: string) {
    return this.globalSettingsService.findOne(id);
  }

  @Patch(':id')
  @RequirePermissions('global-settings.update')
  @ApiOperation({ summary: 'Update global setting' })
  update(
    @Param('id') id: string,
    @Body() payload: UpdateGlobalSettingDto,
    @CurrentUser() user: AuthUser,
  ) {
    return this.globalSettingsService.update(id, payload, user.userId);
  }

  @Delete(':id')
  @RequirePermissions('global-settings.delete')
  @ApiOperation({ summary: 'Soft delete global setting' })
  remove(@Param('id') id: string, @CurrentUser() user: AuthUser) {
    return this.globalSettingsService.remove(id, user.userId);
  }
}
