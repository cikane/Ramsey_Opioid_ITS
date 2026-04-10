# --- 1. LIBRARIES & CONNECTION ---
library(tidyverse)
library(DBI)
library(odbc)
library(here)

con <- dbConnect(odbc(), 
                 Driver = "ODBC Driver 17 for SQL Server",
                 Server = "localhost", 
                 Database = "PublicHealth_Surveillance", 
                 Trusted_Connection = "yes")

# --- 2. PULL THE GOLD VIEW ---
df_gold <- dbGetQuery(con, "SELECT * FROM rpt.v_Opioid_SDOH_Intersection")
df_gold$date <- as.Date(df_gold$date)

# --- 3. CREATE DIRECTORY ---
# This fixes the 'unable to open file' error
dir.create(here("outputs", "figures"), recursive = TRUE, showWarnings = FALSE)

# --- 4. VISUALIZE VULNERABILITY-ADJUSTED TREND ---
# Since SDOH is constant, we plot the 'Adjusted Rate' to show the 
# monthly burden relative to the county's social risk.
adj_plot <- ggplot(df_gold, aes(x = date, y = Vulnerability_Adjusted_Rate)) +
  geom_line(color = "darkred", linewidth = 1) +
  geom_point(size = 3) +
  geom_hline(yintercept = mean(df_gold$Vulnerability_Adjusted_Rate), 
             linetype = "dashed", color = "blue") +
  labs(
    title = "Ramsey County: Vulnerability-Adjusted Overdose Rate",
    subtitle = "Monthly Overdoses divided by Community Vulnerability Index (CVI)",
    x = "Month",
    y = "Adjustment Factor (Overdose Intensity)",
    caption = "Blue dashed line represents the funding era average."
  ) +
  theme_minimal()

# --- 5. SAVE ---
ggsave(here("outputs", "figures", "vulnerability_adjusted_trend.png"), 
       plot = adj_plot, width = 10, height = 6)

message("✅ Strategic plot saved to outputs/figures/vulnerability_adjusted_trend.png")