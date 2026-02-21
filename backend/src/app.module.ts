import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { AuthModule } from './auth/auth.module';
import { AcademicTermsModule } from './modules/academic-terms/academic-terms.module';
import { AcademicYearsModule } from './modules/academic-years/academic-years.module';
import { AuditLogsModule } from './modules/audit-logs/audit-logs.module';
import { GradeLevelsModule } from './modules/grade-levels/grade-levels.module';
import { GlobalSettingsModule } from './modules/global-settings/global-settings.module';
import { PermissionsModule } from './modules/permissions/permissions.module';
import { RolesModule } from './modules/roles/roles.module';
import { SectionsModule } from './modules/sections/sections.module';
import { SubjectsModule } from './modules/subjects/subjects.module';
import { UsersModule } from './modules/users/users.module';
import { PrismaModule } from './prisma/prisma.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: ['.env'],
    }),
    PrismaModule,
    AuthModule,
    AcademicYearsModule,
    AcademicTermsModule,
    GradeLevelsModule,
    SectionsModule,
    SubjectsModule,
    UsersModule,
    RolesModule,
    PermissionsModule,
    AuditLogsModule,
    GlobalSettingsModule,
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
