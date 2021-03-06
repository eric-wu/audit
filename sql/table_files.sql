-- File entities and their containing project
CREATE TABLE AUDIT_FILES AS
SELECT DISTINCT
    NODE.ID AS ID,
    NODE.NAME AS NAME,
    FROM_UNIXTIME(NODE.CREATED_ON / 1000) AS CREATED_ON,
    NODE.CREATED_BY AS CREATED_BY,
    -- Back track at most 16 levels to find the containing project
    -- The first non-null parent is the containing project
    -- Or there can be a special case where the file has no containing project (24 such files) and
    -- the parent project will back track all the way to the root (ID 4489)
    CASE
        WHEN P16.ID IS NOT NULL THEN -1 -- Parent recursion overflow
        ELSE NULLIF(COALESCE(P15.ID, P14.ID, P13.ID, P12.ID, P11.ID, P10.ID, P9.ID, P8.ID,
            P7.ID, P6.ID, P5.ID, P4.ID, P3.ID, P2.ID, P1.ID), 4489)
    END AS PROJECT_ID
FROM
    JDONODE NODE
    LEFT JOIN JDONODE P1 ON NODE.PARENT_ID = P1.ID
    LEFT JOIN JDONODE P2 ON (P1.PARENT_ID = P2.ID AND P1.NODE_TYPE != 2) -- Type 2 is project
    LEFT JOIN JDONODE P3 ON (P2.PARENT_ID = P3.ID AND P2.NODE_TYPE != 2)
    LEFT JOIN JDONODE P4 ON (P3.PARENT_ID = P4.ID AND P3.NODE_TYPE != 2)
    LEFT JOIN JDONODE P5 ON (P4.PARENT_ID = P5.ID AND P4.NODE_TYPE != 2)
    LEFT JOIN JDONODE P6 ON (P5.PARENT_ID = P6.ID AND P5.NODE_TYPE != 2)
    LEFT JOIN JDONODE P7 ON (P6.PARENT_ID = P7.ID AND P6.NODE_TYPE != 2)
    LEFT JOIN JDONODE P8 ON (P7.PARENT_ID = P8.ID AND P7.NODE_TYPE != 2)
    LEFT JOIN JDONODE P9 ON (P8.PARENT_ID = P9.ID AND P8.NODE_TYPE != 2)
    LEFT JOIN JDONODE P10 ON (P9.PARENT_ID = P10.ID AND P9.NODE_TYPE != 2)
    LEFT JOIN JDONODE P11 ON (P10.PARENT_ID = P11.ID AND P10.NODE_TYPE != 2)
    LEFT JOIN JDONODE P12 ON (P11.PARENT_ID = P12.ID AND P11.NODE_TYPE != 2)
    LEFT JOIN JDONODE P13 ON (P12.PARENT_ID = P13.ID AND P12.NODE_TYPE != 2)
    LEFT JOIN JDONODE P14 ON (P13.PARENT_ID = P14.ID AND P13.NODE_TYPE != 2)
    LEFT JOIN JDONODE P15 ON (P14.PARENT_ID = P15.ID AND P14.NODE_TYPE != 2)
    LEFT JOIN JDONODE P16 ON (P15.PARENT_ID = P16.ID AND P15.NODE_TYPE != 2)
WHERE
    NODE.NODE_TYPE = 16 AND        -- Type 16 is file
    NODE.BENEFACTOR_ID <> 1681355; -- Not in trash can

-- Adds indices
ALTER TABLE AUDIT_FILES ADD INDEX USING HASH (ID);
ALTER TABLE AUDIT_FILES ADD INDEX USING BTREE (CREATED_ON);
ALTER TABLE AUDIT_FILES ADD INDEX USING HASH (CREATED_BY);
ALTER TABLE AUDIT_FILES ADD INDEX USING HASH (PROJECT_ID);

-- Unit tests
SELECT CONCAT(CASE WHEN
    (SELECT COUNT(ID) FROM AUDIT_FILES WHERE PROJECT_ID < 0) = 0
    THEN 'PASSED' ELSE 'FAILED' END,
    ' -- The recursion on parent-id is deep enough.');

SELECT CONCAT(CASE WHEN
    (SELECT COUNT(ID) FROM AUDIT_FILES) > 50000
    THEN 'PASSED' ELSE 'FAILED' END,
    ' -- At least 50,000 files.');

SELECT CONCAT(CASE WHEN
    (SELECT COUNT(ID) FROM AUDIT_FILES WHERE PROJECT_ID = 4489) = 0
    THEN 'PASSED' ELSE 'FAILED' END,
    ' -- No file should have the root as the project.');

SELECT CONCAT(CASE WHEN
    (SELECT COUNT(ID) FROM AUDIT_FILES WHERE PROJECT_ID = 1834618) = 0
    THEN 'PASSED' ELSE 'FAILED' END,
    ' -- 0 files in the project of getting started with the R client');

SELECT CONCAT(CASE WHEN
    (SELECT COUNT(ID) FROM AUDIT_FILES WHERE ID = 1670933) = 0
    THEN 'PASSED' ELSE 'FAILED' END,
    ' -- Test the file Controlled Use Example. This is not a public file.');

SELECT CONCAT(CASE WHEN
    (SELECT COUNT(ID) FROM AUDIT_FILES WHERE ID = 1739275) = 0
    THEN 'PASSED' ELSE 'FAILED' END,
    ' -- Test the BCC final leader board file. This is a legacy layer object.');

SELECT CONCAT(CASE WHEN
    (SELECT PROJECT_ID FROM AUDIT_FILES WHERE ID = 2331029) = 1734172
    THEN 'PASSED' ELSE 'FAILED' END,
    ' -- Test a RA Challenge file and its containing project.');
