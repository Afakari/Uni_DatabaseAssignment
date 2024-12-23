cripts Directory

This directory contains SQL scripts for building and managing the database, processing data, and performing analytics. The scripts are structured sequentially to guide the user through the logical flow of the database setup and operation.


## Contents

### 1. **`Dimensions.sql`**
- Creates dimension tables used in the star schema.
- Dimensions provide descriptive attributes and serve as lookup tables for the fact tables.

### 2. **`Transactions_table_create.sql`**
- Sets up the **Transactions Table** and the **Error Table**.
- These tables handle incoming raw transaction data and errors encountered during processing.

### 3. **`Analytics table create.sql`**
- Defines the **analytics tables**, which form the heart of the star schema.
  - **Detailed Analytics Table**: Contains detailed transactional analytics data.
  - **Summary  Analytics Table**: aggregated and processed data used for dashboards and summary reporting.

### 4. **`Process_transactions_tables.sql`** and **` Process_transaction_package.sql`**
- Together, these scripts form the **Transaction Processing Package**:
  - **`tables.sql`**: Creates control and log tables for managing transaction processing jobs.
  - **`package.sql`**: Implements procedures to process raw transactions:
    - Valid transactions are moved to the **Detailed Transactions Table**.
    - Invalid transactions are logged in the **Error Transactions Table**, along with a description and the processing time.

### 6. **`Summary_tables.sql`** and **`Summary_package.sql`**
- Together, these scripts form the **Summary Analytics Package**:
  - **` tables.sql`**: Creates tables for job controls and logs for summary generation.
  - **`package.sql`**: Implements procedures for aggregating data from the **Detailed Analytics Table** into summary tables.

### 8. **`Dummy_data_feed.sql`**
- Populates the database with dummy data for testing purposes.
- Uses PL/pgSQL scripts to generate raw transaction data.

### 9. **`Sample_analytics.sql`**
- Contains example scripts for aggregating data and generating insights from the **Analytics Summary Table**.


## Usage
1. Execute the scripts in order to set up the database schema and workflows.
2. Use the **Transaction Processing Package** (scripts 4 and 5) to process raw transactions and log errors.
3. Use the **Summary Analytics Package** (scripts 6 and 7) to populate and manage aggregated analytics data.
4. Use the **Dummy Data Feed** (script 8) for testing workflows.
5. Explore **Sample Analytics** (script 9) for generating meaningful insights.



## Notes
- Scripts are organized in a sequence that builds upon the previous steps.
- Modify the dummy data scripts (8) as needed to simulate different transaction scenarios.
- Update summary aggregation logic in scripts 7 and 9 to align with specific dashboard requirements.

For additional context, refer to the main [README.md](../README.md).

