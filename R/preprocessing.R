# Preprocessing functions for WHO FluNet influenza data.

check_raw_data_file <- function(raw_file = here::here("data", "raw", "VIW_FNT.csv")) {
  if (!file.exists(raw_file)) {
    stop(
      paste0(
        "Raw data file not found.\n\n",
        "Please place the WHO FluNet file at:\n",
        raw_file,
        "\n\n",
        "Expected repository path: data/raw/VIW_FNT.csv"
      ),
      call. = FALSE
    )
  }

  invisible(raw_file)
}

load_flunet_data <- function(raw_file = here::here("data", "raw", "VIW_FNT.csv")) {
  check_raw_data_file(raw_file)

  readr::read_csv(raw_file, show_col_types = FALSE) |>
    janitor::clean_names()
}

inspect_flunet_columns <- function(raw_data) {
  tibble::tibble(
    column_name = names(raw_data),
    column_type = purrr::map_chr(raw_data, ~ class(.x)[1])
  )
}

prepare_canada_percent_positive <- function(
  raw_data,
  start_date = as.Date("2015-01-01"),
  end_date = as.Date("2019-12-31")
) {
  required_columns <- c(
    "country",
    "year",
    "week",
    "inf_all",
    "spec_processed_nb"
  )

  missing_columns <- setdiff(required_columns, names(raw_data))

  if (length(missing_columns) > 0) {
    stop(
      paste0(
        "The raw data is missing expected columns: ",
        paste(missing_columns, collapse = ", "),
        "\n\n",
        "Use inspect_flunet_columns(raw_data) to identify equivalent columns, ",
        "then update prepare_canada_percent_positive()."
      ),
      call. = FALSE
    )
  }

  raw_data |>
    dplyr::filter(.data$country == "Canada") |>
    dplyr::mutate(
      week_start = lubridate::ymd(
        paste0(.data$year, "-W", stringr::str_pad(.data$week, 2, pad = "0"), "-1")
      ),
      percent_positive = dplyr::if_else(
        .data$spec_processed_nb > 0,
        .data$inf_all / .data$spec_processed_nb * 100,
        NA_real_
      )
    ) |>
    dplyr::filter(.data$week_start >= start_date, .data$week_start <= end_date) |>
    dplyr::arrange(.data$week_start) |>
    dplyr::select(
      week_start,
      country,
      year,
      week,
      spec_processed_nb,
      inf_all,
      percent_positive
    )
}

save_processed_data <- function(
  processed_data,
  output_file = here::here("data", "processed", "canada_percent_positive_2015_2019.csv")
) {
  readr::write_csv(processed_data, output_file)
  output_file
}
