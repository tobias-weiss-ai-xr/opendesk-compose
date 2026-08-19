#!/bin/bash
set -e

# openDesk Docker Compose — Database Initialization
# Creates databases and users for all services.
# Runs as /docker-entrypoint-initdb.d/10-init-db.sh
#
# 7 databases across a single PostgreSQL:
#   casdoor_db       (Casdoor — OIDC/OAuth2 SSO)
#   synapse_db       (Synapse — Matrix chat, behind --profile chat)
#   opencloud_db     (OpenCloud — file management, behind --profile office)
#   notes_db         (Notes/Impress — collaborative editing, behind --profile notes)
#   sogo_db          (SOGo — webmail metadata)
#   paperless_db     (Paperless-ngx — document management)
#   invoiceninja_db  (Invoice Ninja — invoicing)

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname postgres <<-EOSQL
    -- ── Users first (before DBs, so they can OWN them) ──
    CREATE USER casdoor_user     WITH PASSWORD '${CASDOOR_DB_PASSWORD:-changeme}';
    CREATE USER synapse_user     WITH PASSWORD '${SYNAPSE_DB_PASSWORD:-changeme}';
    CREATE USER opencloud_user   WITH PASSWORD '${OPENCLOUD_DB_PASSWORD:-changeme}';
    CREATE USER notes_user       WITH PASSWORD '${NOTES_DB_PASSWORD:-changeme}';
    CREATE USER sogo_user        WITH PASSWORD '${SOGO_DB_PASSWORD:-changeme}';
    CREATE USER paperless_user   WITH PASSWORD '${PAPERLESS_DB_PASSWORD:-changeme}';
    CREATE USER invoiceninja_user WITH PASSWORD '${INVOICENINJA_DB_PASSWORD:-changeme}';

    -- ── Databases ──
    CREATE DATABASE casdoor_db      OWNER casdoor_user     ENCODING 'UTF8' LC_COLLATE='C';
    CREATE DATABASE synapse_db      OWNER synapse_user     ENCODING 'UTF8' LC_COLLATE='C';
    CREATE DATABASE opencloud_db    OWNER opencloud_user   ENCODING 'UTF8';
    CREATE DATABASE notes_db        OWNER notes_user       ENCODING 'UTF8';
    CREATE DATABASE sogo_db         OWNER sogo_user        ENCODING 'UTF8';
    CREATE DATABASE paperless_db    OWNER paperless_user   ENCODING 'UTF8';
    CREATE DATABASE invoiceninja_db OWNER invoiceninja_user ENCODING 'UTF8';

    -- ── Privileges ──
    GRANT ALL PRIVILEGES ON DATABASE casdoor_db      TO casdoor_user;
    GRANT ALL PRIVILEGES ON DATABASE synapse_db      TO synapse_user;
    GRANT ALL PRIVILEGES ON DATABASE opencloud_db    TO opencloud_user;
    GRANT ALL PRIVILEGES ON DATABASE notes_db        TO notes_user;
    GRANT ALL PRIVILEGES ON DATABASE sogo_db         TO sogo_user;
    GRANT ALL PRIVILEGES ON DATABASE paperless_db    TO paperless_user;
    GRANT ALL PRIVILEGES ON DATABASE invoiceninja_db TO invoiceninja_user;
EOSQL

echo "✅ 7 databases initialized successfully"
