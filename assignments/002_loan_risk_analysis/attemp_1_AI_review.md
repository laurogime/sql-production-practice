## Code Review — Attempt 1

---

### A. Overall Assessment
Honest self-assessment noted and respected — that kind of awareness is itself a production engineering skill. The query runs and produces output, but you have correctly identified the core grain problem yourself. There are also additional issues beyond what you spotted.

---

### B. Correctness

**Critical issues:**
- **The grain is wrong — and you already know it.** The result shows 30 rows across 5 loan types. The business request asks for one row per loan product type — meaning 5 rows maximum. The root cause is in `active_customers` and how `avg_credit_score` flows into the final `GROUP BY`.
- **`AVG(credit_score)` grouped by `customer_id` in `active_customers` is meaningless.** A customer has exactly one `credit_score` — averaging a single value per customer just returns that same value. This CTE adds no value and creates the grain explosion downstream.
- **`GROUP BY al.loan_type, ac.avg_credit_score`** — this is the grain explosion. Because each customer has a unique `credit_score`, `avg_credit_score` in the CTE is just the customer's own score. Grouping by it alongside `loan_type` produces one row per `(loan_type, customer_credit_score)` combination — not one row per loan type.

**Correct decisions:**
- `CASE WHEN` risk flag logic is correct ✅
- `CAST(ROUND(...) AS DECIMAL(10,2))` applied correctly ✅
- `INNER JOIN` used with explicit intent ✅
- Early filtering of active loans and customers ✅
- `COUNT(al.loan_id)` correct ✅

---

### C. Data Grain

**Intended grain:** One row per loan product type

**Actual grain:** One row per `(loan_type, customer_credit_score)` combination

**Root cause:** `avg_credit_score` per `customer_id` is just the customer's individual score. When you group by `loan_type` AND this per-customer score, you get one row per unique score within each loan type — blowing the grain wide open.

**What you actually need:** Aggregate `credit_score` across all customers belonging to each `loan_type` — meaning the `AVG(credit_score)` must happen at the `loan_type` grain, not at the `customer_id` grain first.

---

### D. Code Quality & Structure

- CTE naming is clear and purposeful ✅
- Comments explain intent ✅
- Formatting and alignment are consistent ✅
- `active_customers` CTE is structurally unnecessary in its current form — the per-customer AVG adds no value
- The comment "Pre-filter active customers before joining to transactions" references transactions, but this query has no transactions table — copy-paste from Assignment 1 ⚠️

---

### E. SQL Best Practices

- Grouping by a derived aggregate (`avg_credit_score`) that is effectively just the raw value per customer is a subtle but serious anti-pattern
- The `active_customers` CTE could be simplified to a simple filter — the `GROUP BY customer_id` and `AVG` serve no purpose here

---

### F. Performance

- Early filtering in CTEs is good ✅
- The unnecessary `GROUP BY customer_id` in `active_customers` adds an aggregation pass that produces no useful transformation — wasted compute

---

### G. Scalability

- The grain explosion means at scale, the intermediate result set grows with the number of unique `(loan_type, credit_score)` combinations — not just loan types. This compounds at scale.

---

### H. Cost Efficiency

- Unnecessary aggregation in `active_customers` CTE costs compute for no gain
- Grain explosion means more rows carried through the pipeline than needed

---

### I. Edge Cases

- `BETWEEN 500 AND 700` — the boundary value of exactly 700 falls into 'Medium Risk'. The business spec says "700 and above is Low Risk" — meaning 700 should be Low Risk. Your `BETWEEN` catches 700 as Medium Risk. This is a boundary condition bug.
- Loans with no matching customer are silently dropped — acceptable but should be a conscious decision

---

### J. Production Readiness

Not production-ready. Wrong grain, boundary condition bug, and a meaningless CTE aggregation.

---

### K. Production Verdict

❌ REQUEST CHANGES

---

### L. Score: 5/10

Structure and habits are improving — CTEs, comments, explicit casting, and early filtering show real growth. The grain problem is the central issue, and you identified it yourself, which matters. The boundary condition bug on 700 is a separate issue worth fixing independently. You have 2 attempts remaining — take the time to think through the grain before writing the next query.

**The key question to answer before writing Attempt 2:**

> At what point in the query should `AVG(credit_score)` be calculated, and over what set of rows?