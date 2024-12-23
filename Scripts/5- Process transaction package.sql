-- We can start the package by first getting into the schema
-- and then running the command below:
-- select Transaction_Processing.start()


-- Package init, job handler

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
    EXECUTE 'TRUNCATE TABLE Transactions RESTART IDENTITY';

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

