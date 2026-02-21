import { Module } from '@nestjs/common';
import { AuditLogsModule } from '../audit-logs/audit-logs.module';
import { AcademicTermsController } from './academic-terms.controller';
import { AcademicTermsService } from './academic-terms.service';

@Module({
  imports: [AuditLogsModule],
  controllers: [AcademicTermsController],
  providers: [AcademicTermsService],
  exports: [AcademicTermsService],
})
export class AcademicTermsModule {}
