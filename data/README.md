# Data Directory

This folder stores raw and processed data for the WHO FluNet influenza time series project.

## Raw Data

Place the WHO FluNet raw file here:

```text
data/raw/VIW_FNT.csv
```

The raw file is not included in this repository by default. It may be excluded from GitHub depending on file size, data access terms, and licensing.

## Processed Data

Processed analysis-ready files will be written to:

```text
data/processed/
```

The main target variable is:

```text
percent_positive = INF_ALL / SPEC_PROCESSED_NB * 100
```

If the raw file uses different column names, inspect the data and update `R/preprocessing.R` with the equivalent fields for country, year, week, specimens processed, and influenza positives.
