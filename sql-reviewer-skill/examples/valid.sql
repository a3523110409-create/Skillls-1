-- =============================================================================
-- EXAMPLES: VALID SQL STATEMENTS
-- These statements adhere strictly to all security, performance, integrity,
-- and naming convention rules. They should produce 0 violations.
-- =============================================================================

-- 1. Clean Bounded SELECT with explicit column projections
SELECT FNUSER_ID, FCUSER_NAME, FCEMAIL, FDCREATED_AT
FROM TA_USERS
WHERE FCSTATUS = 'ACTIVE'
ORDER BY FDCREATED_AT DESC
LIMIT 50;

-- 2. Safe Parametric DML Update with precise primary key filtering
UPDATE TA_USERS
SET FCUSER_NAME = :userName,
    FDUPDATED_AT = CURRENT_TIMESTAMP
WHERE FNUSER_ID = :userId 
  AND FDIS_DELETED = 0;

-- 3. High-performance SARGable Date-Range Query with proper IS NULL predicate
SELECT FNORDER_ID, FNUSER_ID, FNTOTAL_AMOUNT
FROM TA_ORDERS
WHERE FDORDER_DATE >= '2026-01-01' 
  AND FDORDER_DATE < '2026-02-01'
  AND FDCANCELLED_AT IS NULL
ORDER BY FDORDER_DATE ASC
LIMIT 100;

-- 4. Clean Soft Delete Update avoiding destructive hard DELETE
UPDATE TA_PRODUCTS
SET FDIS_DELETED = 1,
    FDDELETED_AT = CURRENT_TIMESTAMP
WHERE FNPRODUCT_ID = :productId
  AND FDIS_DELETED = 0;

-- 5. Explicit JOIN aggregation with matching data types
SELECT u.FNUSER_ID, u.FCUSER_NAME, COUNT(o.FNORDER_ID) AS FNTOTAL_ORDERS
FROM TA_USERS u
INNER JOIN TA_ORDERS o ON u.FNUSER_ID = o.FNUSER_ID
WHERE u.FCSTATUS = 'ACTIVE'
GROUP BY u.FNUSER_ID, u.FCUSER_NAME
LIMIT 200;
