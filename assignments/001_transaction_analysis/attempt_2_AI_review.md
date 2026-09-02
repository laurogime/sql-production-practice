## Code Review — Attempt 2

---

### A. Overall Assessment
Meaningful improvement from Attempt 1. The double scan is eliminated, rounding is applied, and inline comments show engineering awareness. However, there are still issues that would prevent this from being approved in a production code review.

---

### B. Correctness

**Critical issues:**
- `COUNT(transaction_id)` — good choice over `COUNT(*)`, but only if `transaction_id` is guaranteed non-NULL. If it can be NULL, some transactions would be silently undercounted. In production you must know your data guarantees.
- `ROUND(AVG(amount_aud), 2)` — `AVG` on a financial column in MSSQL returns the same data type as the input. If `amount_aud` is an integer type, `AVG` truncates before rounding, producing wrong results. You need to verify the column type or cast explicitly.

**Minor issues:**
- Row 2: `CUST0093` shows `avg_transaction_amount = 7033.4` — only one decimal place displayed. `ROUND(..., 2)` guarantees the calculation is to 2 places but display formatting depends on the data type. In production, `CAST(ROUND(..., 2) AS DECIMAL(10,2))` ensures consistent display.
- The `is_active = 1` filter is applied after the JOIN — this is correct logically, but filtering active customers **before** joining to transactions would be more efficient.

**Correct decisions:**
- Single CTE scanning `dbo.transactions` once ✅
- `COUNT(transaction_id)` over `COUNT(*)` ✅
- `ROUND()` applied ✅
- Inline comments explaining filter logic ✅

---

### C. Data Grain

**Intended grain:** One row per active customer with ≥ 5 transactions

**Actual grain:** One row per customer — matches ✅

**JOIN cardinality:**
- `transaction_analysis` CTE → `dbo.customers` on `customer_id` → 1:1 ✅
- No row multiplication risk

**One concern:** The CTE aggregates ALL customers including inactive ones, then filters in `WHERE`. This means you are computing aggregations for customers you will ultimately discard — wasted compute.

---

### D. Code Quality & Structure

- Single CTE is clean and readable ✅
- Inline comments are a good production habit ✅
- Alias names are consistent and descriptive ✅
- **One issue:** `FROM transaction_analysis AS ta` on line 15 has inconsistent indentation compared to the rest of the query — `FROM` should align with `SELECT` at the same level

---

### E. SQL Best Practices

- **Inefficiency:** Aggregating all customers in the CTE before filtering for active ones means inactive customer data is computed and then thrown away. The `is_active` filter should reduce the dataset before aggregation.
- **Data type risk:** `AVG` without explicit casting is a known MSSQL pitfall in financial calculations.

---

### F. Performance

- Single table scan on `dbo.transactions` — correct ✅
- However, the CTE computes aggregations for all customers, then discards inactive ones at the `WHERE` clause. A more efficient approach filters active customers first, then aggregates only their transactions.
- At 10M+ transaction rows, computing and discarding inactive customer aggregations wastes meaningful compute.

---

### G. Scalability

- Single scan scales better than Attempt 1 ✅
- The inactive customer aggregation waste grows proportionally with the number of inactive customers — if 40% of customers are inactive, you are doing 40% unnecessary aggregation work at any scale.

---

### H. Cost Efficiency

- Improved from Attempt 1 ✅
- The unnecessary aggregation of inactive customers is a cost inefficiency that compounds at scale in cloud environments.

---

### I. Edge Cases

- Customers in `dbo.transactions` with no matching record in `dbo.customers` are silently dropped by the INNER JOIN — acceptable given the business requirement but should be a conscious decision
- `avg_transaction_amount` display inconsistency (`7033.4` vs `9007.54`) should be resolved with explicit casting

---

### J. Production Readiness

Closer but not there yet. Two fixable issues remain: filter efficiency and data type safety on the average calculation.

---

### K. Production Verdict

⚠️ APPROVE WITH CHANGES

---

### L. Score: 7.5/10

Solid improvement. The core design is now sound. Remaining issues are the inactive customer aggregation waste and the data type safety on `AVG`. This is your final attempt — fix both and submit Attempt 3.