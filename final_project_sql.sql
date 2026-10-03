CREATE DATABASE Customers_transactions;
UPDATE customers SET Gender = NULL WHERE Gender ='';
UPDATE customers SET Age = NULL WHERE Age ='';
ALTER TABLE customers MODIFY Age INT NULL;

SELECT * FROM customers;

CREATE TABLE transactions 
(date_new DATE,
id_check INT,
ID_client INT,
Count_products DECIMAL(10,3),
Sum_payment DECIMAL(10,2));

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/transactions_final.csv'
INTO TABLE transactions
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

SHOW VARIABLES LIKE 'secure_file_priv';

SELECT * FROM transactions;

# Задание 1

# Клиенты без пропусков по месяцам

SELECT ID_client
FROM transactions
WHERE date_new >= '2015-06-01'
  AND date_new < '2016-06-01'
GROUP BY ID_client
HAVING COUNT(DISTINCT DATE_FORMAT(date_new, '%Y-%m')) = 12;

# Рассчет показателей данных клиентов

WITH regular_clients AS (
    SELECT ID_client
    FROM transactions
    WHERE date_new >= '2015-06-01'
      AND date_new < '2016-06-01'
    GROUP BY ID_client
    HAVING COUNT(DISTINCT DATE_FORMAT(date_new, '%Y-%m')) = 12
),

checks AS (
    SELECT
        ID_client,
        id_check,
        SUM(Sum_payment) AS check_sum
    FROM transactions
    WHERE date_new >= '2015-06-01'
      AND date_new < '2016-06-01'
      AND ID_client IN (SELECT ID_client FROM regular_clients)
    GROUP BY ID_client, id_check
)

SELECT
    ID_client,
    AVG(check_sum) AS avg_check,
    SUM(check_sum) / 12 AS avg_month_sum,
    COUNT(*) AS operations
FROM checks
GROUP BY ID_client;

# Задание 2

# a) Средняя сумма чека в месяц

# Средняя сумма чека по месяцам
   SELECT
    DATE_FORMAT(t.date_new, '%Y-%m') AS month,
    t.id_check,
    SUM(t.Sum_payment) AS check_sum
FROM transactions t
JOIN customer c
    ON c.Id_client = t.ID_client
WHERE t.date_new >= '2015-06-01'
  AND t.date_new < '2016-06-01'
GROUP BY
    DATE_FORMAT(t.date_new, '%Y-%m'),
    t.id_check;
    
# Временная таблица
CREATE TEMPORARY TABLE monthly_checks AS
SELECT
    DATE_FORMAT(t.date_new, '%Y-%m') AS month,
    t.ID_client,
    t.id_check,
    SUM(t.Sum_payment) AS check_sum
FROM transactions t
JOIN customers c
    ON c.Id_client = t.ID_client
WHERE t.date_new >= '2015-06-01'
  AND t.date_new < '2016-06-01'
GROUP BY
    DATE_FORMAT(t.date_new, '%Y-%m'),
    t.ID_client,
    t.id_check;
    
DROP TEMPORARY TABLE monthly_checks;
    
# Средняя сумма чека в месяц
SELECT
    month,
    AVG(check_sum) AS avg_check
FROM monthly_checks
GROUP BY month
ORDER BY month;
    
# b) Среднее количество операций в месяц

# Среднее количество операций по месяцам
SELECT
    DATE_FORMAT(t.date_new, '%Y-%m') AS month,
    COUNT(DISTINCT t.id_check) AS operations
FROM transactions t
JOIN customers c
    ON c.Id_client = t.ID_client
WHERE t.date_new >= '2015-06-01'
  AND t.date_new < '2016-06-01'
GROUP BY DATE_FORMAT(t.date_new, '%Y-%m')
ORDER BY month;

# Среднее количество операций в месяц
SELECT
    COUNT(DISTINCT id_check) / 12 AS avg_operations_per_month
FROM transactions
WHERE date_new >= '2015-06-01'
  AND date_new < '2016-06-01';

# c) Среднее количество клиентов, которые совершали операции

# Количество клиентов по месяцам
SELECT
    DATE_FORMAT(t.date_new, '%Y-%m') AS month,
    COUNT(DISTINCT t.ID_client) AS clients
FROM transactions t
JOIN customers c
    ON c.Id_client = t.ID_client
WHERE t.date_new >= '2015-06-01'
  AND t.date_new < '2016-06-01'
  AND t.Sum_payment IS NOT NULL
GROUP BY DATE_FORMAT(t.date_new, '%Y-%m')
ORDER BY month;

# Среднее количество клиентов в месяц, которые совершили операции
SELECT
    COUNT(DISTINCT t.ID_client) / 12 AS avg_clients_per_month
FROM transactions t
JOIN customers c
    ON c.Id_client = t.ID_client
WHERE t.date_new >= '2015-06-01'
  AND t.date_new < '2016-06-01'
  AND t.Sum_payment IS NOT NULL;

# d) Выведи долю от общего количества операций за год и долю в месяц от общей суммы операций

# Доля каждого месяца
SELECT
    DATE_FORMAT(t.date_new, '%Y-%m') AS month,
    SUM(t.Sum_payment) AS month_amount
FROM transactions t
JOIN customers c
    ON c.Id_client = t.ID_client
WHERE t.date_new >= '2015-06-01'
  AND t.date_new < '2016-06-01'
  AND t.Sum_payment IS NOT NULL
GROUP BY DATE_FORMAT(t.date_new, '%Y-%m')
ORDER BY month;

# Доля от общего количества операций за год
SELECT
    COUNT(DISTINCT id_check) AS total_operations
FROM transactions
WHERE date_new >= '2015-06-01'
  AND date_new < '2016-06-01'
  AND Sum_payment IS NOT NULL;

# e) Вывести % соотношение M/F/NA в каждом месяце с их долей затрат;

# Временная таблица с данными по месяцам
CREATE TEMPORARY TABLE monthly_gender AS
SELECT
    DATE_FORMAT(t.date_new, '%Y-%m') AS month,
    COUNT(DISTINCT CASE WHEN c.Gender = 'M' THEN t.ID_client END) AS male_clients,
    COUNT(DISTINCT CASE WHEN c.Gender = 'F' THEN t.ID_client END) AS female_clients,
    COUNT(DISTINCT CASE
        WHEN c.Gender IS NULL OR c.Gender = 'NA'
        THEN t.ID_client
    END) AS NA_clients,
    SUM(CASE WHEN c.Gender = 'M' THEN t.Sum_payment ELSE 0 END) AS male_amount,
    SUM(CASE WHEN c.Gender = 'F' THEN t.Sum_payment ELSE 0 END) AS female_amount,
    SUM(CASE
        WHEN c.Gender IS NULL OR c.Gender = 'NA'
        THEN t.Sum_payment
        ELSE 0
    END) AS NA_amount,
    COUNT(DISTINCT t.ID_client) AS total_clients,
    SUM(t.Sum_payment) AS total_amount
FROM transactions t
JOIN customers c
    ON c.Id_client = t.ID_client
WHERE t.date_new >= '2015-06-01'
  AND t.date_new < '2016-06-01'
  AND t.Sum_payment IS NOT NULL
GROUP BY DATE_FORMAT(t.date_new, '%Y-%m');

# Рассчет процентов
SELECT
    month,
    male_clients / total_clients * 100 AS male_percent,
    female_clients / total_clients * 100 AS female_percent,
    NA_clients / total_clients * 100 AS NA_percent,

    male_amount / total_amount * 100 AS male_cost_share,
    female_amount / total_amount * 100 AS female_cost_share,
    NA_amount / total_amount * 100 AS NA_cost_share
FROM monthly_gender
ORDER BY month;

# Задание 3

# Разбивка клиентов на возрастные группы и вывод суммы и количества операций за весь период
SELECT
    CASE
        WHEN c.Age IS NULL THEN 'NA'
        WHEN c.Age < 20 THEN 'до 20'
        WHEN c.Age < 30 THEN '20-29'
        WHEN c.Age < 40 THEN '30-39'
        WHEN c.Age < 50 THEN '40-49'
        WHEN c.Age < 60 THEN '50-59'
        WHEN c.Age < 70 THEN '60-69'
        WHEN c.Age < 80 THEN '70-79'
        ELSE '80+'
    END AS age_group,

    SUM(t.Sum_payment) AS total_amount,

    COUNT(DISTINCT t.id_check) AS total_operations

FROM transactions t
JOIN customers c
    ON c.Id_client = t.ID_client

WHERE t.date_new >= '2015-06-01'
  AND t.date_new < '2016-06-01'
  AND t.Sum_payment IS NOT NULL

GROUP BY age_group
ORDER BY age_group;

# Средние показатели поквартально
SELECT
    CONCAT(YEAR(t.date_new), '-Q', QUARTER(t.date_new)) AS quarter,

    CASE
        WHEN c.Age IS NULL THEN 'NA'
        WHEN c.Age < 20 THEN 'до 20'
        WHEN c.Age < 30 THEN '20-29'
        WHEN c.Age < 40 THEN '30-39'
        WHEN c.Age < 50 THEN '40-49'
        WHEN c.Age < 60 THEN '50-59'
        WHEN c.Age < 70 THEN '60-69'
        WHEN c.Age < 80 THEN '70-79'
        ELSE '80+'
    END AS age_group,

    AVG(t.Sum_payment) AS avg_amount,
    COUNT(DISTINCT t.id_check) AS operations,
    COUNT(DISTINCT t.ID_client) AS clients

FROM transactions t
JOIN customers c
    ON c.Id_client = t.ID_client

WHERE t.date_new >= '2015-06-01'
  AND t.date_new < '2016-06-01'
  AND t.Sum_payment IS NOT NULL

GROUP BY CONCAT(YEAR(t.date_new), '-Q', QUARTER(t.date_new)), age_group
ORDER BY quarter, age_group;