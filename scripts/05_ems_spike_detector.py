import pandas as pd
from sodapy import Socrata

# 1. CONNECT
client = Socrata("opendata.ramseycountymn.gov", None)
dataset_id = "khr9-xwfu"

# 2. FETCH DATA
print("--- FETCHING HISTORICAL BASELINE (Q1 2022) ---")
# Since the data ends in March 2022, we pull the last 5000 records
results = client.get(dataset_id, limit=5000)
df_ems = pd.DataFrame.from_records(results)

# 3. CLEAN & FILTER
df_ems['response_date'] = pd.to_datetime(df_ems['response_date'])

# Using the labels we discovered: 'Medical/Fire' and 'MEDICAL'
df_filtered = df_ems[
    (df_ems['agency_type'] == 'Medical/Fire') & 
    (df_ems['problem'] == 'MEDICAL')
].copy()

# 4. SPIKE DETECTION LOGIC
daily_calls = df_filtered.resample('D', on='response_date').size()

# We'll use the first 20 days as the "Baseline" and the last day as "Today"
baseline = daily_calls.iloc[:-1]
latest_day = daily_calls.iloc[-1]

mean_val = baseline.mean()
std_val = baseline.std()
threshold = mean_val + (2 * std_val)

print(f"\n--- DETECTOR RESULTS (2022 Archive Mode) ---")
print(f"Historical Mean: {mean_val:.2f}")
print(f"Spike Threshold: {threshold:.2f}")
print(f"Latest Count: {latest_day}")

if latest_day > threshold:
    print("🚨 ALERT: Intensity Spike detected relative to baseline!")
else:
    print("✅ Status: Normal Activity.")