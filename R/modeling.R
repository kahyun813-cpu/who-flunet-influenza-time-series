# Modeling functions for ARIMA and SARIMA analysis.

create_weekly_ts <- function(processed_data) {
  values <- processed_data$percent_positive

  if (anyNA(values)) {
    values <- zoo::na.approx(values, na.rm = FALSE)
    values <- zoo::na.locf(values, na.rm = FALSE)
    values <- zoo::na.locf(values, fromLast = TRUE, na.rm = FALSE)
  }

  stats::ts(values, frequency = 52)
}

split_train_test <- function(ts_data, holdout_weeks = 52) {
  n_obs <- length(ts_data)

  if (n_obs <= holdout_weeks + 52) {
    stop(
      paste0(
        "Not enough observations for a ",
        holdout_weeks,
        "-week hold-out set. Found only ",
        n_obs,
        " observations."
      ),
      call. = FALSE
    )
  }

  train_end <- n_obs - holdout_weeks

  list(
    train = stats::window(ts_data, end = stats::time(ts_data)[train_end]),
    test = stats::window(ts_data, start = stats::time(ts_data)[train_end + 1])
  )
}

run_adf_test <- function(ts_data) {
  tseries::adf.test(stats::na.omit(ts_data))
}

fit_nonseasonal_arima <- function(train_ts) {
  forecast::auto.arima(
    train_ts,
    seasonal = FALSE,
    stepwise = FALSE,
    approximation = FALSE
  )
}

fit_seasonal_arima <- function(train_ts) {
  forecast::auto.arima(
    train_ts,
    seasonal = TRUE,
    stepwise = FALSE,
    approximation = FALSE
  )
}

forecast_models <- function(nonseasonal_model, seasonal_model, h) {
  list(
    nonseasonal = forecast::forecast(nonseasonal_model, h = h),
    seasonal = forecast::forecast(seasonal_model, h = h)
  )
}
