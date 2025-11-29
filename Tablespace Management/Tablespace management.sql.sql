-- Query that i always use: TABLESPACE USAGE REPORT (everything is gb)
set colsep
set linesize 100 pages 100 trimspool on numwidth 14
col name format a25
col owner format a15
col "Used (GB)" format a15
col "Free (GB)" format a15
col "(Used) %" format a15
col "Size (GB)" format a15

-- Permanent tablespaces
SELECT 
    d.status "Status",
    d.tablespace_name "Name",
    TO_CHAR(NVL(a.bytes/1024/1024/1024, 0), '99,999,990.90') "Size (GB)",
    TO_CHAR(NVL((a.bytes - NVL(f.bytes, 0))/1024/1024/1024, 0), '99,999,990.90') "Used (GB)",
    TO_CHAR(NVL(f.bytes/1024/1024/1024, 0), '99,999,990.90') "Free (GB)",
    TO_CHAR(NVL(((a.bytes - NVL(f.bytes, 0))/a.bytes)*100, 0), '990.00') "(Used) %"
FROM sys.dba_tablespaces d
LEFT JOIN (
    SELECT tablespace_name, SUM(bytes) AS bytes
    FROM dba_data_files
    GROUP BY tablespace_name
) a ON d.tablespace_name = a.tablespace_name
LEFT JOIN (
    SELECT tablespace_name, SUM(bytes) AS bytes
    FROM dba_free_space
    GROUP BY tablespace_name
) f ON d.tablespace_name = f.tablespace_name
WHERE NOT (d.extent_management LIKE 'LOCAL' AND d.contents LIKE 'TEMPORARY')
UNION ALL
-- temp tbs
SELECT 
    d.status "Status",
    d.tablespace_name "Name",
    TO_CHAR(NVL(a.bytes/1024/1024/1024, 0), '99,999,990.90') "Size (GB)",
    TO_CHAR(NVL(t.bytes/1024/1024/1024, 0), '99,999,990.90') "Used (GB)",
    TO_CHAR(NVL((a.bytes - NVL(t.bytes, 0))/1024/1024/1024, 0), '99,999,990.90') "Free (GB)",
    TO_CHAR(NVL((t.bytes / a.bytes)*100, 0), '990.00') "(Used) %"
FROM sys.dba_tablespaces d
LEFT JOIN (
    SELECT tablespace_name, SUM(bytes) AS bytes
    FROM dba_temp_files
    GROUP BY tablespace_name
) a ON d.tablespace_name = a.tablespace_name
LEFT JOIN (
    SELECT tablespace_name, SUM(bytes_cached) AS bytes
    FROM v$temp_extent_pool
    GROUP BY tablespace_name
) t ON d.tablespace_name = t.tablespace_name
WHERE d.extent_management LIKE 'LOCAL'
AND d.contents LIKE 'TEMPORARY';


-- To check datafile related to the specific tbs
set colsep |
set linesize 100 pages 100 trimspool on numwidth 14
col file_name format a42
SELECT file_name, ROUND (bytes / POWER(1024, 3), 2) AS size gb FROM dba data files WHERE tablespace name = 'SYSAUX';



-- To describe the data dictionary view for datafiles
DESC dba_data_files;

-- To check file name, tablespace name, size in GB, status
SELECT file_name,
       tablespace_name,
       bytes/1024/1024/1024 AS GB,
       status
FROM dba_data_files;


-- Simple tablespace creation with fixed size
CREATE TABLESPACE TBS1
DATAFILE 'disk2/data/u01/data01.dbf'
SIZE 5G;


-- Creating tablespace with autoextend enabled
CREATE TABLESPACE TBS1
DATAFILE 'disk2/data/u01/data01.dbf'
SIZE 560M
AUTOEXTEND ON
NEXT 1M
MAXSIZE 2G;


-- Adding a datafile + enabling autoextend
ALTER TABLESPACE TBS1
ADD DATAFILE 'disk2/data/u01/data02.dbf'
SIZE 560M
AUTOEXTEND ON
NEXT 1M
MAXSIZE 2G;


-- Resize the datafile to increase size manually
ALTER DATABASE DATAFILE 'disk2/data/u01/data01.dbf' RESIZE 7G;


--Enable Autoextend on an Existing Datafile
ALTER DATABASE DATAFILE '<path>/<filename>.dbf'
AUTOEXTEND ON NEXT <increment> MAXSIZE <limit>;


-- Drops tablespace including datafiles and contents
DROP TABLESPACE tbs1 INCLUDING CONTENTS AND DATAFILES;


-- Renaming a tablespace
ALTER TABLESPACE tbs1 RENAME TO dba_tools;


-- Drop a Datafile from Tablespace
ALTER TABLESPACE tbs1 DROP DATAFILE 'disk2/data/u01/data02.dbf';


--Renaming a datafile:
-- Step 1: Put tablespace offline before renaming datafile
ALTER TABLESPACE tbs1 OFFLINE;
-- Step 2: Attempt to rename file (will error if file not physically renamed)
ALTER TABLESPACE tbs1
RENAME DATAFILE 'disk2/data/u01/data01.dbf'
TO 'disk2/data/u01/data_01.dbf';
-- ERROR happens because OS file not renamed
-- # Step 3: Rename actual file at OS level
mv data01.dbf data_01.dbf
-- Step 4: Bring tablespace online
ALTER TABLESPACE tbs1 ONLINE;



-- Creating a tablespace with 16K block size
SHOW PARAMETER db_block_size;
ALTER SYSTEM SET db_16k_cache_size=10G SCOPE=BOTH;
CREATE TABLESPACE TBS2
DATAFILE 'disk2/data/u02/data01.dbf'
SIZE 5G
BLOCKSIZE 16K;


-- temporary tablespace queries
DESC dba_temp_files;
SELECT file_name,
       tablespace_name,
       bytes/1024/1024/1024 AS GB,
       status
FROM dba_temp_files;


-- REsize temporary file
ALTER DATABASE
TEMPFILE 'disk2/data/u03/temp01.dbf'
RESIZE 4G;


-- Create temporary tablespace
CREATE TEMPORARY TABLESPACE TEMP2
TEMPFILE 'disk2/data/u03/temp02.dbf'
SIZE 2G;


-- Check default temporary tablespace
SELECT * 
FROM database_properties 
WHERE property_name LIKE '%TABLESPACE';


-- Alter default temporary tablepsace
ALTER DATABASE DEFAULT TEMPORARY TABLESPACE temp01;



-- Temporary Tablespace groups
SELECT * FROM temporary_tablespace_groups;
-- Create new temporary tablespace and add to group
CREATE TEMPORARY TABLESPACE TEMP3
TEMPFILE 'disk2/data/u03/temp03.dbf'
SIZE 2G
TABLESPACE GROUP te_group;

-- Add existing temp tablespaces to group
ALTER TABLESPACE temp01 TABLESPACE GROUP te_group;
ALTER TABLESPACE temp02 TABLESPACE GROUP te_group;

SELECT * FROM temporary_tablespace_groups;

-- Set group as default temporary tablespace
ALTER DATABASE DEFAULT TEMPORARY TABLESPACE te_group;

SELECT * FROM temporary_tablespace_groups;



