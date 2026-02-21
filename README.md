# School System (NestJS + React + MySQL)

Monorepo for a school MVP:
- `apps/api`: NestJS API
- `apps/web`: React web app
- `apps/mobile`: mobile starter (Expo-ready skeleton)

## Included MVP modules
- Students
- Classes
- Attendance
- Grades

## Local setup
1. Start MySQL:
   - `docker compose up -d`
2. Install packages:
   - `npm install`
3. Configure API env:
   - Copy `apps/api/.env.example` to `apps/api/.env`
4. Run Prisma migration:
   - `npm run prisma:migrate -w apps/api`
5. Start API:
   - `npm run dev:api`
6. Start web app:
   - `npm run dev:web`

## Notes
- Existing Arabic SQL/analysis folders are preserved.
- This implementation is a clean MVP foundation using your selected stack.
