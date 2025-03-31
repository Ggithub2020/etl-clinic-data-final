--*************************************************************************--
-- Title: ETL Final Project---ETLFinal_DW_ETL Script_GObse
-- Author: Girum.Obse
-- Change Log: When,Who,What
-- 03/10/2025,GObse,Created File

--**************************************************************************--
USE [DWClinicReportDataGirum];
go
SET NoCount ON;

--  Setup Logging Objects ----------------------------------------------------

--********************************************************************--
--  Create ETL logging objects. Use these in your ETL stored procedures!
--********************************************************************--
If NOT Exists(Select * From Sys.tables where Name = 'ETLLog')
  Create -- Drop
  Table ETLLog
  (ETLLogID int identity Primary Key
  ,ETLDateAndTime datetime Default GetDate()
  ,ETLAction varchar(100)
  ,ETLLogMessage varchar(2000)
  );
go

Create or Alter View vETLLog
As
  Select
   ETLLogID
  ,ETLDate = Format(ETLDateAndTime, 'D', 'en-us')
  ,ETLTime = Format(Cast(ETLDateAndTime as datetime2), 'HH:mm', 'en-us')
  ,ETLAction
  ,ETLLogMessage
  From ETLLog;
go


Create or Alter Proc pInsETLLog
 (@ETLAction varchar(100), @ETLLogMessage varchar(2000))
--*************************************************************************--
-- Desc:This Sproc creates an admin table for logging ETL metadata. 
-- Change Log: When,Who,What
-- 03/10/2025,GObse,Created Sproc
--*************************************************************************--
As
Begin
  Declare @RC int = 0;
  Begin Try
    Begin Tran;
      Insert Into ETLLog
       (ETLAction,ETLLogMessage)
      Values
       (@ETLAction,@ETLLogMessage)
    Commit Tran;
    Set @RC = 1;
  End Try
  Begin Catch
    If @@TRANCOUNT > 0 Rollback Tran;
    Set @RC = -1;
  End Catch
  Return @RC;
End
Go
--select * from ETLLog

--********************************************************************--
-- A) Drop the FOREIGN KEY CONSTRAINTS and Clear the tables
 -- NOT NEEDED FOR INCREMENTAL LOADING: 
--********************************************************************--

--********************************************************************--
-- Pre-Load Tasks: Drop foreign key constraints and clear tables
--********************************************************************--
go
Create or Alter Procedure pETLDropForeignKeyConstraints
/* Desc: Removed FKs before truncation of the tables
** Change Log: When,Who,What
** 20251503,Girum,Created Sproc.
*/
AS
 Begin
  Declare @RC int = 0;
  Begin Try

    -- ETL Processing Code --
    Alter Table [dbo].[FactDoctorShifts] 
     Drop Constraint [fkFactDoctorShiftsToDimClinics] 

    Alter Table [dbo].[FactDoctorShifts] 
     Drop Constraint [fkFactDoctorShiftsToDimShifts]

    Alter Table [dbo].[FactDoctorShifts] 
     Drop Constraint [fkFactDoctorShiftsToDimDoctors]

	Alter Table [dbo].[FactDoctorShifts]
	 Drop Constraint [fkFactDoctorShiftsToDimDates]

	Alter Table [dbo].[FactVisits]
	  Drop Constraint  [fkFactVisitsToDimDates]
	
	Alter Table [dbo].[FactVisits]
	  Drop Constraint [fkFactVisitsToDimClinics]

----Alter Table [dbo].[FactVisits]                 SCD Type 2--keep Foreign Key as we dont Truncate the table
----  Drop Constraint [fkFactVisitsToDimPatients]  SCD Type 2--keep Foreign Key as we dont truncate the table
    Alter Table [dbo].[FactVisits]
	  Drop Constraint [fkFactVisitsToDimDoctors]

	Alter Table [dbo].[FactVisits]
	  Drop Constraint [fkFactVisitsToDimProcedures]

    Exec pInsETLLog
	        @ETLAction = 'pETLDropForeignKeyConstraints'
	       ,@ETLLogMessage = 'Foreign Keys dropped';
    Set @RC = +1
  End Try
  Begin Catch
     Declare @ErrorMessage nvarchar(1000) = Error_Message();
	 Exec pInsETLLog 
	      @ETLAction = 'pETLDropForeignKeyConstraints'
	     ,@ETLLogMessage = 'Foreign Keys cannot be dropped (They may be missing or misnamed)';
    Set @RC = -1
  End Catch
  Return @RC;
 End
go
/* Testing Code:
 Declare @Status int;
 Exec @Status = pETLDropForeignKeyConstraints;
 Print @Status;
 Select * From vETLLog;
*/go


Create or Alter Procedure pETLTruncateTables
/* Desc: Flushes all date from the tables
** Change Log: When,Who,What
** 20251503 ,GObse,Created Sproc.
*/
AS
 Begin
  Declare @RC int = 0;
  Begin Try

    -- ETL Processing Code --
    Truncate Table [DWClinicReportDataGirum].[dbo].[DimClinics];
	Truncate Table [DWClinicReportDataGirum].[dbo].[DimDates];
	Truncate Table [DWClinicReportDataGirum].[dbo].[DimDoctors];
--Truncate Table [DWClinicReportDataGirum].[dbo].[DimPatients]; SCD Type 2 keep DimPatients Table for historical data
	Truncate Table [DWClinicReportDataGirum].[dbo].[DimProcedures];
	Truncate Table [DWClinicReportDataGirum].[dbo].[DimShifts];
	Truncate Table [DWClinicReportDataGirum].[dbo].[FactDoctorShifts];
	Truncate Table [DWClinicReportDataGirum].[dbo].[FactVisits];

    Exec pInsETLLog
	        @ETLAction = 'pETLTruncateTables'
	       ,@ETLLogMessage = 'Tables data removed';
    Set @RC = +1
  End Try
  Begin Catch
     Declare @ErrorMessage nvarchar(1000) = Error_Message();
	 Exec pInsETLLog 
	      @ETLAction = 'pETLTruncateTables'
	     ,@ETLLogMessage = @ErrorMessage;
    Set @RC = -1
  End Catch
  Return @RC;
 End
go
/* Testing Code:
 Declare @Status int;
 Exec @Status = pETLTruncateTables;
 Print @Status;
 Select * From vETLLog;
*/
go


--********************************************************************--
-- B) FILL the Tables
--********************************************************************--



/****** [dbo].[DimDates] ******/

Create or Alter Procedure pETLFillDimDates
/* Desc: Inserts data Into DimDates
** Change Log: When,Who,What
** 20200117,RRoot,Created Sproc.
*/
AS
 Begin
  Declare @RC int = 0;
  Begin Try

    -- ETL Processing Code --
      Declare @StartDate datetime = '01/01/2005'
      Declare @EndDate datetime = '12/31/2025' 
      Declare @DateInProcess datetime  = @StartDate
      -- Loop through the dates until you reach the end date
       Begin Tran
      While @DateInProcess <= @EndDate
       Begin
       -- Add a row Into the date dimension table for this date
       Insert Into DimDates 
       ( [DateKey], [FullDate],[FullDateName],[MonthID],[MonthName],[YearID],[YearName])
       Values ( 
         Cast(Convert(nVarchar(50), @DateInProcess, 112) as int) -- [DateKey]
        ,@DateInProcess -- [FullDate]
        ,DateName(weekday, @DateInProcess) + ', ' + Convert(nVarchar(50), @DateInProcess, 110) -- [DateName]  
        ,Cast(Left(Convert(nVarchar(50), @DateInProcess, 112), 6) as int)  -- [MonthID]
        ,DateName(month, @DateInProcess) + ' - ' + DateName(YYYY,@DateInProcess) -- [MonthName]
        ,Year(@DateInProcess) -- [YearID] 
        ,Cast(Year(@DateInProcess ) as nVarchar(50)) -- [YearName] 
        )  
       -- Add a day and loop again
       Set @DateInProcess = DateAdd(d, 1, @DateInProcess)
       End
	   Commit Tran

    Exec pInsETLLog
	        @ETLAction = 'pETLFillDimDates'
	       ,@ETLLogMessage = 'DimDates filled';
    Set @RC = +1
  End Try
  Begin Catch
     If @@TRANCOUNT > 0 Rollback Tran;
     Declare @ErrorMessage nvarchar(1000) = Error_Message();
	 Exec pInsETLLog 
	      @ETLAction = 'pETLFillDimDates'
	     ,@ETLLogMessage = @ErrorMessage;
    Set @RC = -1
  End Catch
  Return @RC;
 End
go



SET IDENTITY_INSERT DimDates ON;-----If  need to manually insert specific  values otherwise turn it OFF*/
/* Testing Code:
 Declare @Status int;
 Exec @Status = pETLFillDimDates;
 Print @Status;
 Select * From DimDates;
 Select * From vETLLog;
*/
go



/****** [dbo].[DimClinics]******/
go 
Create or Alter View vETLDimClinics
/* Desc: Extracts and transforms data for DimProducts
** Change Log: When,Who,What
** 20251503,GObse,Created View.
*/
As
  Select [ClinicID]= [ClinicID] *100  ,[ClinicName] ,[City]  As[ClinicCity] ,[State] As[ClinicState] ,[Zip]   As[ClinicZip] From [DoctorsSchedules].[dbo].[Clinics]

go
/* Testing Code:
 Select * From vETLDimClinics;
*/

go
Create or Alter Procedure pETLDimClinics
/* Desc: Inserts data Into DimClinics using the vETLDimClinics view
** Change Log: When,Who,What
** 20251503,GObse,Created Sproc.
*/
AS
 Begin
  Declare @RC int = 0;
  Begin Try

    -- ETL Processing Code --
    If ((Select Count(*) From DimClinics) = 0)
     Begin Tran
      Insert Into [DWClinicReportDataGirum].[dbo].[DimClinics]
      ( [ClinicID]
	  , [ClinicName]
	  , [ClinicCity]
	  , [ClinicState]
	  , [ClinicZip]
	   )
      Select 
	    [ClinicID]
	  , [ClinicName]
	  , [ClinicCity]
	  , [ClinicState]
	  , [ClinicZip]
       
      FROM [dbo].[vETLDimClinics]
    Commit Tran

    Exec pInsETLLog
	        @ETLAction = 'pETLDimClinics'
	       ,@ETLLogMessage = 'DimClinics filled';
    Set @RC = +1
  End Try
  Begin Catch
     If @@TRANCOUNT > 0 Rollback Tran;
     Declare @ErrorMessage nvarchar(1000) = Error_Message();
	 Exec pInsETLLog 
	      @ETLAction = 'pETLDimClinics'
	     ,@ETLLogMessage = @ErrorMessage;
    Set @RC = -1
  End Catch
  Return @RC;
 End
go
/* Testing Code:
 Declare @Status int;
 Exec @Status = pETLDimClinics;
 Print @Status;
 Select * From DimClinics;
 Select * From vETLLog;
*/

execute pETLDimClinics;

/****** [dbo].[DimDoctors]******/
go 
Create or Alter View vETLDimDoctors
/* Desc: Extracts and transforms data for DimDoctors
** Change Log: When,Who,What
** 20251503,GObse,Created View.
*/
As
  Select  [DoctorID]
        , [DoctorFullName] = Cast( [FirstName] + ' ' +[LastName] As nvarchar(200))
        , [EmailAddress] As [DoctorEmailAddress]
        , [City]         As [DoctorCity]
        , [State]        As [DoctorState]
        , [Zip]          As [DoctorZip]
  From  [DoctorsSchedules].[dbo].[Doctors]

go
/* Testing Code:
 Select * From vETLDimDoctors;
*/

go
Create or Alter Procedure pETLDimDoctors
/* Desc: Inserts data Into DimDoctors using the vETLDimDoctors view
** Change Log: When,Who,What
** 20251503,GObse,Created Sproc.
*/
AS
 Begin
  Declare @RC int = 0;
  Begin Try

    -- ETL Processing Code --
    If ((Select Count(*) From DimDoctors) = 0)
     Begin Tran
      Insert Into [DWClinicReportDataGirum].[dbo].[DimDoctors]
	   ([DoctorID]
	  , [DoctorFullName]
	  , [DoctorEmailAddress]
	  , [DoctorCity]
	  , [DoctorState]
	  , [DoctorZip]
	   )
      Select 
	    [DoctorID]
	   ,[DoctorFullName]
	   ,[DoctorEmailAddress]
	   ,[DoctorCity]
	   ,[DoctorState]
	   ,[DoctorZip]
       
      FROM [dbo].[vETLDimDoctors]
    Commit Tran

    Exec pInsETLLog
	        @ETLAction = 'pETLDimDoctors'
	       ,@ETLLogMessage = 'DimDoctors filled';
    Set @RC = +1
  End Try
  Begin Catch
     If @@TRANCOUNT > 0 Rollback Tran;
     Declare @ErrorMessage nvarchar(1000) = Error_Message();
	 Exec pInsETLLog 
	      @ETLAction = 'pETLDimDoctors'
	     ,@ETLLogMessage = @ErrorMessage;
    Set @RC = -1
  End Catch
  Return @RC;
 End
go
/* Testing Code:
 Declare @Status int;
 Exec @Status = pETLDimDoctors;
 Print @Status;
 Select * From DimDoctors;
 Select * From vETLLog;
*/



/****** [dbo].[DimProcedures]******/
go 
Create or Alter View vETLDimProcedures
/* Desc: Extracts and transforms data for DimProcedures
** Change Log: When,Who,What
** 20251503,GObse,Created view.
*/
As
  Select  [ID] As[ProcedureID], [Name] As [ProcedureName], [Desc] As[ProcedureDesc], [Charge] As[ProcedureCharge]
  From  [Patients].[dbo].[Procedures]

go
/* Testing Code:
 Select * From vETLDimProcedures;
*/

go
Create or Alter Procedure pETLDimProcedures
/* Desc: Inserts data Into DimProcedures using the vETLDimProcedures view
** Change Log: When,Who,What
** 20251503,GObse,Created Sproc.
*/
AS
 Begin
  Declare @RC int = 0;
  Begin Try

    -- ETL Processing Code --
    If ((Select Count(*) From DimProcedures) = 0)
     Begin Tran
      Insert Into [DWClinicReportDataGirum].[dbo].[DimProcedures]
	   ([ProcedureID]
	   , [ProcedureName]
	   , [ProcedureDesc]
	   , [ProcedureCharge]
	   )
      Select 
	    [ProcedureID]
	   , [ProcedureName]
	   , [ProcedureDesc]
	   , [ProcedureCharge]
       
      FROM vETLDimProcedures
    Commit Tran

    Exec pInsETLLog
	        @ETLAction = 'pETLDimProcedures'
	       ,@ETLLogMessage = 'DimProcedures filled';
    Set @RC = +1
  End Try
  Begin Catch
     If @@TRANCOUNT > 0 Rollback Tran;
     Declare @ErrorMessage nvarchar(1000) = Error_Message();
	 Exec pInsETLLog 
	      @ETLAction = 'pETLDimProcedures'
	     ,@ETLLogMessage = @ErrorMessage;
    Set @RC = -1
  End Catch
  Return @RC;
 End
go
/* Testing Code:
 Declare @Status int;
 Exec @Status = pETLDimProcedures;
 Print @Status;
 Select * From DimProcedures;
 Select * From vETLLog;
*/



/****** [dbo].[DimShifts]******/

Create or Alter View vETLDimShifts
/* Desc: Extracts and transforms data for DimShifts
** Change Log: When,Who,What
** 20251503,GObse,Created Sproc.
*/
As
  Select  [ShiftID], [ShiftStart], [ShiftEnd]
  From [DoctorsSchedules].[dbo].[Shifts]

go
/* Testing Code:
 Select * From vETLDimShifts;
*/

Create or Alter Procedure pETLDimShifts
/* Desc: Inserts data Into DimShifts using the vETLDimShifts view
** Change Log: When,Who,What
** 20251503,GObse,Created Sproc.
*/
AS
 Begin
  Declare @RC int = 0;
  Begin Try

    -- ETL Processing Code --
    If ((Select Count(*) From DimShifts) = 0)
     Begin Tran
      Insert Into [DWClinicReportDataGirum].[dbo].[DimShifts]
	   ([ShiftID]
	   , [ShiftStart]
	   , [ShiftEnd]
	   )
      Select 
	      [ShiftID]
		, [ShiftStart]
		, [ShiftEnd] 
      FROM vETLDimShifts
    Commit Tran

    Exec pInsETLLog
	        @ETLAction = 'pETLDimShifts'
	       ,@ETLLogMessage = 'DimDimShifts filled';
    Set @RC = +1
  End Try
  Begin Catch
     If @@TRANCOUNT > 0 Rollback Tran;
     Declare @ErrorMessage nvarchar(1000) = Error_Message();
	 Exec pInsETLLog 
	      @ETLAction = 'pETLDimShifts'
	     ,@ETLLogMessage = @ErrorMessage;
    Set @RC = -1
  End Catch
  Return @RC;
 End
go
/* Testing Code:
 Declare @Status int;
 Exec @Status = pETLDimShifts;
 Print @Status;
 Select * From DimShifts;
 Select * From vETLLog;
*/

/****** [dbo].[DimPatients] ******/
go 
Create or Alter View vETLDimPatients
/* Author: GObse
** Desc: Extracts and transforms data for DimProducts
** Change Log: When,Who,What
** 20251503,GObse,Created view.
*/
As
  Select
       [ID] As [PatientID]
      ,[PatientFullName] = Cast([FName]+ ' ' +[LName]  As varchar(100))
      ,[PatientCity] = Cast([City] As varchar(100))
      ,[PatientState] = Cast([State] As Varchar(100)) 
      ,[ZipCode] As [PatientZipCode]
  From [Patients].[dbo].[Patients]

go
/* Testing Code:
 Select * From vETLDimPatients;
*/

go
Create or Alter Procedure pETLDimPatients
/* Author: Girum
** Desc: Updates data in DimPatients using the vETLDimPatients view
** Change Log: When,Who,What
** 2025-03-15,Girum,Created Sproc.
*/
AS
 Begin
  Declare @ReturnCode int = 0;
  Begin Try
    -- ETL Processing Code --
 
    Begin Tran;
      -- 1) For UPDATE: Change the EndDate and IsCurrent on any added rows
      -- NOTE: Performing the Update before an Insert makes the coding eaiser since there is only one current version of the data      
      With ChangedPatients 
      As(
         Select[PatientID], [PatientFullName], [PatientCity], [PatientState], [PatientZipCode] From vETLDimPatients
         Except
         Select[PatientID], [PatientFullName], [PatientCity], [PatientState], [PatientZipCode] From DimPatients
           Where IsCurrent = 1 -- Needed if the value is changed back to previous value
        ) UPDATE [DWClinicReportDataGirum].[dbo].[DimPatients]
           SET EndDate = Cast(Convert(nvarchar(50), GetDate(), 112) as date)
              ,IsCurrent = 0
           WHERE PatientID IN (Select PatientID From ChangedPatients)
           ;

      -- 2)For INSERT or UPDATES: Add new rows to the table
      With AddedORChangedPatients 
        As(
           Select[PatientID], [PatientFullName], [PatientCity], [PatientState], [PatientZipCode] From vETLDimPatients
         Except
         Select[PatientID], [PatientFullName], [PatientCity], [PatientState], [PatientZipCode] From DimPatients
           Where IsCurrent = 1 -- Needed if the value is changed back to previous value
          ) INSERT INTO [DWClinicReportDataGirum].[dbo].[DimPatients]
            ([PatientID], [PatientFullName], [PatientCity], [PatientState], [PatientZipCode], [StartDate], [EndDate], [IsCurrent])
            SELECT
              [PatientID]
			 ,[PatientFullName]
			 ,[PatientCity]
			 ,[PatientState]
			 ,[PatientZipCode]
             ,[StartDate] = Cast(Convert(nvarchar(50), GetDate(), 112) as date)
             ,[EndDate] = Null
             ,[IsCurrent] = 1
            FROM vETLDimPatients
            WHERE PatientID IN (Select PatientID From AddedORChangedPatients)
            ;

      -- 3) For Delete: Change the IsCurrent status to zero
      With DeletedPatients
          As(
              Select[PatientID], [PatientFullName], [PatientCity], [PatientState], [PatientZipCode] From DimPatients
                Where IsCurrent = 1 -- We do not care about row already marked zero!
              Except            			
              Select[PatientID], [PatientFullName], [PatientCity], [PatientState], [PatientZipCode] From vETLDimPatients
            ) UPDATE [DWClinicReportDataGirum].[dbo].[DimPatients]
                SET EndDate = Cast(Convert(nvarchar(50), GetDate(), 112) as date)
                   ,IsCurrent = 0
                WHERE PatientID IN (Select PatientID From DeletedPatients)
                ;
     Commit Tran;


    -- ETL Logging Code --
    Exec pInsETLLog
	        @ETLAction = ' pETLDimPatients'
	       ,@ETLLogMessage = 'DimPatients synced';
    Set @ReturnCode = +1
  End Try
  Begin Catch
     Declare @ErrorMessage nvarchar(1000) = Error_Message();
	 Exec pInsETLLog 
	      @ETLAction = 'pETLDimPatients'
	     ,@ETLLogMessage = @ErrorMessage;
    Set @ReturnCode = -1
  End Catch
  Return @ReturnCode;
 End
go
/* Testing Code:
 Declare @Status int;
 Exec @Status = pETLDimPatients;
 Print @Status;
 Select * From DimPatients Order By PatientID
*/

---Since some doctors are missing, we need a placeholder record (DoctorKey = -1) in DimDoctors:



go

/****** [dbo].[FactVisits] ******/
CREATE OR ALTER VIEW vETLFactVisits  
AS  
SELECT  
    [VisitKey] = ps.ID,  
    [DateKey] = dda.[DateKey], 
    [ClinicKey] = dc.ClinicKey,  
    [PatientKey] = dpa.PatientKey,  
    [DoctorKey] = dd.DoctorKey,  
    [ProcedureKey] = dpr.ProcedureKey,  
    [ProcedureVistCharge] = ps.[Charge]  
FROM [Patients].[dbo].[Visits] AS ps  
LEFT JOIN [DWClinicReportDataGirum].[dbo].[DimDates] AS dda  
ON dda.[FullDate] = CAST(ps.[Date] AS DATE)
JOIN [DWClinicReportDataGirum].[dbo].[DimClinics] AS dc  
    ON dc.ClinicID = ps.[Clinic]    
JOIN [DWClinicReportDataGirum].[dbo].[DimPatients] AS dpa  
    ON dpa.PatientID = ps.Patient  
JOIN [DWClinicReportDataGirum].[dbo].[DimDoctors] AS dd   
    ON dd.DoctorID = ps.Doctor  
JOIN [DWClinicReportDataGirum].[dbo].[DimProcedures] AS dpr  
    ON dpr.ProcedureID = ps.[Procedure]  ;


/* Testing Code:
 Select * From vETLFactVisits;
*/


/* Desc: Inserts data Into FactSalesOrders using the vETLFactVisits view
** Change Log: When,Who,What
** 20250120,GObse,Created Sproc.
*/
Go
Create or Alter Procedure pETLFactVisits
AS
 Begin 
  Declare @RC int = 0;
  Begin Try

 Insert Into [DWClinicReportDataGirum].[dbo].[FactVisits]
  ( [VisitKey]
  , [DateKey]
 , [ClinicKey]
 , [PatientKey]
 , [DoctorKey]
 , [ProcedureKey]
 , [ProcedureVistCharge]
 )
 Select 
   [VisitKey]
 , [DateKey]
 , [ClinicKey]
 , [PatientKey]
 , [DoctorKey]
 , [ProcedureKey]
  , [ProcedureVistCharge]
  FROM vETLFactVisits

    Exec pInsETLLog
	        @ETLAction = 'pETLFactVisits'
	       ,@ETLLogMessage = 'FactVisits filled';
    Set @RC = +1
  End Try
  Begin Catch
     If @@TRANCOUNT > 0 Rollback Tran;
     Declare @ErrorMessage nvarchar(1000) = Error_Message();
	 Exec pInsETLLog 
	      @ETLAction = 'pETLFactVisits'
	     ,@ETLLogMessage = @ErrorMessage;
    Set @RC = -1
  End Catch
  Return @RC;
 End
 Go
/* Testing Code:
 Declare @Status int;
 Exec @Status = pETLFactVisits;
 Print @Status;
 Select * From FactVisits;
 Select * From vETLLog;
*/


/* Testing Code:
 Declare @Status int;
 Exec @Status = pETLFactVisits;
 Print @Status;
 Select * From FactVisits;
 Select * From vETLLog;
*/



/****** [dbo].[FactDoctorShifts] ******/

CREATE OR ALTER VIEW vFactDoctorShifts  
AS  
SELECT  
    [DoctorsShiftID] = dsh.DoctorsShiftID,  
    [ShiftDateKey] = CAST(CONVERT(NVARCHAR(50), dsh.ShiftDate, 112) AS INT),  
    [ClinicKey] = dc.ClinicKey,  
    [ShiftKey] = dss.ShiftKey,  
    [DoctorKey] = dd.DoctorKey,  
    [HoursWorked] = CAST(DATEDIFF(HOUR, ds.ShiftStart, ds.ShiftEnd) AS INT)  
FROM [DoctorsSchedules].[dbo].[DoctorShifts] AS dsh  
LEFT JOIN [DoctorsSchedules].[dbo].[Shifts] AS ds  
    ON ds.ShiftID = dsh.ShiftID  
LEFT JOIN [DWClinicReportDataGirum].[dbo].[DimDoctors] AS dd  
    ON dd.DoctorID = dsh.DoctorID  
LEFT JOIN [DWClinicReportDataGirum].[dbo].[DimClinics] AS dc  
    ON dc.ClinicID = dsh.ClinicID *100 -----got data type error and fixed
LEFT JOIN [DWClinicReportDataGirum].[dbo].[DimShifts] AS dss  
    ON dss.ShiftID = dsh.ShiftID;

/* Testing Code:
 Select * From vFactDoctorShifts;
*/
go
Create or Alter Procedure pFactDoctorShifts
/* Desc: Inserts data Into FactDoctorShifts using the vFactDoctorShifts view
** Change Log: When,Who,What
** 20251703,GObse,Created Sproc.
*/
AS
 Begin 
  Declare @RC int = 0;
  Begin Try

 Insert Into [DWClinicReportDataGirum].[dbo].[FactDoctorShifts]
  ([DoctorsShiftID]
  , [ShiftDateKey]
  , [ClinicKey]
  , [ShiftKey]
  , [DoctorKey]
  , [HoursWorked]
 )
 Select 
   [DoctorsShiftID]
  , [ShiftDateKey]
  , [ClinicKey]
  , [ShiftKey]
  , [DoctorKey]
  , [HoursWorked]
  FROM vFactDoctorShifts

    Exec pInsETLLog
	        @ETLAction = 'pFactDoctorShifts'
	       ,@ETLLogMessage = 'FactDoctorShifts filled';
    Set @RC = +1
  End Try
  Begin Catch
     If @@TRANCOUNT > 0 Rollback Tran;
     Declare @ErrorMessage nvarchar(1000) = Error_Message();
	 Exec pInsETLLog 
	      @ETLAction = 'pFactDoctorShifts'
	     ,@ETLLogMessage = @ErrorMessage;
    Set @RC = -1
  End Catch
  Return @RC;
 End
 Go
/* Testing Code:
 Declare @Status int;
 Exec @Status = pFactDoctorShifts;
 Print @Status;
 Select * From FactDoctorShifts;
 Select * From vETLLog;
*/


--********************************************************************--
-- Re-Create the FOREIGN KEY CONSTRAINTS
--********************************************************************--
-- 3) Re-Create the Foreign Key CONSTRAINTS
Create Or Alter Proc pETLAddForeignKeyConstraints
As
Begin
    Declare @RC int = 0; 
    Declare @ErrorMessage nvarchar(1000); -- Capture error messages

    Begin Try
        -- Start the transaction
        Begin Tran;

        -- Add foreign key constraints
        Alter Table [dbo].[FactDoctorShifts] 
            Add Constraint [fkFactDoctorShiftsToDimClinics] 
            FOREIGN KEY ([ClinicKey]) REFERENCES [dbo].[DimClinics]([ClinicKey]);

        Alter Table [dbo].[FactDoctorShifts] 
            Add Constraint [fkFactDoctorShiftsToDimDoctors] 
            FOREIGN KEY ([DoctorKey]) REFERENCES [dbo].[DimDoctors]([DoctorKey]);

        Alter Table [dbo].[FactDoctorShifts]
            Add Constraint [fkFactDoctorShiftsToDimDates] 
            FOREIGN KEY ([ShiftDateKey]) REFERENCES [dbo].[DimDates]([DateKey]);

        Alter Table [dbo].[FactVisits]
            Add Constraint [fkFactVisitsToDimDates] 
            FOREIGN KEY ([DateKey]) REFERENCES [dbo].[DimDates]([DateKey]);

        Alter Table [dbo].[FactVisits]
            Add Constraint [fkFactVisitsToDimClinics] 
            FOREIGN KEY ([ClinicKey]) REFERENCES [dbo].[DimClinics]([ClinicKey]);

        Alter Table [dbo].[FactVisits]
            Add Constraint [fkFactVisitsToDimDoctors] 
            FOREIGN KEY ([DoctorKey]) REFERENCES [dbo].[DimDoctors]([DoctorKey]);

        Alter Table [dbo].[FactVisits]
            Add Constraint [fkFactVisitsToDimProcedures] 
            FOREIGN KEY ([ProcedureKey]) REFERENCES [dbo].[DimProcedures]([ProcedureKey]);

        -- Commit transaction BEFORE calling the logging procedure
        Commit Tran;

        -- Log success AFTER committing the transaction
        Exec pInsETLLog
            @ETLAction = 'pETLAddForeignKeyConstraints',
            @ETLLogMessage = 'Foreign Key Constraints re-created';

        -- Set return code to success
        Set @RC = 1;
    End Try
    Begin Catch
        -- If there is an active transaction, rollback
        If @@TRANCOUNT > 0  
            Rollback Tran;

        -- Capture the error message
        Set @ErrorMessage = ERROR_MESSAGE();
        Print 'Error: ' + @ErrorMessage;  -- Debugging

        -- Set return code to failure
        Set @RC = -1;
    End Catch

    -- Return the status code
    Return @RC;
End;
Go


/* Testing Code:
 Declare @Status int;
 Exec @Status = pETLAddForeignKeyConstraints;
 Print @Status;
 Select * From vETLLog;
*/


--********************************************************************--
-- D) Review the results of this script
--********************************************************************--
go
Declare @Status int;
Exec @Status = pETLDropForeignKeyConstraints;
Select [Object] = 'pETLDropForeignKeyConstraints', [Status] = @Status;

Exec @Status = pETLTruncateTables;
Select [Object] = 'pETLTruncateTables', [Status] = @Status;

Exec @Status = pETLFillDimDates;
Select [Object] = 'pETLFillDimDates', [Status] = @Status;

Exec @Status = pETLDimClinics;
Select [Object] = 'pETLDimClinics', [Status] = @Status;

Exec @Status = pETLDimDoctors;
Select [Object] = 'pETLDimDoctors', [Status] = @Status;

Exec @Status = pETLDimProcedures;
Select [Object] = 'pETLDimProcedures', [Status] = @Status;


Exec @Status = pETLDimShifts;
Select [Object] = 'pETLDimShifts', [Status] = @Status;

Exec @Status = pETLDimPatients;
Select [Object] = 'pETLDimPatients', [Status] = @Status;

Exec @Status = pETLFactVisits;
Select [Object] = 'pETLFactVisits', [Status] = @Status;


Exec @Status = pFactDoctorShifts;
Select [Object] = 'pFactDoctorShifts', [Status] = @Status;


Exec @Status = pETLAddForeignKeyConstraints;
Select [Object] = 'pETLAddForeignKeyConstraints', [Status] = @Status;

go

select * from [dbo].[DimClinics]
select * from [dbo].[DimDates]
select * from [dbo].[DimDoctors]
select * from [dbo].[DimPatients]
select * from [dbo].[DimProcedures]
select * from [dbo].[DimShifts]
select * from [dbo].[FactDoctorShifts]
select * from [dbo].[FactVisits]
Select * From vETLLog;



















































































































































































































































































































































































































































































































































































































