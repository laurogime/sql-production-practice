WITH transaction_analysis AS (
    SELECT 
        customer_id,
        COUNT(transaction_id)       AS transaction_volume,
        ROUND(AVG(amount_aud), 2)   AS avg_transaction_amount
    FROM dbo.transactions
    GROUP BY customer_id
)
SELECT
    ta.customer_id,
    ta.transaction_volume,
    ta.avg_transaction_amount,
    c.credit_score,
    c.employment_status
FROM transaction_analysis AS ta
JOIN dbo.customers AS c 
ON ta.customer_id = c.customer_id
WHERE
    -- filtering for customers with at least 5 transactions
    ta.transaction_volume >= 5
    -- filtering for active customers
    AND c.is_active = 1
ORDER BY ta.transaction_volume DESC;


