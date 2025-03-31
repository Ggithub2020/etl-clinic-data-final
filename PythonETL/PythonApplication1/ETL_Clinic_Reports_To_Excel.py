
import os
import pyodbc
from datetime import datetime
from openpyxl import Workbook

# Database connection parameters
server = 'localhost\GMSSQLSERVER_DEV'  # Your SQL Server name
database = 'DWClinicReportDataGirum'  # Your database name

# Define the folder path where the Excel file will be saved
reports_folder = r"C:\__BISolutions\UWETLFinalGirumObse\Reports"

# Get the current date in the format YYYY-MM-DD
current_date = datetime.now().strftime("%Y-%m-%d")

# Construct the full file path for the Excel file
file_path = os.path.join(reports_folder, f"ClinicReportsData_{current_date}.xlsx")

# Establish the database connection using Windows authentication
conn = pyodbc.connect(f'DRIVER={{SQL Server}};SERVER={server};DATABASE={database};Trusted_Connection=yes;')
cursor = conn.cursor()

# Query to get Doctor Shift data from the vRrtDoctorShifts view
doctor_shifts_query = """
SELECT ShiftDate, ClinicName, ClinicCity, ClinicState, ShiftID, ShiftStart, ShiftEnd, DoctorFullName, HoursWorked
FROM vRrtDoctorShifts
"""

# Query to get Patient Visit data from the vRrtPatientVisits view
patient_visits_query = """
SELECT VisitDate, ClinicName, ClinicCity, ClinicState, PatientFullName, DoctorFullName, ProcedureName, ProcedureVistCharge
FROM vRrtPatientVisits
"""

# Execute the queries
cursor.execute(doctor_shifts_query)
doctor_shifts_data = cursor.fetchall()

cursor.execute(patient_visits_query)
patient_visits_data = cursor.fetchall()

# Create a new Excel workbook
workbook = Workbook()

# Create the first sheet for Doctor Shifts
sheet1 = workbook.active
sheet1.title = "DoctorShifts"

# Set column headers for DoctorShifts sheet
sheet1["A1"] = "ShiftDate"
sheet1["B1"] = "ClinicName"
sheet1["C1"] = "ClinicCity"
sheet1["D1"] = "ClinicState"
sheet1["E1"] = "ShiftID"
sheet1["F1"] = "ShiftStart"
sheet1["G1"] = "ShiftEnd"
sheet1["H1"] = "DoctorFullName"
sheet1["I1"] = "HoursWorked"

# Populate DoctorShifts data into the sheet
for row_num, row in enumerate(doctor_shifts_data, start=2):
    sheet1[f"A{row_num}"] = row.ShiftDate
    sheet1[f"B{row_num}"] = row.ClinicName
    sheet1[f"C{row_num}"] = row.ClinicCity
    sheet1[f"D{row_num}"] = row.ClinicState
    sheet1[f"E{row_num}"] = row.ShiftID
    sheet1[f"F{row_num}"] = row.ShiftStart
    sheet1[f"G{row_num}"] = row.ShiftEnd
    sheet1[f"H{row_num}"] = row.DoctorFullName
    sheet1[f"I{row_num}"] = row.HoursWorked

# Create the second sheet for Patient Visits
sheet2 = workbook.create_sheet("PatientVisits")

# Set column headers for PatientVisits sheet
sheet2["A1"] = "VisitDate"
sheet2["B1"] = "ClinicName"
sheet2["C1"] = "ClinicCity"
sheet2["D1"] = "ClinicState"
sheet2["E1"] = "PatientFullName"
sheet2["F1"] = "DoctorFullName"
sheet2["G1"] = "ProcedureName"
sheet2["H1"] = "ProcedureVistCharge"

# Populate PatientVisits data into the sheet
for row_num, row in enumerate(patient_visits_data, start=2):
    sheet2[f"A{row_num}"] = row.VisitDate
    sheet2[f"B{row_num}"] = row.ClinicName
    sheet2[f"C{row_num}"] = row.ClinicCity
    sheet2[f"D{row_num}"] = row.ClinicState
    sheet2[f"E{row_num}"] = row.PatientFullName
    sheet2[f"F{row_num}"] = row.DoctorFullName
    sheet2[f"G{row_num}"] = row.ProcedureName
    sheet2[f"H{row_num}"] = row.ProcedureVistCharge

# Save the workbook to the specified file path
workbook.save(file_path)

# Close the database connection
cursor.close()
conn.close()

# Output the path where the file was saved
print(f"Excel file saved to: {file_path}")
