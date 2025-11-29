--check undo tablespace
SHOW PARAMETER undo;

--View UNDO Tablespace Size & Status
SELECT tablespace_name,
       status,
       contents,
       extent_management
FROM dba_tablespaces
WHERE contents = 'UNDO';

-- Check UNDO Usage
SELECT tablespace_name,
       SUM(bytes)/1024/1024/1024 AS used_GB
FROM dba_undo_extents
WHERE status = 'ACTIVE'
GROUP BY tablespace_name;

--Create a New UNDO Tablespace
CREATE UNDO TABLESPACE undo2DATAFILE '/u01/app/oracle/oradata/ORCL/undots02.dbf' SIZE 2G;

-- Switch Database to New UNDO Tablespace
ALTER SYSTEM SET undo_tablespace = undo2;

-- Resize Existing UNDO Datafile
ALTER DATABASE DATAFILE '/u01/app/oracle/oradata/ORCL/undo1.dbf' RESIZE 3G;

-- Add Additional Datafile to UNDO
ALTER TABLESPACE undo1 ADD DATAFILE '/u01/app/oracle/oradata/ORCL/undots03.dbf' SIZE 1G;

-- Drop Old/Unused UNDO Tablespace
DROP TABLESPACE undotbs1 INCLUDING CONTENTS AND DATAFILES;


-- Fix ORA-01555 Snapshot Too Old  --- ************ v.imp 
ALTER SYSTEM SET undo_retention = 3600;  -- 1 hour
