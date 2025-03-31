/***********************************************************************************************************
======================================================
Description: This script is a demo ETL process for BI ETL Final Milestone 01.
Developer  : GObse
Date       : 03/05/2025
Change Log : (Date, Author, Description)
======================================================
03/04/2025, GObse, Created initial version of the ETL script.
======================================================

*************************************************************************************************************************************************/
Set NoCount ON; --Turn of the (4 rows affected) messages
-----Create the staging tables
------------------------------------------------------------------------------------------------------------------------------------------------

Use tempdb;
go
create or Alter proc pETLCreateStagingTables
As
/**********************************************************************************************************************************************
Desc: Creates Staging Tables for File Import
Dev:GObse
Date: 03/04/2025
Change Log: (when, Who, What)
********************************************************************************************************************************************/
Begin 
 Declare @RC int =0;
   Begin Try
       If (select object_ID('StagingBellevueNewPatients')) is Not Null
	       Drop Table  StagingBellevueNewPatients;
		   Create Table StagingBellevueNewPatients
		   ([FName] nvarchar (100)
		   ,[LName] nvarchar(100)
		   ,[Email] nvarchar(100)
		   ,[Address] nvarchar(100)
		   ,[City] nvarchar(100)
		   ,[State] nvarchar(100)
		   ,[ZipCode] nvarchar(100)
		   );

		   If (select object_ID('StagingBellevueVisits')) is Not Null
		   Drop Table  StagingBellevueVisits;
		   Create Table StagingBellevueVisits
		   ([Time] nvarchar(100)
		   ,[Patient] nvarchar(100)
		   --,[Clinic] nvarchar(100) ----- This data is missing in th file.
		   ,[Doctor] nvarchar(100)
		   ,[Procedure] nvarchar(100)
		   ,[Charge] nvarchar(100)
		   );

		   If (select object_ID('StagingKirklandNewPatients')) is Not Null
	       Drop Table  StagingKirklandNewPatients;
		   Create Table StagingKirklandNewPatients
		   ([FName] nvarchar (100)
		   ,[LName] nvarchar(100)
		   ,[Email] nvarchar(100)
		   ,[Address] nvarchar(100)
		   ,[City] nvarchar(100)
		   ,[State] nvarchar(100)
		   ,[ZipCode] nvarchar(100)
		   );

		   If (select object_ID('StagingKirklandVisits')) is Not Null
		   Drop Table  StagingKirklandVisits;
		   Create Table StagingKirklandVisits
		   ([Time] nvarchar(100)
		   ,[Patient] nvarchar(100)
		   ,[Clinic] nvarchar(100) 
		   ,[Doctor] nvarchar(100)
		   ,[Procedure] nvarchar(100)
		   ,[Charge] nvarchar(100)
		   );

		     If (select object_ID('StagingRedmondNewPatients')) is Not Null
	       Drop Table  StagingRedmondNewPatients;
		   Create Table StagingRedmondNewPatients
		   ([FName] nvarchar (100)
		   ,[LName] nvarchar(100)
		   ,[Email] nvarchar(100)
		   ,[Address] nvarchar(100)
		   ,[City] nvarchar(100)
		   ,[State] nvarchar(100)
		   ,[ZipCode] nvarchar(100)
		   );

		   If (select object_ID('StagingRedmondVisits')) is Not Null
		   Drop Table  StagingRedmondVisits;
		   Create Table StagingRedmondVisits
		   ([Time] nvarchar(100)
		   ,[Patient] nvarchar(100)
		   ,[Clinic] nvarchar(100) ----Different Column Order Issue
		   ,[Doctor] nvarchar(100) ----Different Column Order Issue
		   ,[Procedure] nvarchar(100)
		   ,[Charge] nvarchar(100)
		   );

		   set @RC = 1;
	End Try
	Begin Catch
	   print 'Error Creating Staging Tables for file Import'
	   print ERROR_MESSAGE()
	   Set @RC = -1
    End Catch
	Return @RC;
	End
	go
	Exec pETLCreateStagingTables;
	select [name], [crdate] From sysobjects where name Like 'Staging%'
	select * From StagingBellevueNewPatients
	select * From StagingBellevueVisits
	select * From StagingKirklandNewPatients
	select * From StagingKirklandVisits
	select * From StagingRedmondNewPatients
	select * From StagingRedmondVisits
	go


--Insert Data From Files --
---------------------------------------------------------------------------------------------------------------------------------
--Import a data file into a datbase table or view ina user specified formatin SQL server"
--use the link 
--   https://learn.microsoft.com/en-us/sql/t-sql/statements/bulk-insert-transact-sql?view=sql-server-ver16

Create or Alter proc pETLImportFileDataToStagingTables
As
/*****************************************************************************************************************************
Desc: Imports File Data to Staging Tables
Dev: GObse
Date 03/05/2025
Change Log: (when, who, what)
*************************************************************************************************************************************/
Begin 
     Declare @RC int = 0;
	 BEgin Try
	     Bulk Insert StagingBellevueNewPatients
		 From 'C:\__BISolutions\ClinicDailyData\Bellevue\20100102NewPatients.csv'
		   with
		   (DATAFILETYPE = 'char'
		   ,FORMAT = 'CSV'
		   ,ROWTERMINATOR = '\n'
		   ,FIRSTROW = 2
		   )

		    Bulk Insert StagingBellevueVisits
		    From 'C:\__BISolutions\ClinicDailyData\Bellevue\20100102Visits.csv'
		   with
		   (DATAFILETYPE = 'char'
		   ,FORMAT = 'CSV'
		   ,ROWTERMINATOR = '\n'
		   ,FIRSTROW = 2
		   )

		    Bulk Insert StagingKirklandNewPatients
		    From 'C:\__BISolutions\ClinicDailyData\Kirkland\20100102NewPatients.csv'
		   with
		   (DATAFILETYPE = 'char'
		   ,FORMAT = 'CSV'
		   ,ROWTERMINATOR = '\n'
		   ,FIRSTROW = 2
		   )

		    Bulk Insert StagingKirklandVisits
		    From 'C:\__BISolutions\ClinicDailyData\Kirkland\20100102Visits.csv'
		   with
		   (DATAFILETYPE = 'char'
		   ,FORMAT = 'CSV'
		   ,ROWTERMINATOR = '\n'
		   ,FIRSTROW = 2
		   )

		      Bulk Insert StagingRedmondNewPatients
		    From 'C:\__BISolutions\ClinicDailyData\Redmond\20100102NewPatients.csv'
		   with
		   (DATAFILETYPE = 'char'
		   ,FORMAT = 'CSV'
		   ,ROWTERMINATOR = '\n'
		   ,FIRSTROW = 2
		   )

		     Bulk Insert StagingRedmondVisits
		    From 'C:\__BISolutions\ClinicDailyData\Redmond\20100102Visits.csv'
		   with
		   (DATAFILETYPE = 'char'
		   ,FORMAT = 'CSV'
		   ,ROWTERMINATOR = '\n'
		   ,FIRSTROW = 2
		   )

		set @RC = 1;
 End Try
 Begin Catch
       Print 'Error Importing File Data to Staging Tables'
	   Print ERROR_MESSAGE()
	   Set @RC = -1
End Catch
Return @RC;
End
go
Exec pETLImportFileDataToStagingTables;
go

--Review the data---
-----------------------------------------------------------------------------------------------------------------------------------
    select * From StagingBellevueNewPatients
	select * From StagingBellevueVisits
	select * From StagingKirklandNewPatients
	select * From StagingKirklandVisits
	select * From StagingRedmondNewPatients
    select * From StagingRedmondVisits

----Transforms the new data --
go
create or Alter proc pETLTransformVistsData
As
/***********************************************************************************************************************************
Desc: Transforms Data in Staging Tables
Dev: GObse
Date:03/05/2025
Change Log: (when, who, what)
********************************************************************************************************************************/
Begin 
   Declare @RC int =0
   Begin Try 
     Update [tempdb].[dbo].[StagingBellevueNewPatients] ---Bellevue
	 set [Email] = [Email] + ' (Invalid) '
	 Where (patIndex( '%@%', [Email]) = 0);

	 Update [tempdb].[dbo].[StagingKirklandNewPatients] ---Kirkland
	 set [Email] = [Email] + ' (Invalid) '
	 Where (patIndex( '%@%', [Email]) = 0);

	 Update [tempdb].[dbo].[StagingRedmondNewPatients] ---Redmond
	 set [Email] = [Email] + ' (Invalid) '
	 Where (patIndex( '%@%', [Email]) = 0);
	 set @RC = 1;
	End Try
	Begin Catch
	      print  'Error Importing File Data to Staging Tables'
		  print ERROR_MESSAGE()
		  Set @RC = -1;
	End Catch
	Return @RC
	End
	go
	Exec pETLTransformVistsData
	go
	Select * from StagingBellevueNewPatients
	Select * from StagingKirklandNewPatients
	Select * from StagingRedmondNewPatients
	go

	create or Alter Proc pETLSelectVistsData -- This could also be a view or function
	(@Date date)
	As
	/*****************************************************************************************************************************
	Desc: Selects data from staging tables , adds a data , combines the results for all visits.
	Dev: GObse
	Date: 03/05/2025
	Change Log: (when, Who, What)
	*********************************************************************************************************************************/
	Begin 
	   Declare @RC int = 0;
	   Begin Try
	     Select 
		 [Date] = cast(@Date as datetime) + Cast([Time] as datetime)
		,[Clinic] = 100 --Adding missing Clinic ID
		,[Patient]
		,[Doctor]
		,[Procedure]
		,[Charge]
		From StagingBellevueVisits
		Union --combine Bellevue and Redmon data
		Select
		[Date] = cast(@Date as datetime) + Cast([Time] as datetime)
	   ,[Clinic] = [Clinic] *100
	   ,[Patient]
	   ,[Doctor]
	   ,[Procedure]
	   ,[Charge]
	   From StagingRedmondVisits
	   Union --now add kirkland data
	   Select
	   [Date] = cast(@Date as datetime) + Cast([Time] as datetime)
	   ,[Clinic] = [Clinic] *100
	   ,[Patient]
	   ,[Doctor]
	   ,[Procedure]
	   ,[Charge]
	    From StagingKirklandVisits
		Except --subtract what is already in the visits table
		select
		 [Date]
		,[Clinic] 
	    ,[Patient]
	    ,[Doctor]
	    ,[Procedure]
	    ,[Charge]
		From [Patients].[dbo].[Visits]
		Order By [Date],[Clinic];
		Set @RC = 1
		;
	End Try
	Begin catch
	  Rollback Tran;
	  print 'Error Inserting Data from Staging Tables into Visits'
	  Print ERROR_MESSAGE()
	  Set @RC = -1
	  End Catch 
	  Return @RC
	End
	go
	Exec pETLSelectVistsData @date = '20100102';  --If you get zero row the data has already been imported
	go


	Create or Alter Proc pETLInsertVisitsData
	(@Date date)
	As
	/***************************************************************************************************************************
	Desc: Inserts Data from Staging Tables into Visits
	Dev:GObse
	Date:03/05/2025
*********************************************************************************************************************************/
Begin
   Declare @RC int =0;
   Begin Try
   Begin Tran;
   Insert Into [Patients].[dbo].[Visits]
   ([Date],[Clinic],[Patient],[Doctor],[Procedure],[Charge])
   Exec pETLSelectVistsData @Date = @Date --using my select sproc
   Commit Tran;
   Set @RC = 1;
   End Try
   Begin Catch
     Rollback Tran;
	 Print 'Error Inserting Data from Staging Tables into Visits'
	 Print ERROR_MESSAGE()
	 Set @RC = -1;
    End Catch
	Return @RC;
 End
 go
 Exec pETLSelectVistsData @Date = '20100102'
 go

 --Test Code--
 USE [master]
 go
 -- reset the database
 ALTER DATABASE [patients] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
 RESTORE DATABASE [Patients]
  FROM DISK = N'C:/_BISOLUTIONS/Databases/Patients.bak'
  WITH RECOVERY, REPLACE;
 ALTER DATABASE [Patients] SET MULTI_user;
 go
 Select Count(*) From [Patients].[dbo].[Visits] --40150
 go
 Use tempdb;
 go
 Exec pETLCreateStagingTables
 go
 Exec pETLImportFileDataToStagingTables
 go
 Exec pETLTransformVistsData
 go
 Exec pETLInsertVisitsData @Date = '20100102'
 go
 Select Count(*) From [Patients].[dbo].[Visits] --40304
 go





