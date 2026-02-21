import { Module } from '@nestjs/common';
import { AuditLogsModule } from '../audit-logs/audit-logs.module';
import { GlobalSettingsController } from './global-settings.controller';
import { GlobalSettingsService } from './global-settings.service';

@Module({
  imports: [AuditLogsModule],
  controllers: [GlobalSettingsController],
  providers: [GlobalSettingsService],
  exports: [GlobalSettingsService],
})
export class GlobalSettingsModule {}
