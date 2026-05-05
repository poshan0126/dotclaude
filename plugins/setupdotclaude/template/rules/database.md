---
paths:
  - "**/migrations/**"
  - "**/migrate/**"
  - "**/db/migrate/**"
  - "**/alembic/**"
  - "**/alembic/versions/**"
  - "**/prisma/migrations/**"
  - "**/drizzle/**"
  - "**/knex/migrations/**"
  - "**/sequelize/migrations/**"
  - "**/typeorm/migrations/**"
  - "**/flyway/**"
  - "**/liquibase/**"
---

# Database Migrations

- **Never modify an existing migration.** Always create a new migration for changes. Existing migrations may have already run in production.
- Every migration must be reversible. Implement both up/forward and down/rollback.
- Test migrations in both directions before committing.
- Migration filenames are ordered by timestamp prefix. New migrations go at the end.
- Never use raw SQL when the ORM or migration tool provides a method for the operation.
- Never seed production data in migration files. Use dedicated seed files.
- Never drop columns or tables without first confirming the data is no longer needed.
- Add indexes in their own migration, not bundled with schema changes. Easier to roll back independently.
