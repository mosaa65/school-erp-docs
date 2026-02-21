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
import { AcademicYearStatus } from '@prisma/client';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { RequirePermissions } from '../../common/decorators/permissions.decorator';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { PermissionsGuard } from '../../common/guards/permissions.guard';
import type { AuthUser } from '../../common/interfaces/auth-user.interface';
import { CreateAcademicYearDto } from './dto/create-academic-year.dto';
import { ListAcademicYearsDto } from './dto/list-academic-years.dto';
import { UpdateAcademicYearDto } from './dto/update-academic-year.dto';
import { AcademicYearsService } from './academic-years.service';

@ApiTags('Academic Years')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, PermissionsGuard)
@Controller('academic-years')
export class AcademicYearsController {
  constructor(private readonly academicYearsService: AcademicYearsService) {}

  @Post()
  @RequirePermissions('academic-years.create')
  @ApiOperation({ summary: 'Create academic year' })
  create(
    @Body() payload: CreateAcademicYearDto,
    @CurrentUser() user: AuthUser,
  ) {
    return this.academicYearsService.create(payload, user.userId);
  }

  @Get()
  @RequirePermissions('academic-years.read')
  @ApiOperation({ summary: 'Get paginated academic years' })
  @ApiQuery({ name: 'page', required: false, type: Number })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  @ApiQuery({ name: 'search', required: false, type: String })
  @ApiQuery({
    name: 'status',
    required: false,
    enum: AcademicYearStatus,
  })
  @ApiQuery({ name: 'isCurrent', required: false, type: Boolean })
  findAll(@Query() query: ListAcademicYearsDto) {
    return this.academicYearsService.findAll(query);
  }

  @Get(':id')
  @RequirePermissions('academic-years.read')
  @ApiOperation({ summary: 'Get academic year by ID' })
  findOne(@Param('id') id: string) {
    return this.academicYearsService.findOne(id);
  }

  @Patch(':id')
  @RequirePermissions('academic-years.update')
  @ApiOperation({ summary: 'Update academic year' })
  update(
    @Param('id') id: string,
    @Body() payload: UpdateAcademicYearDto,
    @CurrentUser() user: AuthUser,
  ) {
    return this.academicYearsService.update(id, payload, user.userId);
  }

  @Delete(':id')
  @RequirePermissions('academic-years.delete')
  @ApiOperation({ summary: 'Soft delete academic year and its terms' })
  remove(@Param('id') id: string, @CurrentUser() user: AuthUser) {
    return this.academicYearsService.remove(id, user.userId);
  }
}
