import { Module } from '@nestjs/common';
import { AuditLogsModule } from '../audit-logs/audit-logs.module';
import { GradeLevelsController } from './grade-levels.controller';
import { GradeLevelsService } from './grade-levels.service';

@Module({
  imports: [AuditLogsModule],
  controllers: [GradeLevelsController],
  providers: [GradeLevelsService],
  exports: [GradeLevelsService],
})
export class GradeLevelsModule {}
