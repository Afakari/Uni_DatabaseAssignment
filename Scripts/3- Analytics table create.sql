
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


select * from Detailed_Analytics

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
    FOREIGN KEY (report_id, mo_key) REFERENCES Summary_Analytics(report_id, mo_key),
    FOREIGN KEY (user_id) REFERENCES Users(id),
    FOREIGN KEY (service_id) REFERENCES Services(id)
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
