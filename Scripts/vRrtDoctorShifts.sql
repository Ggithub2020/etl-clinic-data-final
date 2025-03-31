
If (OBJECT_ID('vRrtDoctorShifts') is not null) Drop View vRrtDoctorShifts;
go

CREATE OR ALTER VIEW vRrtDoctorShifts 
AS  
SELECT  
    CAST(CAST(d.FullDate AS DATE) AS VARCHAR(100)) AS ShiftDate,  
    c.ClinicName,  
    c.ClinicCity,  
    c.ClinicState,  
    s.ShiftID,  
    s.ShiftStart,  
    s.ShiftEnd,  
    doc.DoctorFullName,  
    ABS(fds.HoursWorked) AS HoursWorked  
FROM FactDoctorShifts AS fds  
JOIN DimDates AS d ON fds.ShiftDateKey = d.DateKey  
JOIN DimClinics AS c ON fds.ClinicKey = c.ClinicKey  
JOIN DimShifts AS s ON fds.ShiftKey = s.ShiftKey  
JOIN DimDoctors AS doc ON fds.DoctorKey = doc.DoctorKey;


--select * from  vRrtDoctorShifts