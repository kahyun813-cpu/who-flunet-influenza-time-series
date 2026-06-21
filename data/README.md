# Data Directory

This folder stores raw and processed data for the WHO FluNet influenza time series project.

## Raw Data

The WHO FluNet data can be downloaded from the WHO Global Influenza Programme surveillance outputs page:

```text
https://www.who.int/teams/global-influenza-programme/surveillance-and-monitoring/influenza-surveillance-outputs
```

Use the `Download the FluNet dataset (CSV)` link under the `Download data` section.

Place the WHO FluNet raw file here:

```text
data/raw/VIW_FNT.csv
```

The raw file is not included in this repository by default. It may be excluded from GitHub depending on file size, data access terms, and licensing.

## Processed Data

Processed analysis-ready files will be written to:

```text
data/processed/canada_flu_percent_positive_2015_2019.csv
```

The main target variable is:

```text
percent_positive = inf_all / spec_processed_nb * 100
```

The current pipeline detects the WHO FluNet columns after `janitor::clean_names()`, including `country_area_territory`, `iso_weekstartdate`, `iso_year`, `iso_week`, `spec_processed_nb`, and `inf_all`.
