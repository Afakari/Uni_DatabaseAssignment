CREATE TABLE Cities (
    code CHAR(6) PRIMARY KEY,
    city_name VARCHAR(100) 
);




CREATE TABLE Services (
    id INT PRIMARY KEY,
    service_name VARCHAR(100),
    category VARCHAR(50),
    price DECIMAL(10, 2)
);

create table Plans (
	account_type VARCHAR(50) PRIMARY KEY,
	discount DECIMAL(10, 2)
);




CREATE TABLE Users (
    id INT PRIMARY KEY,
    user_name varchar(100) not null,
    account_type VARCHAR(50),
    start_date DATE,
    end_date DATE,
    city_code CHAR(6), 
    FOREIGN KEY (city_code) REFERENCES Cities(code),
    FOREIGN KEY (account_type) REFERENCES plans(account_type)
);







 create table dwr_date as
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


