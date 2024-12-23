-- Because of the fact that we can NOT have packages in pgpl/sql, We created a schema
-- that contains all the tables , procedures, making it look structured, like a package 

CREATE SCHEMA Transaction_Processing;

CREATE TABLE Transaction_Processing.Job_Control (
    job_id SERIAL PRIMARY KEY,
    job_name VARCHAR(100),
    start_time TIMESTAMP,
    end_time TIMESTAMP,
    status VARCHAR(50), -- ENUM: 'Running', 'Completed', 'Failed'
    records_processed INT,
    errors_logged INT
);


CREATE TABLE Transaction_Processing.Job_Logs (
    log_id SERIAL PRIMARY KEY,
    job_id INT REFERENCES Transaction_Processing.Job_Control(job_id),
    log_timestamp TIMESTAMP DEFAULT NOW(),
    message TEXT
);

