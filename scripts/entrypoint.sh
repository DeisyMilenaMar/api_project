#!/bin/bash
set -e

DJANGO_SETTINGS_MODULE=app.config.settings.local

# Esperar a que la base de datos esté lista
until PGPASSWORD=$POSTGRES_PASSWORD psql -h "$POSTGRES_HOST" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c '\q'; do
  >&2 echo "Postgres is unavailable - sleeping"
  sleep 1
done

>&2 echo "Postgres is up - executing command"

# Ejecutar migraciones
python manage.py migrate

# Recoger archivos estáticos
python manage.py collectstatic --noinput

# Ejecutar el comando pasado al entrypoint
exec "$@"