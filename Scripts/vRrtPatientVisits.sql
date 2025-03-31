If (OBJECT_ID('vRrtPatientVisits') is not null) Drop View vRrtPatientVisits;
go

CREATE OR ALTER VIEW vRrtPatientVisits AS  
SELECT  
    CAST(CAST(d.FullDate AS DATE) AS VARCHAR(100)) AS VisitDate,  
    c.ClinicName,  
    c.ClinicCity,  
    c.ClinicState,  
    p.PatientFullName,  
    doc.DoctorFullName,  
    pr.ProcedureName,  
    ABS(fv.ProcedureVistCharge) AS ProcedureVistCharge  
FROM FactVisits AS fv  
JOIN DimDates AS d ON fv.DateKey = d.DateKey  
JOIN DimClinics AS c ON fv.ClinicKey = c.ClinicKey  
JOIN DimPatients AS p ON fv.PatientKey = p.PatientKey  
JOIN DimDoctors AS doc ON fv.DoctorKey = doc.DoctorKey  
JOIN DimProcedures AS pr ON fv.ProcedureKey = pr.ProcedureKey;

--select * from vRrtPatientVisits

