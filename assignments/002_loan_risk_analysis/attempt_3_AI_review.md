## Code Review — Attempt 3 (Final)

---

### A. Overall Assessment
The missing `dbo.accounts` requirement is now addressed — that is the most important fix. However, several issues from the previous attempt carried over unchanged, and one new logical problem exists with how accounts link to loans.

---

### B. Correctness

**Critical issues:**
- **`active_customers` CTE joins `dbo.accounts` on `customer_id` — but `dbo.accounts` links to `dbo.loans` via `account_id`, not `customer_id`.** A customer can have multiple accounts, only some of which may be active. The correct filter is: the loan's `account_id` must match an account with `status = 'Active'` — not just any active account belonging to that customer. Your current approach would include a loan even if its specific account is inactive, as long as the customer has any other active account.
- **Redundant `WHERE al.customer_id = ac.customer_id`** — still present from the previous attempt. The `INNER JOIN` already enforces this. This is dead logic.
- **`CAST(AVG(al.interest_rate_pct) AS DECIMAL(10,2))` without `ROUND`** — still present. `CAST` truncates, not rounds. Financial figures must be rounded before casting.
- **Active customer filter missing from `dbo.customers`.** You filter active accounts via `dbo.accounts` but never filter `c.is_active = 1` on `dbo.customers`. An inactive customer with an active account would still appear.

**Correct decisions:**
- `dbo.accounts` is now included ✅
- Grain correct — one row per loan type ✅
- Boundary conditions correct ✅
- `active_loans` CTE pre-filtering correct ✅
- `ELSE 'Unknown'` retained ✅

---

### C. Data Grain

**Intended grain:** One row per loan product type

**Actual grain:** One row per loan type — matches ✅

**JOIN cardinality risk:**
- `active_customers` from `dbo.accounts` by `customer_id` — a customer with multiple active accounts produces multiple rows in `active_customers`. When joined to `active_loans` on `customer_id`, this multiplies loan rows — one per active account per customer. This inflates `COUNT(loan_id)` and distorts `SUM(outstanding_balance)` and `AVG` calculations silently.

---

### D. Code Quality & Structure
- Redundant `WHERE` clause still present ⚠️
- `ROUND` missing on interest rate ⚠️
- Structure and comments otherwise clean ✅

---

### E. SQL Best Practices
- Joining on `customer_id` through `dbo.accounts` instead of `account_id` is the core logic error
- Redundant `WHERE` repeating JOIN condition remains an anti-pattern
- Missing `ROUND` before `CAST` on financial average

---

### K. Production Verdict
❌ REQUEST CHANGES

---

### L. Score: 6.5/10

Real progress — `dbo.accounts` is included, structure is clean, and grain is correct at the output level. The account linkage logic is wrong in a way that would produce silently incorrect numbers in production, which is the most dangerous kind of bug.

---

## Final Production-Grade Solution

```sql
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
```

---

## Why This Is Better

**1. Account linked via `account_id`, not `customer_id`**
Each loan has a specific `account_id`. Filtering on that account's status ensures the loan's own account is active — not just any account the customer holds.

**2. Both loan and account filters in one CTE**
`active_loan_base` enforces both `l.status = 'Active'` and `a.status = 'Active'` in a single pass. Downstream CTEs work only on qualifying loans.

**3. Customer activity separated cleanly**
`active_customer_scores` isolates the customer filter and the credit score retrieval. The aggregation CTE stays focused on metrics only.

**4. No redundant JOIN conditions in `WHERE`**
`INNER JOIN` enforces the relationship. The `WHERE` clause handles only business filters — not structural joins.

**5. `ROUND` before `CAST` on all financial figures**
Prevents silent truncation of decimal values in financial calculations.

**6. Simplified `CASE WHEN`**
Since conditions are evaluated top to bottom, `< 500` catches High Risk, `< 700` catches Medium Risk (already passed `< 500`), and `ELSE` catches everything ≥ 700. No need for `AND` conditions.

**7. `ORDER BY loan_type`**
Deterministic output ordering — production reports should never rely on undefined sort order.

---

Now treat this as AI-generated code. Find the flaws.