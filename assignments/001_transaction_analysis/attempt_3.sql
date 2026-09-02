
SELECT 
    t.customer_id,
    COALESCE(COUNT(t.transaction_id), 0)                  AS transaction_volume,
    CAST(ROUND(AVG(t.amount_aud), 2) AS DECIMAL(10, 2))   AS avg_transaction_amount,
    c.credit_score,
    c.employment_status
FROM dbo.transactions                                      AS t
LEFT JOIN dbo.customers                                    AS c
ON t.customer_id = c.customer_id
-- filtering for active customers
WHERE c.is_active = 1
GROUP BY 
    t.customer_id, 
    c.credit_score, 
    c.employment_status
-- filtering for customers with at least 5 transactions
HAVING COALESCE(COUNT(t.transaction_id), 0) >= 5
ORDER BY transaction_volume DESC;


