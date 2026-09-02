-- Final Production-Grade Solution
-- ============================================================
-- Assignment 001: Customer Transaction Analysis
-- Grain: One row per active customer with >= 5 transactions
-- ============================================================

WITH active_customers AS (
    -- Pre-filter active customers before joining to transactions
    -- Reduces the working dataset early, improving JOIN efficiency
    SELECT
        customer_id,
        credit_score,
        employment_status
    FROM dbo.customers
    WHERE is_active = 1
),

customer_transaction_summary AS (
    -- Aggregate transactions for active customers only
    -- Grain: one row per customer_id
    SELECT
        t.customer_id,
        COUNT(t.transaction_id)                        AS transaction_volume,
        CAST(
            ROUND(AVG(t.amount_aud), 2)
            AS DECIMAL(10, 2)
        )                                              AS avg_transaction_amount
    FROM dbo.transactions AS t
    INNER JOIN active_customers AS ac
        ON t.customer_id = ac.customer_id
    GROUP BY t.customer_id
    HAVING COUNT(t.transaction_id) >= 5
)

-- Final output: join aggregated transactions back to customer attributes
-- INNER JOIN is explicit and intentional — we only want customers in both sets
SELECT
    cts.customer_id,
    cts.transaction_volume,
    cts.avg_transaction_amount,
    ac.credit_score,
    ac.employment_status
FROM customer_transaction_summary AS cts
INNER JOIN active_customers AS ac
    ON cts.customer_id = ac.customer_id
ORDER BY cts.transaction_volume DESC;
/*
Why This Is Better

1. Early filtering via active_customers CTE
Inactive customers are eliminated before touching dbo.transactions. The JOIN and aggregation only process data that will appear in the final output.

2. Grain is protected
Aggregation groups only by t.customer_id — the stable, immutable key. Customer attributes (credit_score, employment_status) are joined after aggregation, not grouped on. This means if attributes change, the aggregation layer is unaffected.

3. Explicit INNER JOIN with clear intent
Every JOIN type is chosen deliberately. A reader immediately understands the relationship without having to reason about whether a LEFT JOIN was intentional.

4. HAVING inside the aggregation CTE
The >= 5 filter is applied at the earliest possible point — inside the CTE, not in the outer query — reducing rows carried forward.

5. No COALESCE on COUNT
COUNT never returns NULL. Wrapping it adds noise and signals uncertainty about how the function works.

6. Two CTEs, each with a single responsibility
active_customers handles filtering. customer_transaction_summary handles aggregation. The final SELECT handles presentation. Each layer does one thing — this is maintainable and easy to debug.

Now treat this as AI-generated code. Find the flaws. */
