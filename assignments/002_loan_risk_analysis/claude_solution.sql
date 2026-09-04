-- ============================================================
-- Assignment 002: Loan Portfolio Risk Analysis
-- Grain: one row per loan product type
-- Filters: active loans, active associated account, 
--          active customer
-- ============================================================

WITH active_loan_base AS (
    -- Pre-filter active loans and join to their specific account
    -- dbo.loans links to dbo.accounts via account_id (not customer_id)
    -- This ensures the loan's OWN account is active, not just any
    -- account belonging to the customer
    SELECT
        l.loan_id,
        l.loan_type,
        l.outstanding_balance,
        l.interest_rate_pct,
        l.customer_id
    FROM dbo.loans         AS l
    INNER JOIN dbo.accounts AS a
        ON l.account_id = a.account_id
    WHERE l.status = 'Active'
      AND a.status  = 'Active'
),

active_customer_scores AS (
    -- Pre-filter active customers and retain credit score
    -- Separated to keep aggregation logic clean
    SELECT
        customer_id,
        credit_score
    FROM dbo.customers
    WHERE is_active = 1
),

loan_risk_metrics AS (
    -- Aggregate at loan_type grain
    -- AVG(credit_score) is across all customers with active loans
    -- in that product type
    SELECT
        alb.loan_type,
        CAST(
            ROUND(SUM(alb.outstanding_balance), 2)
            AS DECIMAL(18, 2)
        )                                        AS total_outstanding_balance,
        COUNT(alb.loan_id)                       AS number_of_active_loans,
        CAST(
            ROUND(AVG(alb.interest_rate_pct), 2)
            AS DECIMAL(10, 2)
        )                                        AS avg_interest_rate,
        CAST(
            ROUND(AVG(acs.credit_score), 2)
            AS DECIMAL(10, 2)
        )                                        AS avg_credit_score
    FROM active_loan_base       AS alb
    INNER JOIN active_customer_scores AS acs
        ON alb.customer_id = acs.customer_id
    GROUP BY alb.loan_type
)

-- Final output with risk flag
SELECT
    loan_type,
    total_outstanding_balance,
    number_of_active_loans,
    avg_interest_rate,
    avg_credit_score,
    CASE
        WHEN avg_credit_score <  500 THEN 'High Risk'
        WHEN avg_credit_score <  700 THEN 'Medium Risk'
        ELSE                              'Low Risk'
    END                                          AS risk_flag
FROM loan_risk_metrics
ORDER BY loan_type;