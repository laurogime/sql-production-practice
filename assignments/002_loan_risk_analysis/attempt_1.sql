-- Assignment 002: Loan Risk Analysis
-- Grain: one row per product type with both active status on loans and accounts
WITH active_loans AS (
    -- Pre-filter active loans before joining to transactions
    -- Reduces the working dataset early, improving JOIN efficiency
    SELECT
        loan_type,
        outstanding_balance,
        loan_id,
        interest_rate_pct,
        customer_id
    FROM dbo.loans
    WHERE status = 'Active'
),
active_customers AS (
    -- Pre-filter active customers before joining to transactions
    SELECT
        customer_id,
        CAST(
            ROUND(AVG(credit_score), 2)
            AS DECIMAL (10,2) 
        ) AS avg_credit_score
    FROM dbo.customers
    WHERE is_active = 1
    GROUP BY customer_id
),
loan_risk_metrics AS (
    -- calculating the metrics
    SELECT
        al.loan_type                    AS loan_type,
        CAST(
            ROUND(SUM(al.outstanding_balance), 2)
            AS DECIMAL (10, 2)
            )     AS total_outstanding_balance,
        COUNT(al.loan_id)               AS number_of_active_loans,
        CAST(
            ROUND(AVG(al.interest_rate_pct), 2)
            AS DECIMAL (10,2)
            )                           AS avg_interest_rate,
        ac.avg_credit_score             AS avg_credit_score
    FROM active_loans                   AS al
    INNER JOIN active_customers         AS ac 
    ON al.customer_id = ac.customer_id
    GROUP BY al.loan_type, ac.avg_credit_score 
)  

SELECT
    -- final output
    loan_type,
    total_outstanding_balance,
    number_of_active_loans,
    avg_interest_rate,
    avg_credit_score,
    CASE 
        WHEN avg_credit_score < 500                     THEN 'High Risk'
        WHEN avg_credit_score BETWEEN 500 AND 700       THEN 'Medium Risk'
        WHEN avg_credit_score >= 700                    THEN 'Low Risk'
        ELSE 'Unknown'
    END AS flag_risk
FROM loan_risk_metrics;





