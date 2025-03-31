# ETL Automation for Medical Clinic Data

## 📌 Project Overview  
This project automates the **ETL (Extract, Transform, Load)** process for a small medical clinic that previously relied on a manual CSV file upload workflow. The solution ensures **efficient data ingestion, transformation, and reporting** using **SQL Server, SSIS, and Python**.  
This project was completed as part of the **ETL and Data Migration certification** course at the **University of Washington**.

## 🚀 Key Features  
- **Automated Data Processing:** Converts raw CSV uploads into a structured database.  
- **Data Warehouse Implementation:** Centralized reporting in `DWClinicReportData`.  
- **Python-Based ETL:** Handles non-SQL data extraction and transformations.  
- **SSIS & SQL Automation:** Developed packages and jobs for automation.  
- **Real-Time Monitoring:** SSRS dashboards for job execution tracking.  
- **SSRS Reports for ETL Logs:** Provides insights into ETL execution history and errors.  

## 🛠️ Tech Stack  
- **Database:** SQL Server  
- **ETL Tools:** SSIS, SQL Jobs  
- **Scripting:** Python  
- **Reporting:** SSRS  
## 📸 Visual Studio Solution Structure
Here is a screenshot showing the organization of all the project files and folders in Visual Studio:

[Visual Studio Solution](https://github.com/user-attachments/assets/fbae2da4-5917-40c9-b138-31a8bf6ee94b)


## 📂 Repository Structure
```
├── data/                 # Sample dataset (CSV files)
├── scripts/              # Python ETL scripts
├── sql/                  # SQL scripts for database operations
├── ssis/                 # SSIS packages
├── reports/              # SSRS report templates
├── README.md             # Project documentation
```

## 🔧 Setup Instructions
1. Clone the repository:
2. Set up the database:
   - Run the SQL scripts in `sql/` to create tables and stored procedures.
3. Configure SSIS:
   - Import the SSIS package from `ssis/` and update the connection settings.
4. Run the Python ETL scripts:
   ```bash
   python scripts/etl_process.py
   ```
5. Deploy SSRS reports:
   - Import templates from `reports/` into your SSRS server.
   - Deploy **SSRS ETL Log Reports** for monitoring ETL execution status.

## 📊 Results & Benefits
✅ Reduced manual effort and errors
✅ Improved data accuracy and reporting efficiency
✅ Scalable architecture for future data expansion
✅ Enhanced visibility into ETL performance and failures

## 🤝 Contributions
-Contributions and feedback are welcome! Feel free to submit issues or pull requests.
---
**Author:** Girum Obse

For questions, connect with me on [LinkedIn](https://www.linkedin.com/in/girumbi/).
