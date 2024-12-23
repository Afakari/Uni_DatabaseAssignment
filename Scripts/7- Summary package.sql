-- To run the summary package, we can call:
-- select Summary.start('2024-01-01','2025-01-01')
-- this package my design is a very heavy package
-- considering no acutal engine hints( such as parallelism)


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

CREATE OR REPLACE PROCEDURE Summary.Process_Summary(v_job_id INT,
    p_start_date DATE,
    p_end_date DATE
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_records_processed INT := 0;
BEGIN
	ALTER TABLE public.Detailed_Analytics DISABLE TRIGGER ALL;
	ALTER TABLE public.Summary_Analytics DISABLE TRIGGER ALL;

    DELETE FROM public.Summary_Analytics
    WHERE TO_DATE(day_key, 'YYYYMMDD') BETWEEN p_start_date AND p_end_date;

	ALTER TABLE public.Summary_Analytics ENABLE TRIGGER ALL;
	ALTER TABLE public.Detailed_Analytics ENABLE TRIGGER ALL;

    WITH summary_data AS (
        SELECT 
            SUM(d.amount) AS total_spent,
            COUNT(d.transaction_id) AS total_transactions,
            ROUND(SUM(d.amount) / COUNT(d.transaction_id)) AS avg_transaction_value,
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
        GROUP BY d.transaction_date, s.category, u.account_type, s.service_name, u.city_code, d.mo_key
    )
    INSERT INTO public.Summary_Analytics (total_spent, total_transactions, avg_transaction_value, account_type, service_name, service_category, city_code, day_key, mo_key)
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

    GET DIAGNOSTICS v_records_processed = ROW_COUNT;

WITH summary_report AS (
    SELECT report_id, account_type, service_name, city_code, day_key
    FROM public.Summary_Analytics
    WHERE TO_DATE(day_key, 'YYYYMMDD') BETWEEN p_start_date AND p_end_date)
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


