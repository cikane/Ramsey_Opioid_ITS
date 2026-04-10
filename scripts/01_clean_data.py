import pandas as pd
import numpy as np
import os
import urllib
from pathlib import Path
from sqlalchemy import create_engine

# --- 1. CONFIGURATION ---
RAW_DATA_DIR = Path("data/raw")
PROCESSED_DATA_DIR = Path("data/processed")
INPUT_FILE = RAW_DATA_DIR / "mdh_overdose_data_2026.xlsx" 
OUTPUT_FILE = PROCESSED_DATA_DIR / "ramsey_overdose_clean.csv"

# SQL Server Configuration
DB_NAME = "PublicHealth_Surveillance"
TABLE_NAME = "ramsey_overdose_its"
SERVER_NAME = "localhost" 

# Manual Column Names from your Excel Image
COL_COUNTY = 'County_name'
COL_MONTH = 'Month'
COL_YEAR = 'Year'
COL_DRUG = 'Drug_Category'
COL_VALUE = 'Count_suppressed' # This is Column J in your image

def get_sql_engine():
    params = urllib.parse.quote_plus(
        f"DRIVER={{ODBC Driver 17 for SQL Server}};"
        f"SERVER={SERVER_NAME};"
        f"DATABASE={DB_NAME};"
        f"Trusted_Connection=yes;"
    )
    return create_engine(f"mssql+pyodbc:///?odbc_connect={params}")

def run_etl():
    if not INPUT_FILE.exists():
        print(f"❌ Error: {INPUT_FILE} not found.")
        return

    print("🚀 Starting Ramsey County Public Health ETL Pipeline...")
    
    # --- 2. LOAD DATA ---
    # We skip exactly 1 row because 'Year', 'Month', etc. are on Row 2
    df = pd.read_excel(INPUT_FILE, skiprows=1)

    # --- 3. CLEAN & FILTER ---
    # 1. Filter for Ramsey County
    df_filtered = df[df[COL_COUNTY].astype(str).str.contains('Ramsey', case=False, na=False)].copy()
    
    # 2. Filter for All Opioids specifically (Row 4 in your image)
    df_filtered = df_filtered[df_filtered[COL_DRUG] == 'All_Opioid']

    # 3. Create Date (Format: 'January 2024')
    df_filtered['date_dt'] = pd.to_datetime(
        df_filtered[COL_MONTH].astype(str) + " " + df_filtered[COL_YEAR].astype(str), 
        format='%B %Y', 
        errors='coerce'
    )
    
    # 4. Clean up numbers and sort
    df_filtered = df_filtered.dropna(subset=['date_dt']).sort_values('date_dt').reset_index(drop=True)
    df_filtered['overdose_count'] = pd.to_numeric(df_filtered[COL_VALUE], errors='coerce').fillna(0)

    # --- 4. FEATURE ENGINEERING (ITS) ---
    df_filtered['time'] = df_filtered.index + 1
    int_date = pd.Timestamp('2024-01-01')
    df_filtered['intervention'] = (df_filtered['date_dt'] >= int_date).astype(int)
    
    # Slope change (months since intervention)
    df_filtered['time_after'] = df_filtered.apply(
        lambda x: max(0, (x['date_dt'].year - int_date.year) * 12 + (x['date_dt'].month - int_date.month)) 
        if x['intervention'] == 1 else 0, axis=1
    )

    # Final Date format for SQL
    df_filtered['date'] = df_filtered['date_dt'].dt.strftime('%Y-%m-%d')

    # --- 5. EXPORT ---
    final_cols = ['date', 'overdose_count', 'time', 'intervention', 'time_after']
    df_final = df_filtered[final_cols].copy()

    # Save to CSV and SQL
    os.makedirs(PROCESSED_DATA_DIR, exist_ok=True)
    df_final.to_csv(OUTPUT_FILE, index=False)

    try:
        engine = get_sql_engine()
        df_final.to_sql(TABLE_NAME, con=engine, if_exists='replace', index=False)
        print(f"✅ Success! {len(df_final)} months of Ramsey Opioid data loaded into SQL.")
    except Exception as e:
        print(f"⚠️ SQL Load Failed: {e}")

if __name__ == "__main__":
    run_etl()