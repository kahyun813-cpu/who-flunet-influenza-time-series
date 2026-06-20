# Main reproducible workflow for the WHO FluNet influenza time series project.
# Run from the project root with:
# source("scripts/run_analysis.R")

required_packages <- c(
  "tidyverse",
  "lubridate",
  "readr",
  "janitor",
  "forecast",
  "tseries",
  "ggplot2",
  "here",
  "zoo",
  "scales"
)

missing_packages <- required_packages[
  !vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)
]

if (length(missing_packages) > 0) {
  stop(
    paste0(
      "Please install the following R packages before running the analysis:\n",
      paste(missing_packages, collapse = ", ")
    ),
    call. = FALSE
  )
}

suppressPackageStartupMessages({
  library(tidyverse)
  library(lubridate)
  library(readr)
  library(janitor)
  library(forecast)
  library(tseries)
  library(ggplot2)
  library(here)
  library(zoo)
  library(scales)
})

source(here::here("R", "preprocessing.R"))
source(here::here("R", "visualization.R"))
source(here::here("R", "modeling.R"))
source(here::here("R", "evaluation.R"))

message("Starting WHO FluNet Canada influenza time series analysis.")
message("Analysis focus: Canada, pre-COVID period 2015-01-01 to 2019-12-31.")

message("1. Checking and loading raw WHO FluNet data...")
raw_data <- load_flunet_data()

message("2. Inspecting raw data structure...")
inspection <- inspect_flunet_data(raw_data)
print_flunet_inspection(inspection)

message("3. Cleaning Canada data and calculating percent positivity...")
canada_data <- prepare_canada_percent_positive(raw_data)
check_weekly_regular(canada_data)
processed_file <- save_processed_data(canada_data)
message("Cleaned data saved to: ", processed_file)
message("Cleaned observations: ", nrow(canada_data))
message("Date range: ", min(canada_data$week_start), " to ", max(canada_data$week_start))

message("4. Creating exploratory figures...")
full_ts <- create_weekly_ts(canada_data)

figure_files <- c(
  save_percent_positive_plot(canada_data),
  save_seasonal_plot(canada_data),
  save_stl_plot(full_ts),
  save_acf_plot(full_ts),
  save_pacf_plot(full_ts)
)
message("Saved exploratory figures:")
print(figure_files)

message("5. Running ADF stationarity test...")
adf_result <- run_adf_test(full_ts)
print(adf_result)

message("6. Creating chronological train/test split...")
split_data <- split_train_test(canada_data, holdout_weeks = 52)
train_ts <- create_weekly_ts(split_data$train)
test_ts <- create_weekly_ts(split_data$test)
message("Training observations: ", nrow(split_data$train))
message("Test observations: ", nrow(split_data$test))

use_full_arima_search <- FALSE
message(
  "Model search mode: stepwise = ",
  !use_full_arima_search,
  ", approximation = FALSE. ",
  "Set use_full_arima_search <- TRUE in scripts/run_analysis.R for a slower exhaustive search."
)

message("7. Fitting ARIMA model with seasonal = FALSE...")
arima_model <- fit_model_with_fallback(
  train_ts,
  seasonal = FALSE,
  stepwise = !use_full_arima_search,
  approximation = FALSE
)
message("Selected ARIMA order: ", get_model_order_text(arima_model))
print(arima_model)

message("8. Fitting SARIMA model with seasonal = TRUE...")
sarima_model <- fit_model_with_fallback(
  train_ts,
  seasonal = TRUE,
  stepwise = !use_full_arima_search,
  approximation = FALSE
)
message("Selected SARIMA order: ", get_model_order_text(sarima_model))
print(sarima_model)

message("9. Forecasting the hold-out period...")
forecasts <- forecast_holdout(arima_model, sarima_model, h = length(test_ts))
forecast_plot_file <- save_forecast_comparison_plot(split_data$train, split_data$test, forecasts)
message("Forecast comparison figure saved to: ", forecast_plot_file)

message("10. Comparing forecast accuracy...")
comparison_table <- create_model_comparison(forecasts, split_data$test)
comparison_file <- save_model_comparison(comparison_table)
message("Model comparison table saved to: ", comparison_file)
print(comparison_table)

best_model <- comparison_table$model[1]
if (best_model == "SARIMA") {
  message(
    "Interpretation: SARIMA had lower RMSE in this split, which supports recurring ",
    "seasonal structure improving forecast accuracy for this hold-out period."
  )
} else {
  message(
    "Interpretation: ARIMA had lower RMSE in this split. Seasonality may still be ",
    "visible, but it did not improve short-term forecast accuracy for this hold-out period."
  )
}

message("11. Running residual diagnostics...")
arima_residual_plot <- save_checkresiduals_plot(
  arima_model,
  here::here("figures", "arima_checkresiduals.png")
)
sarima_residual_plot <- save_checkresiduals_plot(
  sarima_model,
  here::here("figures", "sarima_checkresiduals.png")
)
residual_diagnostics <- summarise_residual_diagnostics(arima_model, sarima_model)
residual_file <- here::here("tables", "residual_diagnostics.csv")
readr::write_csv(residual_diagnostics, residual_file)

message("Residual diagnostic figures saved to:")
print(c(arima = arima_residual_plot, sarima = sarima_residual_plot))
message("Residual diagnostic table saved to: ", residual_file)
print(residual_diagnostics)

message("Analysis complete. Results are statistical forecasts of surveillance data, not causal or biological mechanism estimates.")

message("12. Saving plain-text analysis summary...")
summary_file <- here::here("reports", "analysis_summary.txt")
summary_lines <- c(
  "Seasonal Time Series Forecasting of Canadian Influenza Percent Positivity Using WHO FluNet Data",
  "",
  "Analysis scope",
  "--------------",
  "Country: Canada",
  "Period: 2015-01-01 to 2019-12-31",
  "Target: percent_positive = inf_all / spec_processed_nb * 100",
  "Seasonal frequency: 52 weeks",
  "",
  "Cleaned data",
  "------------",
  paste("Cleaned observations:", nrow(canada_data)),
  paste("Date range:", min(canada_data$week_start), "to", max(canada_data$week_start)),
  paste("Cleaned data file:", processed_file),
  "",
  "ADF stationarity test",
  "---------------------",
  capture.output(print(adf_result)),
  "",
  "Selected models",
  "---------------",
  paste("ARIMA order:", get_model_order_text(arima_model)),
  paste("SARIMA order:", get_model_order_text(sarima_model)),
  "",
  "ARIMA model summary",
  "-------------------",
  capture.output(print(arima_model)),
  "",
  "SARIMA model summary",
  "--------------------",
  capture.output(print(sarima_model)),
  "",
  "Forecast accuracy comparison",
  "----------------------------",
  capture.output(print(comparison_table)),
  "",
  "Residual diagnostics",
  "--------------------",
  capture.output(print(residual_diagnostics)),
  "",
  "Interpretation",
  "--------------",
  if (best_model == "SARIMA") {
    paste(
      "SARIMA had lower RMSE than ARIMA in this chronological hold-out split.",
      "This supports the usefulness of recurring seasonal structure for forecasting",
      "Canadian influenza percent positivity during the 2015-2019 pre-COVID period."
    )
  } else {
    paste(
      "ARIMA had lower RMSE than SARIMA in this chronological hold-out split.",
      "Seasonality may still be visually present, but it did not improve short-term",
      "forecast accuracy in this particular split."
    )
  },
  "",
  "Limitations",
  "-----------",
  paste(
    "These results are statistical forecasts of surveillance data.",
    "They should not be interpreted as causal evidence or as explanations of",
    "biological mechanisms. Surveillance data can be affected by testing behavior,",
    "reporting changes, missingness, and other public health system factors."
  ),
  "",
  "Generated files",
  "---------------",
  paste("Model comparison table:", comparison_file),
  paste("Residual diagnostics table:", residual_file),
  paste("Forecast comparison figure:", forecast_plot_file)
)

writeLines(summary_lines, summary_file)
message("Analysis summary saved to: ", summary_file)
