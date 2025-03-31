
--*************************************************************************--
-- Title: Automate creating a Staging table
-- Author: GObse
-- Desc: This file creates view 'dbo.vw_JobHistory' in msdb database.
-- Change Log: When,Who,What
-- 2025-03-23,GObse,Created File
--**************************************************************************--
Use msdb
go
If (OBJECT_ID('dbo.vw_JobHistory') is not null) Drop View dbo.vw_JobHistory;
go

--Select * From msdb.dbo.sysjobs;
--Select * From msdb.dbo.sysjobhistory;

-- Use this to CLEAR the jobhistory table
-- EXEC MSDB.dbo.sp_purge_jobhistory ;  

CREATE VIEW dbo.vw_JobHistory AS
SELECT top 100
    j.name AS JobName,
    h.step_id AS StepID,
    h.step_name AS StepName,
    h.run_date AS RunDate,
    h.run_time AS RunTime,
    h.run_duration AS Duration,
    CASE h.run_status
        WHEN 0 THEN 'Failed'
        WHEN 1 THEN 'Succeeded'
        WHEN 2 THEN 'Retry'
        WHEN 3 THEN 'Canceled'
        WHEN 4 THEN 'In Progress'
        ELSE 'Unknown'
    END AS RunStatus,
    h.message AS Message
FROM msdb.dbo.sysjobhistory h
JOIN msdb.dbo.sysjobs j ON h.job_id = j.job_id
order by RunDate, RunTime
asc

GO 

select * from   dbo.vw_JobHistory


