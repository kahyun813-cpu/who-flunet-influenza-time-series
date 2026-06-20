# Modeling functions for ARIMA and SARIMA analysis.

create_weekly_ts <- function(processed_data) {
  stats::ts(processed_data$percent_positive, frequency = 52)
}

run_adf_test <- function(ts_data) {
  tseries::adf.test(stats::na.omit(ts_data))
}

fit_arima_model <- function(train_ts) {
  forecast::auto.arima(
    train_ts,
    seasonal = FALSE,
    stepwise = FALSE,
    approximation = FALSE
  )
}

fit_sarima_model <- function(train_ts) {
  forecast::auto.arima(
    train_ts,
    seasonal = TRUE,
    stepwise = FALSE,
    approximation = FALSE
  )
}

fit_model_with_fallback <- function(
  train_ts,
  seasonal,
  stepwise = TRUE,
  approximation = FALSE
) {
  tryCatch(
    forecast::auto.arima(
      train_ts,
      seasonal = seasonal,
      stepwise = stepwise,
      approximation = approximation
    ),
    error = function(error) {
      message(
        "Full auto.arima search failed; retrying with stepwise = TRUE and approximation = TRUE. ",
        "Original error: ",
        conditionMessage(error)
      )

      forecast::auto.arima(
        train_ts,
        seasonal = seasonal,
        stepwise = TRUE,
        approximation = TRUE
      )
    }
  )
}

forecast_holdout <- function(arima_model, sarima_model, h) {
  list(
    arima = forecast::forecast(arima_model, h = h),
    sarima = forecast::forecast(sarima_model, h = h)
  )
}

get_model_order_text <- function(model) {
  paste(names(forecast::arimaorder(model)), forecast::arimaorder(model), sep = "=", collapse = ", ")
}

get_ljung_box_settings <- function(model, lag = 24) {
  fitdf <- length(model$coef)
  residual_count <- length(stats::na.omit(stats::residuals(model)))
  test_lag <- min(max(lag, fitdf + 1), residual_count - 1)

  list(
    lag_used = test_lag,
    model_df = fitdf
  )
}

run_ljung_box_test <- function(model, lag = 24) {
  settings <- get_ljung_box_settings(model, lag = lag)

  stats::Box.test(
    stats::residuals(model),
    lag = settings$lag_used,
    type = "Ljung-Box",
    fitdf = settings$model_df
  )
}

save_checkresiduals_plot <- function(
  model,
  output_file,
  lag = 24
) {
  grDevices::png(output_file, width = 1200, height = 900, res = 150)
  on.exit(grDevices::dev.off(), add = TRUE)
  tryCatch(
    forecast::checkresiduals(model, lag = lag),
    error = function(error) {
      plot(stats::residuals(model), main = "Model Residuals", ylab = "Residual", xlab = "Time")
      message("checkresiduals() could not complete: ", conditionMessage(error))
    }
  )
  output_file
}

summarise_residual_diagnostics <- function(arima_model, sarima_model, lag = 24) {
  arima_settings <- get_ljung_box_settings(arima_model, lag = lag)
  sarima_settings <- get_ljung_box_settings(sarima_model, lag = lag)
  arima_test <- run_ljung_box_test(arima_model, lag = lag)
  sarima_test <- run_ljung_box_test(sarima_model, lag = lag)

  tibble::tibble(
    model = c("ARIMA", "SARIMA"),
    ljung_box_lag = c(arima_settings$lag_used, sarima_settings$lag_used),
    model_df = c(arima_settings$model_df, sarima_settings$model_df),
    test_df = c(unname(arima_test$parameter), unname(sarima_test$parameter)),
    statistic = c(unname(arima_test$statistic), unname(sarima_test$statistic)),
    p_value = c(arima_test$p.value, sarima_test$p.value)
  )
}
