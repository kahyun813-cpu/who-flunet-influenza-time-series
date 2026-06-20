# Seasonal Time Series Forecasting of Canadian Influenza Percent Positivity Using WHO FluNet Data

## Project Motivation

This project analyzes long-term weekly influenza surveillance data for Canada using WHO FluNet data. A previous Canadian respiratory virus surveillance dataset contained only 42 weekly observations, which was too short for reliable seasonal time series modeling. WHO FluNet provides a longer weekly surveillance record and is more appropriate for demonstrating SARIMA-based seasonal time series analysis.

The main goal is to study Canadian influenza seasonality and compare non-seasonal ARIMA models with seasonal ARIMA models using influenza percent positivity.

## Research Questions

1. Does Canadian influenza percent positivity show a clear recurring annual seasonal pattern?
2. Can a seasonal ARIMA model capture the weekly influenza pattern better than a non-seasonal ARIMA model?
3. How well can the fitted model forecast a hold-out period using historical surveillance data?
4. What limitations arise from surveillance data, such as reporting changes, missingness, and the COVID-19 period?

## Data Source

The intended data source is WHO FluNet influenza surveillance data.

Expected raw file:

```text
data/raw/VIW_FNT.csv
```

Raw data may not be committed to GitHub depending on file size, data access terms, and licensing. Place the downloaded raw file in `data/raw/` before running the full analysis.

## Main Analysis Period

The initial analysis focuses on Canada during the pre-COVID period:

```text
2015-01-01 to 2019-12-31
```

This period avoids pandemic-related disruptions and should provide approximately five years of weekly observations, if the data support it.

## Target Variable

The target outcome is influenza percent positivity:

```text
percent_positive = INF_ALL / SPEC_PROCESSED_NB * 100
```

If these exact column names are not present in the raw file, the preprocessing script should be updated after inspecting the dataset to identify equivalent columns for:

- number of specimens processed or tested
- total influenza positives
- country
- year
- week

## Methods

Planned methods include:

- Exploratory time series analysis
- STL decomposition
- ACF and PACF plots
- ADF stationarity test
- Non-seasonal ARIMA using `forecast::auto.arima(seasonal = FALSE)`
- Seasonal ARIMA using `forecast::auto.arima(seasonal = TRUE)`
- Chronological train/test split using the final 52 weeks as a hold-out set if possible
- Forecast accuracy comparison using MAE and RMSE
- Residual diagnostics using `forecast::checkresiduals()` and Ljung-Box tests

This project intentionally does not implement VAR, Granger causality, ARCH/GARCH, LSTM, deep learning, or a broad model zoo. The focus is proper seasonal time series analysis using a sufficiently long public health surveillance dataset.

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

1. Clone or download this repository.
2. Install the required R packages:

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

3. Download the WHO FluNet raw data file and place it here:

```text
data/raw/VIW_FNT.csv
```

4. Run the main workflow script:

```r
source("scripts/run_analysis.R")
```

The first version of the project includes checks that stop with a helpful message if the raw data file is missing.
