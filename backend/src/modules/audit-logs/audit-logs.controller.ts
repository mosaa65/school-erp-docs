import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Post,
  Query,
  Req,
  UseGuards,
} from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOperation,
  ApiQuery,
  ApiTags,
} from '@nestjs/swagger';
import type { Request } from 'express';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { RequirePermissions } from '../../common/decorators/permissions.decorator';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { PermissionsGuard } from '../../common/guards/permissions.guard';
import type { AuthUser } from '../../common/interfaces/auth-user.interface';
import { AuditLogsService } from './audit-logs.service';
import { CreateAuditLogDto } from './dto/create-audit-log.dto';
import { ListAuditLogsDto } from './dto/list-audit-logs.dto';

@ApiTags('Audit Logs')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, PermissionsGuard)
@Controller('audit-logs')
export class AuditLogsController {
  constructor(private readonly auditLogsService: AuditLogsService) {}

  @Post()
  @RequirePermissions('audit-logs.create')
  @ApiOperation({ summary: 'Create audit log entry manually' })
  create(
    @Body() createAuditLogDto: CreateAuditLogDto,
    @CurrentUser() user: AuthUser,
    @Req() req: Request,
  ) {
    return this.auditLogsService.createManual(
      createAuditLogDto,
      user.userId,
      req.ip,
      req.headers['user-agent'],
    );
  }

  @Get()
  @RequirePermissions('audit-logs.read')
  @ApiOperation({ summary: 'Get paginated audit logs' })
  @ApiQuery({ name: 'page', required: false, type: Number })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  findAll(@Query() query: ListAuditLogsDto) {
    return this.auditLogsService.findAll(query);
  }

  @Get(':id')
  @RequirePermissions('audit-logs.read')
  @ApiOperation({ summary: 'Get audit log by ID' })
  findOne(@Param('id') id: string) {
    return this.auditLogsService.findOne(id);
  }

  @Delete(':id')
  @RequirePermissions('audit-logs.delete')
  @ApiOperation({ summary: 'Soft delete audit log entry' })
  remove(@Param('id') id: string, @CurrentUser() user: AuthUser) {
    return this.auditLogsService.remove(id, user.userId);
  }
}
