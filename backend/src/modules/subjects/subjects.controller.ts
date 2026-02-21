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
import { SubjectCategory } from '@prisma/client';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { RequirePermissions } from '../../common/decorators/permissions.decorator';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { PermissionsGuard } from '../../common/guards/permissions.guard';
import type { AuthUser } from '../../common/interfaces/auth-user.interface';
import { CreateSubjectDto } from './dto/create-subject.dto';
import { ListSubjectsDto } from './dto/list-subjects.dto';
import { UpdateSubjectDto } from './dto/update-subject.dto';
import { SubjectsService } from './subjects.service';

@ApiTags('Subjects')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, PermissionsGuard)
@Controller('subjects')
export class SubjectsController {
  constructor(private readonly subjectsService: SubjectsService) {}

  @Post()
  @RequirePermissions('subjects.create')
  @ApiOperation({ summary: 'Create subject' })
  create(@Body() payload: CreateSubjectDto, @CurrentUser() user: AuthUser) {
    return this.subjectsService.create(payload, user.userId);
  }

  @Get()
  @RequirePermissions('subjects.read')
  @ApiOperation({ summary: 'Get paginated subjects' })
  @ApiQuery({ name: 'page', required: false, type: Number })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  @ApiQuery({ name: 'search', required: false, type: String })
  @ApiQuery({ name: 'category', required: false, enum: SubjectCategory })
  @ApiQuery({ name: 'isActive', required: false, type: Boolean })
  findAll(@Query() query: ListSubjectsDto) {
    return this.subjectsService.findAll(query);
  }

  @Get(':id')
  @RequirePermissions('subjects.read')
  @ApiOperation({ summary: 'Get subject by ID' })
  findOne(@Param('id') id: string) {
    return this.subjectsService.findOne(id);
  }

  @Patch(':id')
  @RequirePermissions('subjects.update')
  @ApiOperation({ summary: 'Update subject' })
  update(
    @Param('id') id: string,
    @Body() payload: UpdateSubjectDto,
    @CurrentUser() user: AuthUser,
  ) {
    return this.subjectsService.update(id, payload, user.userId);
  }

  @Delete(':id')
  @RequirePermissions('subjects.delete')
  @ApiOperation({ summary: 'Soft delete subject' })
  remove(@Param('id') id: string, @CurrentUser() user: AuthUser) {
    return this.subjectsService.remove(id, user.userId);
  }
}
