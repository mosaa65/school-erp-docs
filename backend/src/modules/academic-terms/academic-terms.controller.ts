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
import { AcademicTermType } from '@prisma/client';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { RequirePermissions } from '../../common/decorators/permissions.decorator';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { PermissionsGuard } from '../../common/guards/permissions.guard';
import type { AuthUser } from '../../common/interfaces/auth-user.interface';
import { AcademicTermsService } from './academic-terms.service';
import { CreateAcademicTermDto } from './dto/create-academic-term.dto';
import { ListAcademicTermsDto } from './dto/list-academic-terms.dto';
import { UpdateAcademicTermDto } from './dto/update-academic-term.dto';

@ApiTags('Academic Terms')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, PermissionsGuard)
@Controller('academic-terms')
export class AcademicTermsController {
  constructor(private readonly academicTermsService: AcademicTermsService) {}

  @Post()
  @RequirePermissions('academic-terms.create')
  @ApiOperation({ summary: 'Create academic term' })
  create(
    @Body() payload: CreateAcademicTermDto,
    @CurrentUser() user: AuthUser,
  ) {
    return this.academicTermsService.create(payload, user.userId);
  }

  @Get()
  @RequirePermissions('academic-terms.read')
  @ApiOperation({ summary: 'Get paginated academic terms' })
  @ApiQuery({ name: 'page', required: false, type: Number })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  @ApiQuery({ name: 'search', required: false, type: String })
  @ApiQuery({ name: 'academicYearId', required: false, type: String })
  @ApiQuery({
    name: 'termType',
    required: false,
    enum: AcademicTermType,
  })
  @ApiQuery({ name: 'isActive', required: false, type: Boolean })
  findAll(@Query() query: ListAcademicTermsDto) {
    return this.academicTermsService.findAll(query);
  }

  @Get(':id')
  @RequirePermissions('academic-terms.read')
  @ApiOperation({ summary: 'Get academic term by ID' })
  findOne(@Param('id') id: string) {
    return this.academicTermsService.findOne(id);
  }

  @Patch(':id')
  @RequirePermissions('academic-terms.update')
  @ApiOperation({ summary: 'Update academic term' })
  update(
    @Param('id') id: string,
    @Body() payload: UpdateAcademicTermDto,
    @CurrentUser() user: AuthUser,
  ) {
    return this.academicTermsService.update(id, payload, user.userId);
  }

  @Delete(':id')
  @RequirePermissions('academic-terms.delete')
  @ApiOperation({ summary: 'Soft delete academic term' })
  remove(@Param('id') id: string, @CurrentUser() user: AuthUser) {
    return this.academicTermsService.remove(id, user.userId);
  }
}
