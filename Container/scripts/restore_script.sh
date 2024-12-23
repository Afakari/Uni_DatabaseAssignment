#!/bin/bash

# Automating the restoring process
# This script is meant to be run after the PostgreSQL database is up
# The paths for the schema and data SQL files are mounted in the docker-compose file
# This version restores schema and data using SQL files

BACKUP_DIR="/tmp/backups"
SCHEMA_SQL="${BACKUP_DIR}/schema.sql"
DATA_SQL="${BACKUP_DIR}/data.sql"

# Wait for PostgreSQL to become ready
until pg_isready -U "$POSTGRES_USER" -d "$POSTGRES_DB"; do
  echo "Waiting for PostgreSQL to start..."
  sleep 2
done

# Restore the schema SQL file
if [ -f "$SCHEMA_SQL" ]; then
  echo "Restoring schema from $SCHEMA_SQL..."
  psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -f "$SCHEMA_SQL"
  rm -rf $SCHEMA_SQL
else
  echo "Schema file $SCHEMA_SQL not found. Skipping schema restoration."
fi

# Restore the data SQL file
if [ -f "$DATA_SQL" ]; then
  echo "Restoring data from $DATA_SQL..."
  psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -f "$DATA_SQL"
  rm -rf $DATA_SQL
else
  echo "Data file $DATA_SQL not found. Skipping data restoration."
fi

echo "Restoration process complete!"
