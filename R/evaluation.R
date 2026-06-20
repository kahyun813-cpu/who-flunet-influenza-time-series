# Evaluation and residual diagnostic functions.

calculate_accuracy_table <- function(forecasts, test_ts) {
  nonseasonal_accuracy <- forecast::accuracy(forecasts$nonseasonal, test_ts)
  seasonal_accuracy <- forecast::accuracy(forecasts$seasonal, test_ts)

  tibble::tibble(
    model = c("Non-seasonal ARIMA", "Seasonal ARIMA"),
    mae = c(
      nonseasonal_accuracy["Test set", "MAE"],
      seasonal_accuracy["Test set", "MAE"]
    ),
    rmse = c(
      nonseasonal_accuracy["Test set", "RMSE"],
      seasonal_accuracy["Test set", "RMSE"]
    )
  )
}

save_accuracy_table <- function(
  accuracy_table,
  output_file = here::here("tables", "forecast_accuracy.csv")
) {
  readr::write_csv(accuracy_table, output_file)
  output_file
}

run_ljung_box_test <- function(model, lag = 24) {
  stats::Box.test(
    stats::residuals(model),
    lag = lag,
    type = "Ljung-Box",
    fitdf = length(model$coef)
  )
}

save_residual_diagnostics <- function(
  nonseasonal_model,
  seasonal_model,
  output_file = here::here("tables", "ljung_box_tests.csv")
) {
  nonseasonal_test <- run_ljung_box_test(nonseasonal_model)
  seasonal_test <- run_ljung_box_test(seasonal_model)

  diagnostics <- tibble::tibble(
    model = c("Non-seasonal ARIMA", "Seasonal ARIMA"),
    statistic = c(
      unname(nonseasonal_test$statistic),
      unname(seasonal_test$statistic)
    ),
    p_value = c(nonseasonal_test$p.value, seasonal_test$p.value),
    lag = c(unname(nonseasonal_test$parameter), unname(seasonal_test$parameter))
  )

  readr::write_csv(diagnostics, output_file)
  output_file
}
