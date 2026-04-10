# Social Fabric Strategy: Opioid Impact Analysis (Ramsey County)

An end-to-end data engineering and policy analysis project exploring the intersection of Opioid Settlement funding and Social Determinants of Health (SDOH) in Ramsey County, MN.

## 🧠 Project Vision
This project moves beyond standard public health reporting to analyze the **"Structural Floor"** of the opioid crisis. By normalizing overdose data against a **Community Vulnerability Index (CVI)**, we identify where funding is merely managing symptoms versus where it is successfully shifting the social fabric.

## 🛠️ Technical Stack
- **Database:** SQL Server (Medallion Architecture)
- **Analytics:** R (Linear Trend Modeling & SDOH Correlation)
- **Predictive Scouting:** Python (Socrata API integration for real-time EMS Spike Detection)
- **Environment Management:** `renv` (R) and `venv` (Python)

## 📈 Key Innovation: The Vulnerability-Adjusted Rate (VAR)
Instead of looking at raw counts, this project utilizes a **VAR** to isolate "Crisis Intensity." This allows policymakers to see fluctuations in the crisis that are independent of poverty or insurance status.