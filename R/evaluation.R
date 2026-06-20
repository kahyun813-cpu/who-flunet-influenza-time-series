# Evaluation functions for chronological train/test splitting and accuracy.

split_train_test <- function(processed_data, holdout_weeks = 52) {
  n_obs <- nrow(processed_data)

  if (n_obs <= holdout_weeks + 52) {
    stop(
      paste0(
        "Not enough observations for a ",
        holdout_weeks,
        "-week hold-out set. Found only ",
        n_obs,
        " observations after cleaning."
      ),
      call. = FALSE
    )
  }

  split_index <- n_obs - holdout_weeks

  list(
    train = processed_data[seq_len(split_index), ],
    test = processed_data[(split_index + 1):n_obs, ]
  )
}

calculate_mae <- function(actual, predicted) {
  mean(abs(actual - predicted), na.rm = TRUE)
}

calculate_rmse <- function(actual, predicted) {
  sqrt(mean((actual - predicted)^2, na.rm = TRUE))
}

create_model_comparison <- function(forecasts, test_data) {
  actual <- test_data$percent_positive
  arima_predicted <- as.numeric(forecasts$arima$mean)
  sarima_predicted <- as.numeric(forecasts$sarima$mean)

  tibble::tibble(
    model = c("ARIMA", "SARIMA"),
    mae = c(
      calculate_mae(actual, arima_predicted),
      calculate_mae(actual, sarima_predicted)
    ),
    rmse = c(
      calculate_rmse(actual, arima_predicted),
      calculate_rmse(actual, sarima_predicted)
    )
  ) |>
    dplyr::arrange(.data$rmse)
}

save_model_comparison <- function(
  comparison_table,
  output_file = here::here("tables", "model_comparison.csv")
) {
  readr::write_csv(comparison_table, output_file)
  output_file
}
