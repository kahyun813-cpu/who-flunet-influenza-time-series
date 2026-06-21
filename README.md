# Seasonal Time Series Forecasting of Canadian Influenza Percent Positivity Using WHO FluNet Data

## Project Motivation

This project analyzes long-term weekly influenza surveillance data for Canada using WHO FluNet data. WHO FluNet provides weekly surveillance records that are appropriate for demonstrating seasonal ARIMA-based time series analysis.

The project focuses on statistical forecasting of surveillance data. It does not claim causality or explain biological mechanisms.

## Research Questions

1. Does Canadian influenza percent positivity show a clear recurring annual seasonal pattern?
2. Can a seasonal ARIMA model capture the weekly influenza pattern better than a non-seasonal ARIMA model?
3. How well can the fitted model forecast a hold-out period using historical surveillance data?
4. What limitations arise from surveillance data, such as reporting changes, missingness, and the COVID-19 period?

## Data Source

The raw data source is WHO FluNet influenza surveillance data.

Original data download page:

```text
https://www.who.int/teams/global-influenza-programme/surveillance-and-monitoring/influenza-surveillance-outputs
```

On this WHO Global Influenza Programme page, use the `Download the FluNet dataset (CSV)` link under the `Download data` section.

Expected raw file:

```text
data/raw/VIW_FNT.csv
```

Raw data may not be committed to GitHub depending on file size, data access terms, and licensing.

## Variables Used

The current pipeline inspects the raw CSV after cleaning names with `janitor::clean_names()`. In the provided WHO FluNet export, the main variables are:

- country: `country_area_territory`
- week start date: `iso_weekstartdate`
- ISO year: `iso_year`
- ISO week: `iso_week`
- specimens processed: `spec_processed_nb`
- total influenza positives: `inf_all`

The target variable is:

```text
percent_positive = inf_all / spec_processed_nb * 100
```

## Analysis Period

The main analysis focuses on Canada during the pre-COVID period:

```text
2015-01-01 to 2019-12-31
```

This period was chosen to avoid COVID-era disruptions in influenza circulation, testing, and surveillance reporting.

## Model Workflow

The reproducible workflow:

1. Load `data/raw/VIW_FNT.csv`.
2. Clean column names.
3. Inspect dimensions, column names, missing values, and unique countries.
4. Filter to Canada.
5. Calculate weekly influenza percent positivity.
6. Filter to 2015-2019 and remove invalid target values.
7. Save cleaned data.
8. Create exploratory plots, seasonal plots, STL decomposition, ACF, and PACF.
9. Split chronologically into training and final 52-week hold-out test set.
10. Fit non-seasonal ARIMA using `forecast::auto.arima(seasonal = FALSE)`.
11. Fit SARIMA using `forecast::auto.arima(seasonal = TRUE)`.
12. Forecast the hold-out period.
13. Compare MAE and RMSE.
14. Run residual diagnostics and Ljung-Box tests.

The weekly time series uses `frequency = 52` for annual influenza seasonality. The default script uses `stepwise = TRUE` and `approximation = FALSE` so the project runs reliably on a local laptop. To run a slower exhaustive search, set `use_full_arima_search <- TRUE` in `scripts/run_analysis.R`.

This project intentionally does not implement VAR, Granger causality, ARCH/GARCH, LSTM, deep learning, or a broad model zoo. The focus is ARIMA vs SARIMA for seasonal time series forecasting.

## Output Files

Cleaned data:

```text
data/processed/canada_flu_percent_positive_2015_2019.csv
```

Figures:

```text
figures/canada_percent_positive_timeseries.png
figures/seasonal_plot_by_iso_week.png
figures/stl_decomposition.png
figures/acf_percent_positive.png
figures/pacf_percent_positive.png
figures/forecast_comparison_arima_sarima.png
figures/arima_checkresiduals.png
figures/sarima_checkresiduals.png
```

Tables:

```text
tables/model_comparison.csv
tables/residual_diagnostics.csv
```

Report summary:

```text
reports/analysis_summary.txt
reports/final_report.md
```

## Repository Structure

```text
who-flunet-influenza-time-series/
├── README.md
├── .gitignore
├── data/
│   ├── raw/
│   ├── processed/
│   └── README.md
├── R/
│   ├── preprocessing.R
│   ├── visualization.R
│   ├── modeling.R
│   └── evaluation.R
├── scripts/
│   └── run_analysis.R
├── figures/
├── tables/
└── reports/
```

## Reproducibility Instructions

Install the required R packages:

```r
install.packages(c(
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
))
```

Place the WHO FluNet raw CSV here:

```text
data/raw/VIW_FNT.csv
```

Run the full analysis from the project root:

```r
source("scripts/run_analysis.R")
```

In RStudio, open `who-flunet-influenza-time-series.Rproj` first so the working directory is the project root.

The script prints progress messages, selected ARIMA/SARIMA orders, ADF test results, forecast accuracy results, and residual diagnostic summaries.
It also saves the main results to `reports/analysis_summary.txt`, so you do not need to copy console output manually.

## Interpretation Notes

If SARIMA has lower hold-out error than ARIMA, this supports the usefulness of recurring seasonal structure for forecasting this surveillance series. If SARIMA does not improve hold-out accuracy, seasonality may still be visually present but may not improve short-term forecast accuracy in this particular split.

All results should be interpreted as statistical forecasts of surveillance data, with limitations related to reporting changes, missingness, testing behavior, and the choice to avoid the COVID-era period.
