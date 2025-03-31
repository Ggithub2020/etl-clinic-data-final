
USE [DWClinicReportDataGirum]; -- Ensure you're in the correct database  
GO  

-- Drop the view if it exists  
IF OBJECT_ID('dbo.vw_ETLLog', 'V') IS NOT NULL  
    DROP VIEW dbo.vw_ETLLog;  
GO  

-- Create or Alter the view  
CREATE OR ALTER VIEW dbo.vw_ETLLog AS  
SELECT * FROM dbo.ETLLog;  
GO  

-- Test the view  
SELECT * FROM dbo.vw_ETLLog;  
