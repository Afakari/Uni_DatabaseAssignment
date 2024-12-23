CREATE SCHEMA Summary;


CREATE TABLE Summary.Job_Control (
    job_id SERIAL PRIMARY KEY,
    job_name VARCHAR(100),
    start_time TIMESTAMP,
    end_time TIMESTAMP,
    status VARCHAR(20),
    records_processed INT
);


CREATE TABLE Summary.Job_Logs (
    log_id SERIAL PRIMARY KEY,
    job_id INT REFERENCES Summary.Job_Control(job_id),
    log_timestamp TIMESTAMP DEFAULT NOW(),
    message TEXT
);
