ontainer Setup

This directory contains all the resources needed to set up and manage the database environment using Docker.

---

## Contents
- **backups/**: Includes database backup files.
  - `data.sql`: Contains sample data for the database.
  - `schema.sql`: Defines the schema for the database.
- **docker-compose.yaml**: Configuration file for orchestrating the database and associated services.
- **scripts/**: Contains helper scripts for managing the database.
  - `restore_script.sh`: A helper script integrated into Docker's `init.d` process. It restores the schema and populates the database with data using simple SQL and PGPL/SQL commands.

---

## Setting Up the Environment

1. Ensure you have Docker and Docker Compose installed on your system.
2. From the `Container` directory, start the services with the following command:
   ```bash
   docker-compose up
   ```
   This will:
   - Set up a PostgreSQL database.
   - Automatically recreate the schema and populate the database with data using `restore_script.sh`.
   - Launch a pgAdmin4 instance for managing the database.

---

## Access Information

### pgAdmin4
- **URL**: [http://localhost:8080](http://localhost:8080)
- **Username**: admin@test.com
- **Password**: admin

### PostgreSQL Database
- **Hostname**: postgresdb
- **Username**: admin
- **Password**: admin

---

## Additional Notes
- To stop the services, run:
  ```bash
  docker-compose down
  ```
- To clean up all containers, networks, and volumes, add the `--volumes` flag:
  ```bash
  docker-compose down --volumes
  ```

For further details, refer to the main [README.md](../README.md).


