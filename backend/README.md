# School ERP Backend - System 01 (Shared Infrastructure)

Backend foundation for **School ERP** using NestJS + Prisma + MySQL, limited to System 01 scope:

- Users
- Roles
- Permissions
- Audit Logs
- Global Settings (schema ready)

## Tech Stack

- Node.js + NestJS (TypeScript)
- Prisma ORM + MySQL
- REST APIs + Swagger
- JWT Authentication
- RBAC (permission-based)

## What Is Implemented

- Strict modular architecture (`auth`, `users`, `roles`, `permissions`, `audit-logs`, `prisma`)
- Prisma schema with:
  - soft delete (`deleted_at`) on all System 01 tables
  - audit fields (`created_by`, `updated_by`, timestamps)
- Global request validation (`ValidationPipe`)
- Global error response filter
- Structured JSON logging
- Swagger documentation for all current endpoints
- Initial migration script:
  - `prisma/migrations/20260221000000_init_system_01/migration.sql`

## Project Structure

```text
src/
  auth/
  common/
    decorators/
    filters/
    guards/
    interfaces/
    logger/
  modules/
    users/
    roles/
    permissions/
    audit-logs/
  prisma/
prisma/
  schema.prisma
  migrations/
```

## Environment

Copy `.env.example` to `.env` (already included by default):

```env
NODE_ENV=development
PORT=3000
DATABASE_URL="mysql://school_user:school_password@localhost:3306/school_erp"
JWT_SECRET="change_me_with_very_strong_secret"
JWT_EXPIRES_IN="1d"
SWAGGER_PATH="api/docs"
```

## Run Locally

1. Start MySQL:

```bash
docker compose up -d
```

2. Install dependencies:

```bash
npm install
```

3. Generate Prisma client:

```bash
npm run prisma:generate
```

4. Apply migrations:

```bash
npm run prisma:migrate:deploy
```

5. Seed super admin and base permissions (optional but recommended):

```bash
npm run prisma:seed
```

6. Start backend:

```bash
npm run start:dev
```

## API Docs

- Swagger UI: `http://localhost:3000/api/docs`
- Health check: `GET /health`

## Auth + RBAC

- Login endpoint: `POST /auth/login`
- Protected endpoints use:
  - `JwtAuthGuard`
  - `PermissionsGuard`
  - `@RequirePermissions(...)`

### Example Permission Codes Used

- `users.create`, `users.read`, `users.update`, `users.delete`
- `roles.create`, `roles.read`, `roles.update`, `roles.delete`, `roles.assign-permissions`
- `permissions.create`, `permissions.read`, `permissions.update`, `permissions.delete`
- `audit-logs.create`, `audit-logs.read`, `audit-logs.delete`

## Core API Groups

- `POST /auth/login`
- `CRUD /users`
- `CRUD /roles`
- `PUT /roles/:id/permissions`
- `CRUD /permissions`
- `GET/POST/DELETE /audit-logs`

## Notes

- System 01 scope is intentionally isolated.
- No implementation from Systems 02-05 is included in this backend stage.
