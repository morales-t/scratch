WITH user_table AS (
    SELECT
        user_id
    FROM user_transactions
    GROUP BY 1
), dates AS (
    SELECT 
        date::date 
    -- This could be smarter to start each user at their first spend date, just going the lazy approach
    FROM generate_series('2023-01-01'::date,  (CURRENT_DATE + interval '30' day), '1 day'::interval) date
), date_possibilites AS (
    SELECT
        User_id,
        date
    FROM dates a
        CROSS JOIN user_table
), date_spend AS (
    SELECT
        a. user_id,
        a. date,
        COALESCE(b. credit_used , 0) AS credit_used 
    FROM date_possibilites a
        LEFT JOIN user_transactions b
            ON a. User_id = b. User_id
            AND a.date = b. transaction_date 
), rolling AS (
    SELECT
        user_id,
        date,
        SUM(credit_used) OVER (PARTITION BY user_id ORDER BY DATE ASC range BETWEEN INTERVAL '30 day' PRECEDING AND CURRENT ROW) AS Past30DayCredit
    FROM date_spend
)
SELECT
	User_id,
	MIN(date) AS minimumDate
FROM rolling
WHERE date >= CURRENT_DATE
	AND Past30DayCredit < 500
GROUP BY 1
ORDER BY 1
