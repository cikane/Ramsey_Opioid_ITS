# --- 1. LOAD LIBRARIES ---
library(tidyverse)
library(prais)   # For Prais-Winsten AR(1) regression
library(here)    # For easy file paths
library(httpgd)  # For high-quality plots in VS Code

# --- 2. LOAD THE DATA ---
# This pulls the CSV created by your Python ETL script
data_path <- here("data", "processed", "ramsey_overdose_clean.csv")

if (!file.exists(data_path)) {
  stop("❌ Cleaned data not found. Run the Python ETL script first!")
}

df <- read_csv(data_path)

# Ensure date is a proper Date object
df$date <- as.Date(df$date)

# --- 3. RUN THE PRAIS-WINSTEN MODEL ---
# Formula: outcome ~ baseline_trend + level_shift + slope_change
# we use 'overdose_count' to match your Python output
model <- prais_winsten(overdose_count ~ time + intervention + time_after, 
                       data = df, 
                       index = "time")

# Print the statistical summary to the console
print(summary(model))

# --- 4. CREATE THE VISUALIZATION ---
# This plot shows the "Break" in the trend at January 2024
its_plot <- ggplot(df, aes(x = date, y = overdose_count)) +
  geom_point(alpha = 0.5, color = "steelblue") +
  
  # The Intervention Line (Settlement Funding Surge)
  geom_vline(xintercept = as.numeric(as.Date("2024-01-01")),
             linetype = "dashed", color = "red", linewidth = 1) +
  
  # Pre-intervention Trend (Blue)
  geom_smooth(data = filter(df, intervention == 0),
              method = "lm", color = "blue", se = FALSE) +
  
  # Post-intervention Trend (Dark Green)
  geom_smooth(data = filter(df, intervention == 1), 
              method = "lm", color = "darkgreen", se = FALSE) +
  
  # Label the Intervention
  annotate("text", x = as.Date("2024-01-01"), y = max(df$overdose_count, na.rm=TRUE), 
           label = "Funding Surge", color = "red", hjust = -0.1, fontface = "bold") +
  
  # Labels and Formatting
  labs(title = "Impact of Opioid Settlement Funding: Ramsey County",
       subtitle = "Interrupted Time Series Analysis (Level & Slope Change)",
       x = "Date",
       y = "Monthly Non-Fatal Overdoses",
       caption = "Data Source: MDH Syndromic Surveillance | Model: Prais-Winsten