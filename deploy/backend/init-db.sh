#!/bin/sh
# Идемпотентно создаёт роли и базы для User и Chat.
# Пароли берутся из env и не хардкодятся в SQL.
set -eu

: "${PGHOST:=postgres}"
: "${PGPORT:=5432}"
: "${PGUSER:=postgres}"
: "${USER_DB_PASSWORD:?USER_DB_PASSWORD is required}"
: "${CHAT_DB_PASSWORD:?CHAT_DB_PASSWORD is required}"

export PGHOST PGPORT PGUSER

psql -v ON_ERROR_STOP=1 -d postgres \
  -v user_password="$USER_DB_PASSWORD" \
  -v chat_password="$CHAT_DB_PASSWORD" <<'SQL'
SELECT format('CREATE ROLE user_service LOGIN PASSWORD %L', :'user_password')
WHERE NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'user_service')\gexec

SELECT format('ALTER ROLE user_service WITH LOGIN PASSWORD %L', :'user_password')\gexec

SELECT format('CREATE ROLE chat_service LOGIN PASSWORD %L', :'chat_password')
WHERE NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'chat_service')\gexec

SELECT format('ALTER ROLE chat_service WITH LOGIN PASSWORD %L', :'chat_password')\gexec

SELECT 'CREATE DATABASE messenger_users OWNER user_service'
WHERE NOT EXISTS (SELECT 1 FROM pg_database WHERE datname = 'messenger_users')\gexec

SELECT 'CREATE DATABASE messenger_chat OWNER chat_service'
WHERE NOT EXISTS (SELECT 1 FROM pg_database WHERE datname = 'messenger_chat')\gexec
SQL

echo "Database roles and databases are ready."
