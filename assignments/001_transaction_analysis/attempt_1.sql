WITH transaction_volume AS (
    SELECT 
        customer_id,
        COUNT(*) AS transaction_volume
    FROM dbo.transactions
    GROUP BY customer_id
), 
average_transaction AS (
    SELECT 
        customer_id,
        AVG(amount_aud) AS avg_transaction_amount
    FROM dbo.transactions
    GROUP BY customer_id
)
SELECT
    c.customer_id,
    tv.transaction_volume,
    at.avg_transaction_amount,
    c.credit_score,
    c.employment_status
FROM transaction_volume AS tv
JOIN average_transaction AS at 
ON tv.customer_id = at.customer_id
JOIN dbo.customers AS c 
ON tv.customer_id = c.customer_id
WHERE 
    tv.transaction_volume >= 5
    AND c.is_active = 1
ORDER BY tv.transaction_volume DESC;


