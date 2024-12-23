tabase Assignment: Star Schema Design

Welcome to our Database Assignment repository! This project is a collaborative effort between Afakari and keynooshh  for our database course. Our goal is to implement a simple star schema design that supports efficient analytical queries and data processing in PostgresSQL database.



## Repository Structure

This repository is organized into several directories to keep resources modular and easy to navigate:

-   **Container/**: Resources for setting up and maintaining the database environment.
-   **Diagrams/**: Visual representations of the schema and business concepts.
-   **Scripts/**: SQL scripts for creating and processing the database.

Each directory will have its own README file providing more details about its contents.

## How to Use the Repository

### Setting Up

1.  Clone the repository:
    
    ```bash
    git clone git@github.com:Afakari/Uni_DatabaseAssignment.git
    
    ```
    
2.  Navigate to the `Container` directory.
    
3.  Use Docker Compose to set up the database environment. This will recreate the whole schema using the setup scripts in the directory. No need to do anything further:
    
    ```bash
    docker-compose up
    
    ```
    
4.  Once the setup is complete, a pgAdmin4 instance will also be running. You can access it using the following credentials:
    -   **URL**: http://localhost:8080
    -   **Username**: admin@test.com
    -   **Password**: admin
5.  Credentials for the PostgreSQL database:
    
    -   **Hostname**: postgresdb
    -   **Username**: admin
    -   **Password**: admin

### Running the SQL Scripts

-   Scripts are numbered to guide execution order. Start with `1- Dimensions.sql` and proceed sequentially.
-   Use a SQL client or a database management tool to execute each script in order.



## Project Overview

The primary objective of this project is to implement a simple  star schema design to support analytical queries for educational purposes. The schema consists of:

-   **Fact Table**: Contains transactional data.
-   **Dimension Tables**: Provide descriptive attributes for analytical purposes.
-   **Summary Tables**: Optimize the performance of pre-aggregated data for reporting.

Key Features:

-   Efficient handling of transaction data.
-   Scalable star schema design.
-   Automation scripts for data processing and summary table generation.



## Contributing

Feel free to contribute by:

-   Reporting issues
-   Suggesting improvements
-   Submitting pull requests
