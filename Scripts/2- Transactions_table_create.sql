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



