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
import { GradeStage } from '@prisma/client';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { RequirePermissions } from '../../common/decorators/permissions.decorator';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { PermissionsGuard } from '../../common/guards/permissions.guard';
import type { AuthUser } from '../../common/interfaces/auth-user.interface';
import { CreateGradeLevelDto } from './dto/create-grade-level.dto';
import { ListGradeLevelsDto } from './dto/list-grade-levels.dto';
import { UpdateGradeLevelDto } from './dto/update-grade-level.dto';
import { GradeLevelsService } from './grade-levels.service';

@ApiTags('Grade Levels')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, PermissionsGuard)
@Controller('grade-levels')
export class GradeLevelsController {
  constructor(private readonly gradeLevelsService: GradeLevelsService) {}

  @Post()
  @RequirePermissions('grade-levels.create')
  @ApiOperation({ summary: 'Create grade level' })
  create(@Body() payload: CreateGradeLevelDto, @CurrentUser() user: AuthUser) {
    return this.gradeLevelsService.create(payload, user.userId);
  }

  @Get()
  @RequirePermissions('grade-levels.read')
  @ApiOperation({ summary: 'Get paginated grade levels' })
  @ApiQuery({ name: 'page', required: false, type: Number })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  @ApiQuery({ name: 'search', required: false, type: String })
  @ApiQuery({ name: 'stage', required: false, enum: GradeStage })
  @ApiQuery({ name: 'isActive', required: false, type: Boolean })
  findAll(@Query() query: ListGradeLevelsDto) {
    return this.gradeLevelsService.findAll(query);
  }

  @Get(':id')
  @RequirePermissions('grade-levels.read')
  @ApiOperation({ summary: 'Get grade level by ID' })
  findOne(@Param('id') id: string) {
    return this.gradeLevelsService.findOne(id);
  }

  @Patch(':id')
  @RequirePermissions('grade-levels.update')
  @ApiOperation({ summary: 'Update grade level' })
  update(
    @Param('id') id: string,
    @Body() payload: UpdateGradeLevelDto,
    @CurrentUser() user: AuthUser,
  ) {
    return this.gradeLevelsService.update(id, payload, user.userId);
  }

  @Delete(':id')
  @RequirePermissions('grade-levels.delete')
  @ApiOperation({ summary: 'Soft delete grade level and linked sections' })
  remove(@Param('id') id: string, @CurrentUser() user: AuthUser) {
    return this.gradeLevelsService.remove(id, user.userId);
  }
}
