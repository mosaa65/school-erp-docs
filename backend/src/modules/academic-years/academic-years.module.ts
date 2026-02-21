import { Module } from '@nestjs/common';
import { AuditLogsModule } from '../audit-logs/audit-logs.module';
import { AcademicYearsController } from './academic-years.controller';
import { AcademicYearsService } from './academic-years.service';

@Module({
  imports: [AuditLogsModule],
  controllers: [AcademicYearsController],
  providers: [AcademicYearsService],
  exports: [AcademicYearsService],
})
export class AcademicYearsModule {}
