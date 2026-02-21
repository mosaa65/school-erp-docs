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
import { CreateSectionDto } from './dto/create-section.dto';
import { ListSectionsDto } from './dto/list-sections.dto';
import { UpdateSectionDto } from './dto/update-section.dto';
import { SectionsService } from './sections.service';

@ApiTags('Sections')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, PermissionsGuard)
@Controller('sections')
export class SectionsController {
  constructor(private readonly sectionsService: SectionsService) {}

  @Post()
  @RequirePermissions('sections.create')
  @ApiOperation({ summary: 'Create section' })
  create(@Body() payload: CreateSectionDto, @CurrentUser() user: AuthUser) {
    return this.sectionsService.create(payload, user.userId);
  }

  @Get()
  @RequirePermissions('sections.read')
  @ApiOperation({ summary: 'Get paginated sections' })
  @ApiQuery({ name: 'page', required: false, type: Number })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  @ApiQuery({ name: 'search', required: false, type: String })
  @ApiQuery({ name: 'gradeLevelId', required: false, type: String })
  @ApiQuery({ name: 'isActive', required: false, type: Boolean })
  findAll(@Query() query: ListSectionsDto) {
    return this.sectionsService.findAll(query);
  }

  @Get(':id')
  @RequirePermissions('sections.read')
  @ApiOperation({ summary: 'Get section by ID' })
  findOne(@Param('id') id: string) {
    return this.sectionsService.findOne(id);
  }

  @Patch(':id')
  @RequirePermissions('sections.update')
  @ApiOperation({ summary: 'Update section' })
  update(
    @Param('id') id: string,
    @Body() payload: UpdateSectionDto,
    @CurrentUser() user: AuthUser,
  ) {
    return this.sectionsService.update(id, payload, user.userId);
  }

  @Delete(':id')
  @RequirePermissions('sections.delete')
  @ApiOperation({ summary: 'Soft delete section' })
  remove(@Param('id') id: string, @CurrentUser() user: AuthUser) {
    return this.sectionsService.remove(id, user.userId);
  }
}
