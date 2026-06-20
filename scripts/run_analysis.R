# Main workflow for the WHO FluNet influenza time series project.
#
# Before running the full workflow, download the WHO FluNet file and place it at:
# data/raw/VIW_FNT.csv

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

source(here::here("R", "preprocessing.R"))
source(here::here("R", "visualization.R"))
source(here::here("R", "modeling.R"))
source(here::here("R", "evaluation.R"))

raw_file <- here::here("data", "raw", "VIW_FNT.csv")

message("Checking for raw data file...")
check_raw_data_file(raw_file)

message("Loading WHO FluNet data...")
raw_data <- load_flunet_data(raw_file)

message("Preparing Canada percent positivity data for 2015-2019...")
canada_data <- prepare_canada_percent_positive(raw_data)
processed_file <- save_processed_data(canada_data)

message("Saved processed data to: ", processed_file)

message("Creating exploratory figures...")
save_percent_positive_plot(canada_data)

ts_data <- create_weekly_ts(canada_data)
save_stl_plot(ts_data)
save_acf_pacf_plots(ts_data)

message("Running ADF stationarity test...")
adf_result <- run_adf_test(ts_data)
print(adf_result)

message("Splitting data into training and 52-week hold-out test set...")
split_data <- split_train_test(ts_data, holdout_weeks = 52)

message("Fitting non-seasonal ARIMA model...")
nonseasonal_model <- fit_nonseasonal_arima(split_data$train)

message("Fitting seasonal ARIMA model...")
seasonal_model <- fit_seasonal_arima(split_data$train)

message("Forecasting hold-out period...")
forecasts <- forecast_models(
  nonseasonal_model,
  seasonal_model,
  h = length(split_data$test)
)

message("Saving forecast accuracy comparison...")
accuracy_table <- calculate_accuracy_table(forecasts, split_data$test)
accuracy_file <- save_accuracy_table(accuracy_table)
print(accuracy_table)

message("Saving Ljung-Box residual diagnostic table...")
diagnostics_file <- save_residual_diagnostics(nonseasonal_model, seasonal_model)

message("Analysis complete.")
message("Accuracy table: ", accuracy_file)
message("Residual diagnostics table: ", diagnostics_file)
