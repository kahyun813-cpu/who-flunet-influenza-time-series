# Preprocessing functions for WHO FluNet influenza data.

raw_data_path <- function() {
  here::here("data", "raw", "VIW_FNT.csv")
}

processed_data_path <- function() {
  here::here("data", "processed", "canada_flu_percent_positive_2015_2019.csv")
}

check_raw_data_file <- function(raw_file = raw_data_path()) {
  if (!file.exists(raw_file)) {
    stop(
      paste0(
        "Raw data file not found.\n\n",
        "Please place the WHO FluNet file at:\n",
        "data/raw/VIW_FNT.csv\n\n",
        "Full path checked by here::here():\n",
        raw_file
      ),
      call. = FALSE
    )
  }

  invisible(raw_file)
}

load_flunet_data <- function(raw_file = raw_data_path()) {
  check_raw_data_file(raw_file)

  readr::read_csv(raw_file, show_col_types = FALSE) |>
    janitor::clean_names()
}

find_column <- function(data, candidates, required = TRUE) {
  found <- candidates[candidates %in% names(data)]

  if (length(found) > 0) {
    return(found[1])
  }

  if (required) {
    stop(
      paste0(
        "Could not find any of these required columns: ",
        paste(candidates, collapse = ", ")
      ),
      call. = FALSE
    )
  }

  NA_character_
}

get_flunet_columns <- function(raw_data) {
  list(
    country = find_column(raw_data, c("country_area_territory", "country", "country_name")),
    week_start = find_column(raw_data, c("iso_weekstartdate", "week_start", "week_start_date"), required = FALSE),
    year = find_column(raw_data, c("iso_year", "year")),
    week = find_column(raw_data, c("iso_week", "week")),
    specimens = find_column(raw_data, c("spec_processed_nb", "specimens_processed", "spec_processed")),
    positives = find_column(raw_data, c("inf_all", "total_influenza_positive", "influenza_positive"))
  )
}

inspect_flunet_data <- function(raw_data) {
  columns <- get_flunet_columns(raw_data)

  missing_values <- tibble::tibble(
    column_name = names(raw_data),
    missing_count = colSums(is.na(raw_data)),
    missing_percent = round(missing_count / nrow(raw_data) * 100, 2)
  )

  unique_countries <- raw_data |>
    dplyr::distinct(.data[[columns$country]]) |>
    dplyr::arrange(.data[[columns$country]]) |>
    dplyr::pull(.data[[columns$country]])

  list(
    dimensions = dim(raw_data),
    column_names = names(raw_data),
    key_columns = columns,
    missing_values = missing_values,
    unique_countries = unique_countries
  )
}

print_flunet_inspection <- function(inspection) {
  message("Raw data dimensions: ", inspection$dimensions[1], " rows x ", inspection$dimensions[2], " columns")
  message("Detected key columns:")
  print(unlist(inspection$key_columns))

  message("Number of unique countries/areas/territories: ", length(inspection$unique_countries))
  message("First 15 countries/areas/territories:")
  print(utils::head(inspection$unique_countries, 15))

  message("Columns with missing values:")
  print(
    inspection$missing_values |>
      dplyr::filter(.data$missing_count > 0) |>
      dplyr::arrange(dplyr::desc(.data$missing_count))
  )

  invisible(inspection)
}

make_iso_week_start <- function(year, week) {
  jan4 <- as.Date(paste0(year, "-01-04"))
  week1_monday <- jan4 - (lubridate::wday(jan4, week_start = 1) - 1)
  week1_monday + lubridate::weeks(week - 1)
}

prepare_canada_percent_positive <- function(
  raw_data,
  start_date = as.Date("2015-01-01"),
  end_date = as.Date("2019-12-31")
) {
  columns <- get_flunet_columns(raw_data)

  prepared <- raw_data |>
    dplyr::transmute(
      country = .data[[columns$country]],
      iso_year = readr::parse_integer(as.character(.data[[columns$year]])),
      iso_week = readr::parse_integer(as.character(.data[[columns$week]])),
      week_start = if (!is.na(columns$week_start)) {
        as.Date(.data[[columns$week_start]])
      } else {
        make_iso_week_start(
          readr::parse_integer(as.character(.data[[columns$year]])),
          readr::parse_integer(as.character(.data[[columns$week]]))
        )
      },
      spec_processed_nb = readr::parse_number(as.character(.data[[columns$specimens]])),
      inf_all = readr::parse_number(as.character(.data[[columns$positives]]))
    ) |>
    dplyr::filter(.data$country == "Canada") |>
    dplyr::group_by(.data$country, .data$iso_year, .data$iso_week, .data$week_start) |>
    dplyr::summarise(
      spec_processed_nb = sum(.data$spec_processed_nb, na.rm = TRUE),
      inf_all = sum(.data$inf_all, na.rm = TRUE),
      .groups = "drop"
    ) |>
    dplyr::mutate(
      percent_positive = .data$inf_all / .data$spec_processed_nb * 100
    ) |>
    dplyr::filter(
      .data$week_start >= start_date,
      .data$week_start <= end_date,
      is.finite(.data$percent_positive),
      !is.na(.data$percent_positive),
      .data$spec_processed_nb > 0,
      .data$inf_all >= 0
    ) |>
    dplyr::arrange(.data$week_start)

  if (nrow(prepared) == 0) {
    stop("No valid Canada records remained after filtering to 2015-2019.", call. = FALSE)
  }

  prepared
}

check_weekly_regular <- function(processed_data) {
  gaps <- diff(processed_data$week_start)

  if (length(gaps) > 0 && any(gaps != 7)) {
    warning(
      "The cleaned Canada data has at least one gap that is not exactly 7 days. ",
      "Review missing weeks before interpreting the time series model.",
      call. = FALSE
    )
  }

  invisible(processed_data)
}

save_processed_data <- function(
  processed_data,
  output_file = processed_data_path()
) {
  readr::write_csv(processed_data, output_file)
  output_file
}
