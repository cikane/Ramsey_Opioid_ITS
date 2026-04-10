/*
===================================================================================================
PROJECT: Ramsey County Opioid Settlement Impact Analysis
FIRM: Social Fabric Strategy
CONSULTANT: Thomas Doyle-Walton, PhD, MPH
DATE: March 2026

STRATEGIC CONTEXT:
Evaluates the "Settlement Funding Era" (2024-2025) by layering overdose outcomes 
against the Community Vulnerability Index (CVI) from the SDOH_Analytics database.

TECHNICAL LOGIC:
1. Ensures the 'rpt' (Reporting) schema exists.
2. Creates a cross-database Gold View joining Surveillance and SDOH data.
3. Aggregates tract-level vulnerability to a county-level baseline.
===================================================================================================
*/

USE PublicHealth_Surveillance;
GO

-- 1. SCHEMA PREPARATION
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'rpt')
BEGIN
    EXEC('CREATE SCHEMA rpt');
    PRINT '✅ Schema [rpt] created successfully.';
END
GO

-- 2. GOLD VIEW CREATION
CREATE OR ALTER VIEW rpt.v_Opioid_SDOH_Intersection AS
WITH County_SDOH_Stats AS (
    -- Aggregating SDOH metrics from the SDOH_Analytics database
    SELECT 
        County,
        AVG(Poverty_Rate) AS Avg_Poverty_Rate,
        AVG(Uninsured_Rate) AS Avg_Uninsured_Rate,
        AVG(Mental_Health_Rate) AS Avg_MH_Rate, 
        AVG(CVI_Score) AS Avg_Community_Vulnerability_Index,
        COUNT(TractID) AS Total_Tracts_Analyzed
    FROM SDOH_Analytics.int.v_Tract_Vulnerability_Index
    WHERE County = 'Ramsey'
    GROUP BY County
)
SELECT 
    o.date,
    o.overdose_count,
    o.intervention,
    s.Avg_Poverty_Rate,
    s.Avg_Uninsured_Rate,
    s.Avg_MH_Rate,
    s.Avg_Community_Vulnerability_Index,
    -- Crisis Intensity: Monthly ODs relative to the social vulnerability baseline
    (CAST(o.overdose_count AS FLOAT) / NULLIF(s.Avg_Community_Vulnerability_Index, 0)) AS Vulnerability_Adjusted_Rate
FROM PublicHealth_Surveillance.dbo.ramsey_overdose_its o
LEFT JOIN County_SDOH_Stats s ON s.County = 'Ramsey'
WHERE o.date >= '2024-01-01'; -- Focus on the Funding Era
GO

-- 3. VERIFICATION
PRINT '✅ View [rpt.v_Opioid_SDOH_Intersection] updated.';
SELECT TOP 5 * FROM rpt.v_Opioid_SDOH_Intersection ORDER BY date DESC;
GO