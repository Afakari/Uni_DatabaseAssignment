INSERT INTO public.Cities (code, city_name) VALUES
('NYC', 'New York City'),
('LAC', 'Los Angeles'),
('CHI', 'Chicago'),
('SFC', 'San Francisco'),
('HOU', 'Houston');


INSERT INTO public.Plans (account_type, discount) VALUES
('Normal', 0.00),
('Premium', 5.00),
('Platinum', 15.00);


INSERT INTO public.Users (id, user_name ,account_type, start_date, end_date, city_code) VALUES
(1, 'Amir','Normal', '2024-01-01', '2025-01-01', 'NYC'),
(2, 'Keynoosh','Premium', '2024-06-01', '2025-06-01', 'LAC'),
(3, 'Test','Platinum', '2024-03-15', '2025-03-15', 'CHI'),
(4, 'Dummy','Normal', '2024-02-10', '2025-02-10', 'SFC'),
(5, 'QualityCheck','Premium', '2024-07-20', '2025-07-20', 'HOU'),
(6, 'Kitten','Normal', '2024-05-01', '2025-05-01', 'NYC'),
(7, 'Moka','Premium', '2024-08-01', '2025-08-01', 'LAC'),
(8, 'Timo','Platinum', '2024-04-25', '2025-04-25', 'CHI'),
(9, 'Emi','Normal', '2024-01-15', '2025-01-15', 'SFC'),
(10, 'Jingles','Premium', '2024-09-01', '2025-09-01', 'HOU');


INSERT INTO public.Services (id, service_name, category, price) VALUES
(1, 'Internet', 'Communication', 50.00),
(2, 'Mobile', 'Telecom', 30.00),
(3, 'Cable', 'Entertainment', 70.00);





INSERT INTO public.Transactions (transaction_id, user_id, service_id, transaction_datetime, usage_amount, currency) VALUES
(1, 1, 1, '2024-01-05 10:15:00', 50.00, 'RIALS');


DO $$ 
DECLARE 
    v_user_id INT;
    v_service_id INT;
    v_transaction_datetime TIMESTAMP;
    v_usage_amount NUMERIC(10, 2);
    v_currency VARCHAR(10);
BEGIN
    FOR i IN 1..1000000 LOOP
       -- Select random users and services 
        v_user_id := (SELECT id FROM public.Users ORDER BY RANDOM() LIMIT 1);
        v_service_id := (SELECT id FROM public.Services ORDER BY RANDOM() LIMIT 1);
        
        -- Generate a random time in 2024
        v_transaction_datetime := TIMESTAMP '2024-01-01 00:00:00' + INTERVAL '1' DAY * (FLOOR(RANDOM() * 365))   + INTERVAL '1 second' * (FLOOR(RANDOM() * 86400));;
        
        -- Random usage amount
        v_usage_amount := ROUND((RANDOM() * (500.00 - 10.00) + 10.00)::numeric, 2);
        
        -- Random currency 'RIALS' and 'USD'
        v_currency := CASE WHEN RANDOM() < 0.5 THEN 'RIALS' ELSE 'USD' END;
        
        -- Insert the dummy data
        INSERT INTO public.Transactions (transaction_id, user_id, service_id, transaction_datetime, usage_amount, currency)
        VALUES (i, v_user_id, v_service_id, v_transaction_datetime, v_usage_amount, v_currency);
    END LOOP;
END $$;
