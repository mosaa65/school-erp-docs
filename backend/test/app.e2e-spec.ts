import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import { PrismaClient } from '@prisma/client';
import { hash } from 'bcrypt';
import request from 'supertest';
import { App } from 'supertest/types';
import { AppModule } from '../src/app.module';
import { HttpExceptionFilter } from '../src/common/filters/http-exception.filter';

type LoginBody = {
  accessToken: string;
  user: {
    id: string;
    email: string;
    permissionCodes: string[];
  };
};

type UsersListBody = {
  data: unknown[];
  pagination: {
    total: number;
  };
};

type CreateSettingBody = {
  id: string;
  key: string;
};

type GetSettingBody = {
  value: string;
};

type AcademicYearBody = {
  id: string;
  code: string;
  status: string;
  isCurrent: boolean;
  terms?: unknown[];
};

type AcademicTermBody = {
  id: string;
  academicYearId: string;
  code: string;
};

type GradeLevelBody = {
  id: string;
  code: string;
  sections?: unknown[];
};

type SectionBody = {
  id: string;
  gradeLevelId: string;
  code: string;
};

type SubjectBody = {
  id: string;
  code: string;
};

type ErrorEnvelope = {
  success: boolean;
  statusCode: number;
  error: {
    code: string;
    message: string | string[];
    details?: unknown;
  };
};

const ADMIN_EMAIL = 'admin@school.local';
const ADMIN_PASSWORD = 'ChangeMe123!';
const UNIQUE_SUFFIX = `${Date.now()}_${Math.floor(Math.random() * 10000)}`;
const LIMITED_USER_EMAIL = `e2e.readonly.${UNIQUE_SUFFIX}@school.local`;
const LIMITED_USER_PASSWORD = 'ChangeMe123!';
const LIMITED_ROLE_CODE = `e2e_read_only_${UNIQUE_SUFFIX}`;
const E2E_SETTING_KEY_PREFIX = `school.e2e.${UNIQUE_SUFFIX}`;
const E2E_ACADEMIC_YEAR_CODE_PREFIX = `ay.e2e.${UNIQUE_SUFFIX}`;
const E2E_ACADEMIC_TERM_CODE_PREFIX = `term.e2e.${UNIQUE_SUFFIX}`;
const E2E_GRADE_LEVEL_CODE_PREFIX = `grade.e2e.${UNIQUE_SUFFIX}`;
const E2E_SECTION_CODE_PREFIX = `section.e2e.${UNIQUE_SUFFIX}`;
const E2E_SUBJECT_CODE_PREFIX = `subject.e2e.${UNIQUE_SUFFIX}`;

describe('System 01 + 02 (e2e)', () => {
  let app: INestApplication<App>;
  let prisma: PrismaClient;
  let adminAccessToken = '';
  let limitedAccessToken = '';
  let limitedUserId = '';
  let limitedRoleId = '';

  const httpServer = (): App => app.getHttpServer();
  const normalizeMessage = (message: string | string[]): string =>
    Array.isArray(message) ? message.join(' | ') : message;

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    app.useGlobalPipes(
      new ValidationPipe({
        whitelist: true,
        transform: true,
        forbidNonWhitelisted: true,
      }),
    );
    app.useGlobalFilters(new HttpExceptionFilter());

    await app.init();

    prisma = new PrismaClient();

    const adminLoginResponse = await request(httpServer())
      .post('/auth/login')
      .send({
        email: ADMIN_EMAIL,
        password: ADMIN_PASSWORD,
      })
      .expect(200);

    const adminLoginBody = adminLoginResponse.body as LoginBody;
    adminAccessToken = adminLoginBody.accessToken;

    const globalSettingsReadPermission = await prisma.permission.findUnique({
      where: {
        code: 'global-settings.read',
      },
      select: {
        id: true,
      },
    });

    if (!globalSettingsReadPermission) {
      throw new Error('Missing seed permission: global-settings.read');
    }

    const limitedRole = await prisma.role.create({
      data: {
        code: LIMITED_ROLE_CODE,
        name: 'E2E Read-Only Role',
        description: 'Used for RBAC negative tests',
        isSystem: false,
        isActive: true,
      },
      select: {
        id: true,
      },
    });

    limitedRoleId = limitedRole.id;

    await prisma.rolePermission.create({
      data: {
        roleId: limitedRole.id,
        permissionId: globalSettingsReadPermission.id,
      },
    });

    const limitedPasswordHash = await hash(LIMITED_USER_PASSWORD, 12);

    const limitedUser = await prisma.user.create({
      data: {
        email: LIMITED_USER_EMAIL,
        passwordHash: limitedPasswordHash,
        firstName: 'E2E',
        lastName: 'ReadOnly',
        isActive: true,
      },
      select: {
        id: true,
      },
    });

    limitedUserId = limitedUser.id;

    await prisma.userRole.create({
      data: {
        userId: limitedUser.id,
        roleId: limitedRole.id,
      },
    });

    const limitedLoginResponse = await request(httpServer())
      .post('/auth/login')
      .send({
        email: LIMITED_USER_EMAIL,
        password: LIMITED_USER_PASSWORD,
      })
      .expect(200);

    const limitedLoginBody = limitedLoginResponse.body as LoginBody;
    limitedAccessToken = limitedLoginBody.accessToken;
  });

  afterAll(async () => {
    await prisma.section.deleteMany({
      where: {
        code: {
          startsWith: E2E_SECTION_CODE_PREFIX,
        },
      },
    });

    await prisma.gradeLevel.deleteMany({
      where: {
        code: {
          startsWith: E2E_GRADE_LEVEL_CODE_PREFIX,
        },
      },
    });

    await prisma.subject.deleteMany({
      where: {
        code: {
          startsWith: E2E_SUBJECT_CODE_PREFIX,
        },
      },
    });

    await prisma.academicTerm.deleteMany({
      where: {
        code: {
          startsWith: E2E_ACADEMIC_TERM_CODE_PREFIX,
        },
      },
    });

    await prisma.academicYear.deleteMany({
      where: {
        code: {
          startsWith: E2E_ACADEMIC_YEAR_CODE_PREFIX,
        },
      },
    });

    await prisma.globalSetting.deleteMany({
      where: {
        key: {
          startsWith: E2E_SETTING_KEY_PREFIX,
        },
      },
    });

    if (limitedUserId) {
      await prisma.userRole.deleteMany({
        where: {
          userId: limitedUserId,
        },
      });
    }

    if (limitedRoleId) {
      await prisma.rolePermission.deleteMany({
        where: {
          roleId: limitedRoleId,
        },
      });
    }

    if (limitedUserId) {
      await prisma.user.deleteMany({
        where: {
          id: limitedUserId,
        },
      });
    }

    if (limitedRoleId) {
      await prisma.role.deleteMany({
        where: {
          id: limitedRoleId,
        },
      });
    }

    await prisma.$disconnect();
    await app.close();
  });

  it('GET /health should return service health payload', async () => {
    const response = await request(httpServer()).get('/health').expect(200);
    const body = response.body as { status: string; service: string };

    expect(body.status).toBe('ok');
    expect(body.service).toBe('school-erp-backend');
  });

  it('POST /auth/login should authenticate seeded super admin', async () => {
    const response = await request(httpServer())
      .post('/auth/login')
      .send({
        email: ADMIN_EMAIL,
        password: ADMIN_PASSWORD,
      })
      .expect(200);

    const body = response.body as LoginBody;

    expect(body.accessToken).toBeDefined();
    expect(body.user.email).toBe('admin@school.local');
    expect(Array.isArray(body.user.permissionCodes)).toBe(true);
  });

  it('GET /users should require JWT authentication', async () => {
    await request(httpServer()).get('/users').expect(401);
  });

  it('GET /users should return paginated users with valid token', async () => {
    const response = await request(httpServer())
      .get('/users')
      .set('Authorization', `Bearer ${adminAccessToken}`)
      .expect(200);

    const body = response.body as UsersListBody;

    expect(body.data).toBeDefined();
    expect(body.pagination).toBeDefined();
    expect(body.pagination.total).toBeGreaterThanOrEqual(1);
  });

  it('Global settings CRUD flow should work end-to-end', async () => {
    const uniqueKey = `${E2E_SETTING_KEY_PREFIX}.crud`;

    const createResponse = await request(httpServer())
      .post('/global-settings')
      .set('Authorization', `Bearer ${adminAccessToken}`)
      .send({
        key: uniqueKey,
        valueType: 'STRING',
        value: 'Initial Value',
        description: 'E2E temporary setting',
        isPublic: false,
      })
      .expect(201);

    const createBody = createResponse.body as CreateSettingBody;
    const settingId = createBody.id;

    expect(settingId).toBeDefined();
    expect(createBody.key).toBe(uniqueKey);

    const getResponse = await request(httpServer())
      .get(`/global-settings/${settingId}`)
      .set('Authorization', `Bearer ${adminAccessToken}`)
      .expect(200);

    const getBody = getResponse.body as GetSettingBody;
    expect(getBody.value).toBe('Initial Value');

    await request(httpServer())
      .patch(`/global-settings/${settingId}`)
      .set('Authorization', `Bearer ${adminAccessToken}`)
      .send({
        value: 'Updated Value',
      })
      .expect(200);

    const listResponse = await request(httpServer())
      .get('/global-settings')
      .set('Authorization', `Bearer ${adminAccessToken}`)
      .query({ search: uniqueKey })
      .expect(200);

    const listBody = listResponse.body as UsersListBody;
    expect(listBody.pagination.total).toBeGreaterThanOrEqual(1);

    await request(httpServer())
      .delete(`/global-settings/${settingId}`)
      .set('Authorization', `Bearer ${adminAccessToken}`)
      .expect(200);

    await request(httpServer())
      .get(`/global-settings/${settingId}`)
      .set('Authorization', `Bearer ${adminAccessToken}`)
      .expect(404);
  });

  it('GET /users should return 403 for user without users.read permission', async () => {
    const response = await request(httpServer())
      .get('/users')
      .set('Authorization', `Bearer ${limitedAccessToken}`)
      .expect(403);

    const body = response.body as ErrorEnvelope;
    expect(body.success).toBe(false);
    expect(body.statusCode).toBe(403);
    expect(normalizeMessage(body.error.message)).toContain(
      'Insufficient permissions',
    );
  });

  it('POST /global-settings should reject invalid key format', async () => {
    const response = await request(httpServer())
      .post('/global-settings')
      .set('Authorization', `Bearer ${adminAccessToken}`)
      .send({
        key: 'Invalid Key Format',
        valueType: 'STRING',
        value: 'x',
      })
      .expect(400);

    const body = response.body as ErrorEnvelope;
    expect(body.success).toBe(false);
    expect(body.statusCode).toBe(400);
    expect(normalizeMessage(body.error.message)).toContain('key must match');
  });

  it('POST /global-settings should reject non-whitelisted properties', async () => {
    const response = await request(httpServer())
      .post('/global-settings')
      .set('Authorization', `Bearer ${adminAccessToken}`)
      .send({
        key: `${E2E_SETTING_KEY_PREFIX}.whitelist`,
        valueType: 'STRING',
        value: 'x',
        extraField: 'not-allowed',
      })
      .expect(400);

    const body = response.body as ErrorEnvelope;
    expect(body.success).toBe(false);
    expect(body.statusCode).toBe(400);
    expect(normalizeMessage(body.error.message)).toContain('should not exist');
  });

  it('POST /global-settings should reject valueType and value mismatch', async () => {
    const response = await request(httpServer())
      .post('/global-settings')
      .set('Authorization', `Bearer ${adminAccessToken}`)
      .send({
        key: `${E2E_SETTING_KEY_PREFIX}.type-mismatch`,
        valueType: 'NUMBER',
        value: 'not-a-number',
      })
      .expect(400);

    const body = response.body as ErrorEnvelope;
    expect(body.success).toBe(false);
    expect(body.statusCode).toBe(400);
    expect(normalizeMessage(body.error.message)).toContain(
      'Value does not match valueType NUMBER',
    );
  });

  it('GET /academic-years should return 403 for user without academic-years.read permission', async () => {
    const response = await request(httpServer())
      .get('/academic-years')
      .set('Authorization', `Bearer ${limitedAccessToken}`)
      .expect(403);

    const body = response.body as ErrorEnvelope;
    expect(body.success).toBe(false);
    expect(body.statusCode).toBe(403);
    expect(normalizeMessage(body.error.message)).toContain(
      'Insufficient permissions',
    );
  });

  it('Academic years and terms CRUD flow should work end-to-end', async () => {
    const baseYear = 2200 + Math.floor(Math.random() * 300);
    const academicYearCode = `${E2E_ACADEMIC_YEAR_CODE_PREFIX}.crud`;
    const termCode = `${E2E_ACADEMIC_TERM_CODE_PREFIX}.crud`;
    const yearStartDate = `${baseYear}-09-01T00:00:00.000Z`;
    const yearEndDate = `${baseYear + 1}-06-30T23:59:59.000Z`;
    const termStartDate = `${baseYear}-09-01T00:00:00.000Z`;
    const termEndDate = `${baseYear}-12-31T23:59:59.000Z`;

    const createYearResponse = await request(httpServer())
      .post('/academic-years')
      .set('Authorization', `Bearer ${adminAccessToken}`)
      .send({
        code: academicYearCode,
        name: `Academic Year ${baseYear}/${baseYear + 1}`,
        startDate: yearStartDate,
        endDate: yearEndDate,
        status: 'PLANNED',
      })
      .expect(201);

    const createdYear = createYearResponse.body as AcademicYearBody;
    expect(createdYear.id).toBeDefined();
    expect(createdYear.code).toBe(academicYearCode);

    const createTermResponse = await request(httpServer())
      .post('/academic-terms')
      .set('Authorization', `Bearer ${adminAccessToken}`)
      .send({
        academicYearId: createdYear.id,
        code: termCode,
        name: 'Term 1',
        termType: 'SEMESTER',
        sequence: 1,
        startDate: termStartDate,
        endDate: termEndDate,
      })
      .expect(201);

    const createdTerm = createTermResponse.body as AcademicTermBody;
    expect(createdTerm.id).toBeDefined();
    expect(createdTerm.academicYearId).toBe(createdYear.id);
    expect(createdTerm.code).toBe(termCode);

    await request(httpServer())
      .patch(`/academic-terms/${createdTerm.id}`)
      .set('Authorization', `Bearer ${adminAccessToken}`)
      .send({
        name: 'Term 1 Updated',
      })
      .expect(200);

    const getYearResponse = await request(httpServer())
      .get(`/academic-years/${createdYear.id}`)
      .set('Authorization', `Bearer ${adminAccessToken}`)
      .expect(200);

    const yearBody = getYearResponse.body as AcademicYearBody;
    expect(Array.isArray(yearBody.terms)).toBe(true);
    expect(yearBody.terms?.length).toBeGreaterThanOrEqual(1);

    await request(httpServer())
      .delete(`/academic-terms/${createdTerm.id}`)
      .set('Authorization', `Bearer ${adminAccessToken}`)
      .expect(200);

    await request(httpServer())
      .delete(`/academic-years/${createdYear.id}`)
      .set('Authorization', `Bearer ${adminAccessToken}`)
      .expect(200);

    await request(httpServer())
      .get(`/academic-years/${createdYear.id}`)
      .set('Authorization', `Bearer ${adminAccessToken}`)
      .expect(404);
  });

  it('POST /academic-terms should reject term dates outside academic year range', async () => {
    const baseYear = 2600 + Math.floor(Math.random() * 100);
    const academicYearCode = `${E2E_ACADEMIC_YEAR_CODE_PREFIX}.validation`;
    const termCode = `${E2E_ACADEMIC_TERM_CODE_PREFIX}.validation`;

    const createYearResponse = await request(httpServer())
      .post('/academic-years')
      .set('Authorization', `Bearer ${adminAccessToken}`)
      .send({
        code: academicYearCode,
        name: `Academic Year ${baseYear}/${baseYear + 1}`,
        startDate: `${baseYear}-09-01T00:00:00.000Z`,
        endDate: `${baseYear + 1}-06-30T23:59:59.000Z`,
      })
      .expect(201);

    const createdYear = createYearResponse.body as AcademicYearBody;

    const response = await request(httpServer())
      .post('/academic-terms')
      .set('Authorization', `Bearer ${adminAccessToken}`)
      .send({
        academicYearId: createdYear.id,
        code: termCode,
        name: 'Invalid Term',
        termType: 'SEMESTER',
        sequence: 1,
        startDate: `${baseYear}-08-01T00:00:00.000Z`,
        endDate: `${baseYear}-12-31T23:59:59.000Z`,
      })
      .expect(400);

    const body = response.body as ErrorEnvelope;
    expect(body.success).toBe(false);
    expect(body.statusCode).toBe(400);
    expect(normalizeMessage(body.error.message)).toContain(
      'must be within academic year date range',
    );
  });

  it('GET /grade-levels should return 403 for user without grade-levels.read permission', async () => {
    const response = await request(httpServer())
      .get('/grade-levels')
      .set('Authorization', `Bearer ${limitedAccessToken}`)
      .expect(403);

    const body = response.body as ErrorEnvelope;
    expect(body.success).toBe(false);
    expect(body.statusCode).toBe(403);
    expect(normalizeMessage(body.error.message)).toContain(
      'Insufficient permissions',
    );
  });

  it('Grade levels, sections, and subjects CRUD flow should work end-to-end', async () => {
    const sequence = 500 + Math.floor(Math.random() * 400);
    const gradeLevelCode = `${E2E_GRADE_LEVEL_CODE_PREFIX}.crud`;
    const sectionCode = `${E2E_SECTION_CODE_PREFIX}.crud`;
    const subjectCode = `${E2E_SUBJECT_CODE_PREFIX}.crud`;

    const createGradeLevelResponse = await request(httpServer())
      .post('/grade-levels')
      .set('Authorization', `Bearer ${adminAccessToken}`)
      .send({
        code: gradeLevelCode,
        name: 'Grade CRUD',
        stage: 'PRIMARY',
        sequence,
        isActive: true,
      })
      .expect(201);

    const createdGradeLevel = createGradeLevelResponse.body as GradeLevelBody;
    expect(createdGradeLevel.id).toBeDefined();
    expect(createdGradeLevel.code).toBe(gradeLevelCode);

    const createSectionResponse = await request(httpServer())
      .post('/sections')
      .set('Authorization', `Bearer ${adminAccessToken}`)
      .send({
        gradeLevelId: createdGradeLevel.id,
        code: sectionCode,
        name: 'Section CRUD',
        capacity: 30,
      })
      .expect(201);

    const createdSection = createSectionResponse.body as SectionBody;
    expect(createdSection.id).toBeDefined();
    expect(createdSection.gradeLevelId).toBe(createdGradeLevel.id);

    const createSubjectResponse = await request(httpServer())
      .post('/subjects')
      .set('Authorization', `Bearer ${adminAccessToken}`)
      .send({
        code: subjectCode,
        name: 'Mathematics CRUD',
        shortName: 'MATH',
        category: 'MATHEMATICS',
      })
      .expect(201);

    const createdSubject = createSubjectResponse.body as SubjectBody;
    expect(createdSubject.id).toBeDefined();
    expect(createdSubject.code).toBe(subjectCode);

    await request(httpServer())
      .patch(`/sections/${createdSection.id}`)
      .set('Authorization', `Bearer ${adminAccessToken}`)
      .send({
        capacity: 35,
      })
      .expect(200);

    await request(httpServer())
      .patch(`/subjects/${createdSubject.id}`)
      .set('Authorization', `Bearer ${adminAccessToken}`)
      .send({
        name: 'Mathematics Updated',
      })
      .expect(200);

    const getGradeLevelResponse = await request(httpServer())
      .get(`/grade-levels/${createdGradeLevel.id}`)
      .set('Authorization', `Bearer ${adminAccessToken}`)
      .expect(200);

    const gradeLevelBody = getGradeLevelResponse.body as GradeLevelBody;
    expect(Array.isArray(gradeLevelBody.sections)).toBe(true);
    expect(gradeLevelBody.sections?.length).toBeGreaterThanOrEqual(1);

    await request(httpServer())
      .delete(`/sections/${createdSection.id}`)
      .set('Authorization', `Bearer ${adminAccessToken}`)
      .expect(200);

    await request(httpServer())
      .delete(`/grade-levels/${createdGradeLevel.id}`)
      .set('Authorization', `Bearer ${adminAccessToken}`)
      .expect(200);

    await request(httpServer())
      .delete(`/subjects/${createdSubject.id}`)
      .set('Authorization', `Bearer ${adminAccessToken}`)
      .expect(200);

    await request(httpServer())
      .get(`/sections/${createdSection.id}`)
      .set('Authorization', `Bearer ${adminAccessToken}`)
      .expect(404);

    await request(httpServer())
      .get(`/grade-levels/${createdGradeLevel.id}`)
      .set('Authorization', `Bearer ${adminAccessToken}`)
      .expect(404);

    await request(httpServer())
      .get(`/subjects/${createdSubject.id}`)
      .set('Authorization', `Bearer ${adminAccessToken}`)
      .expect(404);
  });

  it('POST /sections should reject invalid grade level reference', async () => {
    const response = await request(httpServer())
      .post('/sections')
      .set('Authorization', `Bearer ${adminAccessToken}`)
      .send({
        gradeLevelId: 'non-existing-grade-level-id',
        code: `${E2E_SECTION_CODE_PREFIX}.badref`,
        name: 'Invalid Grade Section',
      })
      .expect(400);

    const body = response.body as ErrorEnvelope;
    expect(body.success).toBe(false);
    expect(body.statusCode).toBe(400);
    expect(normalizeMessage(body.error.message)).toContain(
      'Grade level is invalid or deleted',
    );
  });

  it('POST /subjects should reject duplicate subject codes', async () => {
    const duplicateSubjectCode = `${E2E_SUBJECT_CODE_PREFIX}.duplicate`;

    await request(httpServer())
      .post('/subjects')
      .set('Authorization', `Bearer ${adminAccessToken}`)
      .send({
        code: duplicateSubjectCode,
        name: 'Duplicate Subject First',
      })
      .expect(201);

    const response = await request(httpServer())
      .post('/subjects')
      .set('Authorization', `Bearer ${adminAccessToken}`)
      .send({
        code: duplicateSubjectCode,
        name: 'Duplicate Subject Second',
      })
      .expect(409);

    const body = response.body as ErrorEnvelope;
    expect(body.success).toBe(false);
    expect(body.statusCode).toBe(409);
    expect(normalizeMessage(body.error.message)).toContain('must be unique');
  });

  it('POST /global-settings should reject duplicate keys', async () => {
    const duplicateKey = `${E2E_SETTING_KEY_PREFIX}.duplicate`;

    await request(httpServer())
      .post('/global-settings')
      .set('Authorization', `Bearer ${adminAccessToken}`)
      .send({
        key: duplicateKey,
        valueType: 'STRING',
        value: 'first-value',
      })
      .expect(201);

    const response = await request(httpServer())
      .post('/global-settings')
      .set('Authorization', `Bearer ${adminAccessToken}`)
      .send({
        key: duplicateKey,
        valueType: 'STRING',
        value: 'second-value',
      })
      .expect(409);

    const body = response.body as ErrorEnvelope;
    expect(body.success).toBe(false);
    expect(body.statusCode).toBe(409);
    expect(normalizeMessage(body.error.message)).toContain('must be unique');
  });
});
