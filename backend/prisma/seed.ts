import { PrismaClient } from '@prisma/client';
import { hash } from 'bcrypt';

const prisma = new PrismaClient();

const DEFAULT_PERMISSION_CODES = [
  'users.create',
  'users.read',
  'users.update',
  'users.delete',
  'roles.create',
  'roles.read',
  'roles.update',
  'roles.delete',
  'roles.assign-permissions',
  'permissions.create',
  'permissions.read',
  'permissions.update',
  'permissions.delete',
  'audit-logs.create',
  'audit-logs.read',
  'audit-logs.delete',
  'global-settings.create',
  'global-settings.read',
  'global-settings.update',
  'global-settings.delete',
  'academic-years.create',
  'academic-years.read',
  'academic-years.update',
  'academic-years.delete',
  'academic-terms.create',
  'academic-terms.read',
  'academic-terms.update',
  'academic-terms.delete',
  'grade-levels.create',
  'grade-levels.read',
  'grade-levels.update',
  'grade-levels.delete',
  'sections.create',
  'sections.read',
  'sections.update',
  'sections.delete',
  'subjects.create',
  'subjects.read',
  'subjects.update',
  'subjects.delete',
];

async function main() {
  const adminEmail = process.env.SEED_ADMIN_EMAIL ?? 'admin@school.local';
  const adminPassword = process.env.SEED_ADMIN_PASSWORD ?? 'ChangeMe123!';

  const permissions = [] as Array<{ id: string; code: string }>;

  for (const code of DEFAULT_PERMISSION_CODES) {
    const [resource, action] = code.split('.', 2);

    const permission = await prisma.permission.upsert({
      where: { code },
      update: {
        resource,
        action: action ?? 'manage',
        isSystem: true,
        deletedAt: null,
        updatedById: null,
      },
      create: {
        code,
        resource,
        action: action ?? 'manage',
        description: `System permission for ${code}`,
        isSystem: true,
      },
      select: {
        id: true,
        code: true,
      },
    });

    permissions.push(permission);
  }

  const superAdminRole = await prisma.role.upsert({
    where: {
      code: 'super_admin',
    },
    update: {
      name: 'Super Admin',
      isSystem: true,
      isActive: true,
      deletedAt: null,
      updatedById: null,
    },
    create: {
      code: 'super_admin',
      name: 'Super Admin',
      description: 'Full access role for System 01 foundation modules',
      isSystem: true,
      isActive: true,
    },
    select: {
      id: true,
    },
  });

  for (const permission of permissions) {
    await prisma.rolePermission.upsert({
      where: {
        roleId_permissionId: {
          roleId: superAdminRole.id,
          permissionId: permission.id,
        },
      },
      update: {
        deletedAt: null,
        updatedById: null,
      },
      create: {
        roleId: superAdminRole.id,
        permissionId: permission.id,
      },
    });
  }

  const passwordHash = await hash(adminPassword, 12);

  const adminUser = await prisma.user.upsert({
    where: {
      email: adminEmail,
    },
    update: {
      firstName: 'System',
      lastName: 'Administrator',
      passwordHash,
      isActive: true,
      deletedAt: null,
      updatedById: null,
    },
    create: {
      email: adminEmail,
      passwordHash,
      firstName: 'System',
      lastName: 'Administrator',
      isActive: true,
    },
    select: {
      id: true,
      email: true,
    },
  });

  await prisma.userRole.upsert({
    where: {
      userId_roleId: {
        userId: adminUser.id,
        roleId: superAdminRole.id,
      },
    },
    update: {
      deletedAt: null,
      updatedById: null,
    },
    create: {
      userId: adminUser.id,
      roleId: superAdminRole.id,
    },
  });

  console.log('Seed completed');
  console.log(`Admin email: ${adminUser.email}`);
  console.log(`Admin password: ${adminPassword}`);
}

main()
  .catch((error) => {
    console.error(error);
    process.exitCode = 1;
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
