## Code Review — Attempt 2

---

### A. Overall Assessment
This is a significant leap from Attempt 1. The grain is now correct — 5 rows, one per loan type. The boundary condition bug is fixed. The unnecessary CTE is gone. This is approaching production quality with a few remaining issues worth addressing.

---

### B. Correctness

**Critical issues:**
- **The assignment requires filtering on active accounts (`dbo.accounts`), not just active customers.** The request explicitly states: *"active loans where the associated customer account is also active."* You joined `dbo.customers` and filtered `c.is_active = 1` — but `dbo.accounts` has its own `status` column and was not joined at all. This is a missing business requirement.

**Minor issues:**
- `ROUND(AVG(c.credit_score), 2)` — `credit_score` is likely an integer. `AVG` of integers in MSSQL returns an integer, so `ROUND(..., 2)` has no effect. The `.00` display comes from `CAST AS DECIMAL(10,2)`, not from rounding. This is not wrong but signals a misunderstanding of what `ROUND` is doing here.
- `WHERE c.is_active = 1` applied after `INNER JOIN` — functionally correct but less efficient than pre-filtering customers in a CTE before the join, as established in Assignment 1.

**Correct decisions:**
- Grain is now correct — one row per `loan_type` ✅
- `GROUP BY al.loan_type` only — clean and stable ✅
- Boundary condition fixed — `>= 500 AND < 700` correctly excludes 700 from Medium Risk ✅
- `ELSE 'Unknown'` retained as a safety net ✅
- `CAST(ROUND(...) AS DECIMAL(10,2))` applied consistently ✅
- Comment corrected — no longer references transactions ✅

---

### C. Data Grain

**Intended grain:** One row per loan product type

**Actual grain:** One row per loan type — matches ✅

**JOIN cardinality:**
- `active_loans` to `dbo.customers` → many:1 on `customer_id` ✅
- No row multiplication risk ✅
- Missing: `dbo.accounts` join — the account activity filter is absent

---

### D. Code Quality & Structure

- Clean, readable, well-commented ✅
- CTE separation of concerns is appropriate ✅
- Alignment is consistent and professional ✅
- The final `SELECT` comment placement above the `SELECT` keyword is slightly unconventional — comments typically sit inside or above the CTE they describe, not floating between CTEs and the final query

---

### E. SQL Best Practices

- Missing required table join is the primary issue
- `WHERE` on joined table column after join rather than pre-filtering — minor but worth noting given Assignment 1 feedback
- `ROUND` on integer `AVG` — no effect, adds noise

---

### F. Performance

- Single scan on `dbo.loans` via CTE ✅
- Direct join to `dbo.customers` is clean ✅
- Post-join `WHERE` filter on `c.is_active` means all customers are joined before filtering — pre-filtering active customers first would reduce the join dataset

---

### G. Scalability

- Correct grain means no row explosion at scale ✅
- Pre-filtering active customers before join would improve scalability at large customer table sizes

---

### H. Cost Efficiency

- Missing `dbo.accounts` join means the query is cheaper than it should be — but only because it's incomplete, not because it's optimized

---

### I. Edge Cases

- Loans with no matching customer dropped silently — acceptable ✅
- Loans linked to inactive accounts are incorrectly included — missing requirement
- A loan type with all customers having the same credit score of exactly 700 would correctly show Low Risk ✅

---

### J. Production Readiness

Not production-ready due to the missing `dbo.accounts` filter. Everything else is close.

---

### K. Production Verdict

❌ REQUEST CHANGES

---

### L. Score: 7.5/10

Strong structural improvement and correct grain — this would score higher if the `dbo.accounts` requirement hadn't been missed. Re-read the assignment requirements carefully before submitting Attempt 3. This is your final attempt.

**The key question before writing Attempt 3:**

> How does `dbo.accounts` link to `dbo.loans`, and what condition on `dbo.accounts` needs to be satisfied?