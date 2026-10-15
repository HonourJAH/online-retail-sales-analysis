-- 06_validate_flagged.sql
-- Purpose: check that the exclusion flags reconcile with the profiling findings.
--          Rows by exclusion_reason must add up to the staging row count (541,910),
--          and no zero-price row may be left unflagged.
-- Reads:   online_retail_flagged


-- count the rows by exclusion reason
SELECT
    COALESCE(exclusion_reason, 'KEEP') AS exclusion_reason,
    COUNT(*)                           AS n_rows
FROM online_retail_flagged
GROUP BY exclusion_reason
ORDER BY n_rows DESC;


-- confirm that no zero-price row survives
SELECT
    COALESCE(exclusion_reason, 'KEEP') AS exclusion_reason,
    COUNT(*)                           AS n_rows
FROM online_retail_flagged
WHERE Price = 0
GROUP BY exclusion_reason;







