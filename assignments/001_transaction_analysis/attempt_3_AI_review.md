## Code Review — Attempt 3 (Final)

---

### A. Overall Assessment
Meaningful evolution from Attempt 2. The explicit casting, `COALESCE`, and direct JOIN approach show growing engineering awareness. However, this attempt introduces a new correctness issue that is more serious than what it fixed — and a JOIN type decision that needs to be examined carefully.

---

### B. Correctness

**Critical issues:**
- **`LEFT JOIN` is wrong here.** You switched from `INNER JOIN` to `LEFT JOIN` — but then filter `WHERE c.is_active = 1`. When you apply a `WHERE` filter on the right-side table of a `LEFT JOIN`, it implicitly converts it to an `INNER JOIN` anyway — but worse, it creates ambiguity and signals to any reader that you may not understand what you're doing. If a transaction has no matching customer, `c.is_active` would be NULL, which fails `= 1`, so those rows are dropped. Use `INNER JOIN` and be explicit.
- **`COALESCE(COUNT(t.transaction_id), 0)` is unnecessary.** `COUNT()` never returns NULL — it returns 0 if no rows match. `COALESCE` here adds noise without value and signals a misunderstanding of how `COUNT` works.

**Minor issues:**
- `GROUP BY t.customer_id, c.credit_score, c.employment_status` — you are grouping by customer attributes from the customers table. This is correct for this query, but it means if a customer ever has their `credit_score` or `employment_status` updated mid-period, historical groupings could split. In production, grouping by `customer_id` only in the CTE and joining customer attributes afterward is safer and more maintainable.

**Correct decisions:**
- `CAST(ROUND(AVG(amount_aud), 2) AS DECIMAL(10, 2))` — correct, fixes the display inconsistency ✅
- Filtering `WHERE c.is_active = 1` before aggregation — conceptually right intent ✅
- Execution time dropped from 96ms to 34ms — the direct JOIN approach is faster ✅
- `7033.40` now displays correctly with 2 decimal places ✅

---

### C. Data Grain

**Intended grain:** One row per active customer with ≥ 5 transactions

**Actual grain:** One row per `(customer_id, credit_score, employment_status)` combination

**This is a data grain risk.** If `credit_score` or `employment_status` were to change and historical records retained both values, you could get multiple rows per customer. On this dataset it produces one row per customer — but the grain is technically wider than needed. The safer design groups only by `customer_id` in the aggregation layer and joins customer attributes separately.

**JOIN cardinality:**
- `dbo.transactions` to `dbo.customers` → many:1 on `customer_id`
- After `GROUP BY customer_id` → 1:1 effective output ✅
- No row multiplication ✅

---

### D. Code Quality & Structure

- Removal of CTE simplifies the query — acceptable tradeoff at this complexity level ✅
- Inline comments retained ✅
- `COALESCE(COUNT(...), 0)` adds unnecessary noise
- `LEFT JOIN` when `INNER JOIN` is intended is a readability and intent problem — another engineer reading this would question why `LEFT JOIN` was chosen
- Column alignment in `SELECT` is clean ✅

---

### E. SQL Best Practices

- **Anti-pattern:** `LEFT JOIN` neutralized by `WHERE` on the right table — always use the JOIN type that matches your actual intent
- **Unnecessary:** `COALESCE` wrapping `COUNT` — `COUNT` never returns NULL
- **Risk:** Grouping by mutable customer attributes instead of stable keys

---

### F. Performance

- Direct JOIN without CTE is faster — confirmed by 34ms vs 96ms ✅
- `WHERE c.is_active = 1` before `GROUP BY` correctly reduces rows before aggregation ✅
- No redundant scans ✅

---

### G. Scalability

- Single scan, early filtering — scales well ✅
- Grouping by `credit_score` and `employment_status` adds marginal overhead but not significant at this scale

---

### H. Cost Efficiency

- Most efficient attempt yet ✅
- Early active customer filter reduces data processed through aggregation ✅

---

### I. Edge Cases

- `COALESCE(COUNT(...), 0)` is harmless but unnecessary — `COUNT` handles empty sets correctly on its own
- The `LEFT JOIN` + `WHERE` pattern silently drops unmatched transactions — same outcome as `INNER JOIN` but less explicit

---

### J. Production Readiness

Almost there. Two issues prevent full approval: the `LEFT JOIN` intent mismatch and grouping by mutable customer attributes.

---

### K. Production Verdict

⚠️ APPROVE WITH CHANGES

---

### L. Score: 7.5/10

Same score as Attempt 2 — you fixed the right things but introduced new issues of comparable weight. The performance improvement is real and noted. The `LEFT JOIN` + `WHERE` anti-pattern and unnecessary `COALESCE` offset the gains.

---

