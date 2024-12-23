CREATE TABLE public.Cities (
    code CHAR(6) PRIMARY KEY,
    city_name VARCHAR(100) 
);

CREATE TABLE public.Services (
    id INT PRIMARY KEY,
    service_name VARCHAR(100),
    category VARCHAR(50),
    price DECIMAL(10, 2)
);

create table public.Plans (
	account_type VARCHAR(50) PRIMARY KEY,
	discount DECIMAL(10, 2)
);

CREATE TABLE public.Users (
    id INT PRIMARY KEY,
    user_name varchar(100) not null,
    account_type VARCHAR(50),
    start_date DATE,
    end_date DATE,
    city_code CHAR(6), 
    FOREIGN KEY (city_code) REFERENCES public.Cities(code),
    FOREIGN KEY (account_type) REFERENCES public.plans(account_type)
);

 create table public.dwr_date as
SELECT 
    row_number() OVER () AS date_key,
    TO_CHAR(mydate, 'YYYYMMDD') AS calendar_date,  
    EXTRACT(YEAR FROM mydate)::TEXT || 'w' ||LPAD(EXTRACT(WEEK FROM mydate)::TEXT, 2, '0') AS week_num, 
    LPAD(EXTRACT(MONTH FROM mydate)::TEXT, 2, '0') AS month_num,
    TO_CHAR(mydate, 'Mon') AS month_name,  
    'Q' || EXTRACT(QUARTER FROM mydate) AS quarter_num, 
    EXTRACT(YEAR FROM mydate) AS calendar_year, 
    EXTRACT(DOW FROM mydate) AS iso_dayofweek, 
    TRIM(TO_CHAR(mydate, 'Day')) AS dayofweek_name  
FROM (
    SELECT generate_series(DATE '2024-01-01', DATE '2025-12-31', INTERVAL '1 day') AS mydate -- crate date data for 2 years
) ;


CREATE TABLE public.Transactions (
    transaction_id INT NOT NULL,
    user_id INT NOT NULL,
    service_id INT NOT NULL,
    transaction_datetime TIMESTAMP NOT NULL,
    usage_amount DECIMAL(10, 2) DEFAULT 0.00,
    currency VARCHAR(10) DEFAULT 'RIALS',
    PRIMARY KEY (transaction_id, transaction_datetime)
) PARTITION BY RANGE (transaction_datetime);

create index idx_transactions_id on Transactions (transaction_id);





DO $$ 
DECLARE
    year_month TEXT;
BEGIN
    FOR year_month IN 
        SELECT to_char(d, 'YYYYMM') 
        FROM generate_series('2024-01-01'::date, '2025-12-01'::date, interval '1 month') AS d
    LOOP
        EXECUTE format('
            CREATE TABLE public.Transactions_%s PARTITION OF public.Transactions 
            FOR VALUES FROM (''%s-01 00:00:00'') TO (''%s-01 00:00:00'');
        ', 
        year_month, 
        left(year_month, 4) || '-' || right(year_month, 2), 
        to_char(to_date(year_month || '01', 'YYYYMMDD') + INTERVAL '1 month', 'YYYY-MM'));
    END LOOP;
END $$;



CREATE TABLE public.Error_Transactions (
    error_id SERIAL PRIMARY KEY,
    transaction_id INT,
    error_date TIMESTAMP DEFAULT NOW(),
    error_description TEXT,
    user_id INT,
    service_id INT,
    transaction_datetime TIMESTAMP,
    amount DECIMAL(10, 2),
    currency VARCHAR(10)
);



CREATE TABLE public.Summary_Analytics (
    report_id SERIAL,
    total_spent DECIMAL(15, 2),
    total_transactions INT,
    avg_transaction_value DECIMAL(10, 2),
    account_type VARCHAR(50),
    service_name VARCHAR(100),
    service_category VARCHAR(50),
    city_code CHAR(6), 
    day_key CHAR(8) NOT NULL,
    mo_key INT NOT NULL,
    PRIMARY KEY (report_id, mo_key) 
) PARTITION BY RANGE (mo_key);

-- Both indexes created for more efficient joins
-- day_key for join with dwr_date
-- report_id for joins with detailed_analytics

CREATE INDEX idx_summary_report_id ON public.Summary_Analytics (report_id);
CREATE INDEX idx_summary_day_key ON public.Summary_Analytics (day_key);

-- A simple pgpl/sql script to gerenate partitions

DO $$ 
DECLARE
    year_month INT;
BEGIN
    FOR year_month IN 
        SELECT to_char(d, 'YYYYMM')::INT 
        FROM generate_series('2024-01-01'::date, '2025-12-01'::date, interval '1 month') AS d
    LOOP
        EXECUTE format('
            CREATE TABLE public.Summary_Analytics_%s PARTITION OF public.Summary_Analytics 
            FOR VALUES FROM (%s) TO (%s);
        ', 
        year_month, 
        year_month, 
        year_month + 1);
    END LOOP;
END $$;


CREATE TABLE public.Detailed_Analytics (
    transaction_id SERIAL,
    report_id SERIAL NOT NULL,
    transaction_date DATE NOT NULL,
    transaction_time TIME NOT NULL,
    user_id INT,
    service_id INT,
    amount DECIMAL(10, 2),
    currency VARCHAR(10),
    mo_key INT NOT NULL,
    PRIMARY KEY (transaction_id, mo_key) ,
    FOREIGN KEY (report_id, mo_key) REFERENCES public.Summary_Analytics(report_id, mo_key),
    FOREIGN KEY (user_id) REFERENCES public.Users(id),
    FOREIGN KEY (service_id) REFERENCES public.Services(id)
) PARTITION BY RANGE (mo_key);


CREATE INDEX idx_detailed_analytics_date ON public.Detailed_Analytics (transaction_date);
create index idx_detailed_analytics_report_id on public.Detailed_Analytics (report_id);
create index idx_detailed_analytics_transaction_id on public.Detailed_Analytics (user_id,service_id);


-- A simple pgpl/sql script to gerenate partitions

DO $$ 
DECLARE
    year_month INT;
BEGIN
    FOR year_month IN 
        SELECT to_char(d, 'YYYYMM')::INT 
        FROM generate_series('2024-01-01'::date, '2025-12-01'::date, interval '1 month') AS d
    LOOP
        EXECUTE format('
            CREATE TABLE public.Detailed_Analytics_%s PARTITION OF public.Detailed_Analytics 
            FOR VALUES FROM (%s) TO (%s);
        ', 
        year_month, 
        year_month, 
        year_month + 1);
    END LOOP;
END $$;



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





CREATE OR REPLACE FUNCTION Transaction_Processing.start()
RETURNS VOID
LANGUAGE plpgsql
AS $$ 
DECLARE
    v_job_running BOOLEAN;
    v_job_id INT;
    v_start_time TIMESTAMP := NOW();
BEGIN
    -- Check if the job is already running
    SELECT EXISTS(
        SELECT 1 
        FROM Transaction_Processing.Job_Control 
        WHERE job_name = 'Transaction_Processing' 
        AND status = 'Running'
    ) INTO v_job_running;

    IF v_job_running THEN
        -- If the job is already running, just exit
        RAISE NOTICE 'Job is already running.';
    ELSE
        -- Start a new job if no job is running
        INSERT INTO Transaction_Processing.Job_Control (job_name, start_time, status)
        VALUES ('Transaction_Processing', v_start_time, 'Running')
        RETURNING job_id INTO v_job_id;

        -- Call the transaction processing procedure with the job_id
        CALL Transaction_Processing.Process_Transactions(v_job_id);
    END IF;
END;
$$;
 
-- Main procedure

CREATE OR REPLACE PROCEDURE Transaction_Processing.Process_Transactions(v_job_id INT)
LANGUAGE plpgsql
AS $$
DECLARE
    v_end_time TIMESTAMP;
    v_records_processed INT := 0;
    v_errors_logged INT := 0;
BEGIN
	ALTER TABLE public.Detailed_Analytics DISABLE TRIGGER ALL;

    -- Invalid transactions -> Error_Transactions
    INSERT INTO public.Error_Transactions (transaction_id, error_description, user_id, service_id, transaction_datetime, amount, currency)
    SELECT 
        t.transaction_id,
        CASE 
            WHEN u.id IS NULL THEN 'User ID not found: ' || u.id
            WHEN s.id IS NULL THEN 'Service ID not found: ' ||  s.id 
            WHEN c.code IS NULL THEN 'City Code not found: ' || c.code
        END AS error_description, -- Simple Description of the reasons.
        t.user_id, t.service_id, t.transaction_datetime, t.usage_amount, t.currency
    FROM public.Transactions t 
    LEFT JOIN public.Users u ON t.user_id = u.id
    LEFT JOIN public.Services s ON t.service_id = s.id
    LEFT JOIN public.Cities c ON u.city_code = c.code
    WHERE u.id IS NULL OR s.id IS NULL OR c.code IS NULL; -- Check for inavlid data

    GET DIAGNOSTICS v_errors_logged = ROW_COUNT;

    -- Valid transactions -> Detailed_Analytics
    INSERT INTO public.Detailed_Analytics (transaction_id,  transaction_date, transaction_time, user_id, service_id, amount, currency, mo_key)
    SELECT 
        t.transaction_id,
        transaction_datetime::DATE,
        transaction_datetime::TIME,
        t.user_id,
        t.service_id,
        t.usage_amount * s.price * (100 - p.discount),
        t.currency,
	EXTRACT(YEAR FROM transaction_datetime) * 100 + EXTRACT(MONTH FROM transaction_datetime) AS mo_key
    FROM public.Transactions t
    JOIN public.Users u ON t.user_id = u.id
	join public.plans p on u.account_type  = p.account_type
    JOIN public.Services s ON t.service_id = s.id
    JOIN public.Cities c ON u.city_code = c.code;

    GET DIAGNOSTICS v_records_processed = ROW_COUNT;
	ALTER TABLE public.Detailed_Analytics ENABLE TRIGGER ALL;
    -- End the job, Handle job controls.
    call Transaction_Processing.finalize_job(v_job_id, v_records_processed, v_errors_logged, 'Completed');

    -- Truncate Transactions.
    EXECUTE 'TRUNCATE TABLE public.Transactions RESTART IDENTITY';

EXCEPTION
    WHEN OTHERS THEN
        call Transaction_Processing.finalize_job(v_job_id, v_records_processed, v_errors_logged, 'Failed');
        RAISE;
END;
$$;

-- Simple Job cleanup

CREATE OR REPLACE PROCEDURE Transaction_Processing.finalize_job(
    p_job_id INT,
    p_records_processed INT,
    p_errors_logged INT,
    p_status VARCHAR
)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE Transaction_Processing.Job_Control
    SET end_time = NOW(), 
        status = p_status,
        records_processed = p_records_processed,
        errors_logged = p_errors_logged
    WHERE job_id = p_job_id;

    INSERT INTO Transaction_Processing.Job_Logs (job_id, message)
    VALUES (p_job_id, format('Job %s completed. Processed: %s, Errors: %s', p_status, p_records_processed, p_errors_logged));
    DELETE FROM Transaction_Processing.Job_Logs WHERE log_timestamp < NOW() - INTERVAL '30 days';
    DELETE FROM Transaction_Processing.Job_Control WHERE start_time < NOW() - INTERVAL '30 days';
END;
$$;

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





CREATE OR REPLACE FUNCTION Summary.start(
    p_start_date DATE,
    p_end_date DATE
)
RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
    v_job_running BOOLEAN;
    v_job_id INT;
    v_start_time TIMESTAMP := NOW();
BEGIN
    -- Check for active job
    SELECT EXISTS(
        SELECT 1 
        FROM Summary.Job_Control 
        WHERE job_name = 'Summary_Processing' 
        AND status = 'Running'
    ) INTO v_job_running;

    IF v_job_running THEN
        RAISE NOTICE 'Summary job is already running.';
    ELSE
	    INSERT INTO Summary.Job_Control (job_name, start_time, status)
	    VALUES ('Summary_Processing', v_start_time, 'Running')
	    RETURNING job_id INTO v_job_id;
        CALL Summary.Process_Summary(v_job_id ,p_start_date, p_end_date);
    END IF;
END;
$$;

CREATE OR REPLACE PROCEDURE Summary.Process_Summary(
    v_job_id INT,
    p_start_date DATE,
    p_end_date DATE
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_records_processed INT := 0;
BEGIN
    -- Disable triggers for faster updates
    ALTER TABLE public.Detailed_Analytics DISABLE TRIGGER ALL;
    ALTER TABLE public.Summary_Analytics DISABLE TRIGGER ALL;

    -- Delete data for the specified date range 
    DELETE FROM public.Summary_Analytics
    WHERE TO_DATE(day_key, 'YYYYMMDD') BETWEEN p_start_date AND p_end_date;

    -- Re-enable triggers
    ALTER TABLE public.Summary_Analytics ENABLE TRIGGER ALL;
    ALTER TABLE public.Detailed_Analytics ENABLE TRIGGER ALL;


    WITH summary_data AS (
        SELECT /*+ Parallel */
            SUM(d.amount) AS total_spent,
            COUNT(d.transaction_id) AS total_transactions,
            ROUND(SUM(d.amount) / NULLIF(COUNT(d.transaction_id), 0)) AS avg_transaction_value,
            u.account_type,
            s.service_name,
            s.category AS service_category,
            u.city_code,
            TO_CHAR(d.transaction_date, 'YYYYMMDD') AS day_key,
            d.mo_key
        FROM public.Detailed_Analytics d
        INNER JOIN public.Users u ON d.user_id = u.id
        INNER JOIN public.Services s ON d.service_id = s.id
        WHERE d.transaction_date BETWEEN p_start_date AND p_end_date
        GROUP BY 
            d.mo_key, 
            d.transaction_date, 
            s.category, 
            u.account_type, 
            s.service_name, 
            u.city_code
    )
    INSERT INTO public.Summary_Analytics (
        total_spent, 
        total_transactions, 
        avg_transaction_value, 
        account_type, 
        service_name, 
        service_category, 
        city_code, 
        day_key, 
        mo_key
    )
    SELECT 
        total_spent,
        total_transactions,
        avg_transaction_value,
        account_type,
        service_name,
        service_category,
        city_code,
        day_key,
        mo_key
    FROM summary_data;

    -- Get diagnostics for rows processed
    GET DIAGNOSTICS v_records_processed = ROW_COUNT;

    WITH summary_report AS (
        SELECT report_id, account_type, service_name, city_code, day_key
        FROM public.Summary_Analytics
        WHERE TO_DATE(day_key, 'YYYYMMDD') BETWEEN p_start_date AND p_end_date
    )
    UPDATE public.Detailed_Analytics da
    SET report_id = sr.report_id
    FROM summary_report sr
    WHERE 
        -- Compare day_key directly as a date
        TO_CHAR(da.transaction_date, 'YYYYMMDD') = sr.day_key
        -- Check account type match using a JOIN
        AND da.user_id IN (SELECT id FROM public.Users WHERE account_type = sr.account_type)
        -- Check service match using a JOIN
        AND da.service_id IN (SELECT id FROM public.Services WHERE service_name = sr.service_name);

    -- Log job completion
    CALL Summary.finalize_job(v_job_id, v_records_processed, 'Completed');

EXCEPTION
    WHEN OTHERS THEN
        CALL Summary.finalize_job(v_job_id, v_records_processed, 'Failed');
        RAISE;
END;
$$;


CREATE OR REPLACE PROCEDURE Summary.finalize_job(
    p_job_id INT,
    p_records_processed INT,
    p_status VARCHAR
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Update the job control table
    UPDATE Summary.Job_Control
    SET end_time = NOW(), 
        status = p_status,
        records_processed = p_records_processed
    WHERE job_id = p_job_id;

    -- Log the job completion
    INSERT INTO Summary.Job_Logs (job_id, message)
    VALUES (p_job_id, format('Summary job finalized with status: %s. Records processed: %s.', p_status, p_records_processed));

    -- Housekeeping for old logs (30 days retention)
    DELETE FROM Summary.Job_Logs WHERE log_timestamp < NOW() - INTERVAL '30 days';
    DELETE FROM Summary.Job_Control WHERE start_time < NOW() - INTERVAL '30 days';
END;
$$;