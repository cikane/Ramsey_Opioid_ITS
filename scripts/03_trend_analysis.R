# --- 1. LOAD LIBRARIES ---
library(tidyverse)
library(here)
library(httpgd)

# Start the graphics server for VS Code
if (interactive()) httpgd::hgd()

# --- 2. LOAD DATA ---
data_path <- here("data", "processed", "ramsey_overdose_clean.csv")
df <- read_csv(data_path)
df$date <- as.Date(df$date)

# --- 3. LINEAR TREND MODEL ---
# We are testing if 'time' (the passing months) predicts a change in 'overdose_count'
model_trend <- lm(overdose_count ~ time, data = df)

# Output the statistical summary
# Look at the 'Estimate' for 'time' and the 'Pr(>|t|)' (p-value)
print(summary(model_trend))

# --- 4. VISUALIZATION ---
trend_plot <- ggplot(df, aes(x = date, y = overdose_count)) +
  geom_point(color = "steelblue", size = 3, alpha = 0.7) +
  # Add the linear trend line with a 95% confidence interval (the grey shadow)
  geom_smooth(method = "lm", color = "darkgreen", fill = "lightgreen", linewidth = 1.2) +
  labs(
    title = "Ramsey County: Opioid Overdose Trend (2024-2025)",
    subtitle = "Post-Settlement Funding Era Analysis",
    x = "Month",
    y = "Monthly ED Visits (Suspected Opioid Overdose)",
    caption = "Data Source: MDH Syndromic Surveillance | Model: Linear Regression (OLS)"
  ) +
  theme_minimal(base_size = 14) +
  theme(
    plot.title = element_text(face = "bold"),
    panel.grid.minor = element_blank()
  )

# Display the plot
print(trend_plot)

# --- 5. SAVE OUTPUT ---
dir.create(here("outputs", "figures"), recursive = TRUE, showWarnings = FALSE)
ggsave(here("outputs", "figures", "ramsey_trend_2025.png"), 
       plot = trend_plot, width = 10, height = 6)

message("✅ Trend analysis complete! Plot saved to outputs/figures/ramsey_trend_2025.png")