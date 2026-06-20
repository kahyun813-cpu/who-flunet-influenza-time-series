# Visualization functions for exploratory and forecast analysis.

save_percent_positive_plot <- function(
  processed_data,
  output_file = here::here("figures", "canada_percent_positive_timeseries.png")
) {
  plot <- ggplot2::ggplot(
    processed_data,
    ggplot2::aes(x = .data$week_start, y = .data$percent_positive)
  ) +
    ggplot2::geom_line(color = "#1f78b4", linewidth = 0.7) +
    ggplot2::geom_point(color = "#1f78b4", size = 0.9, alpha = 0.65) +
    ggplot2::scale_y_continuous(labels = scales::label_percent(scale = 1), limits = c(0, NA)) +
    ggplot2::labs(
      title = "Weekly Influenza Percent Positivity in Canada",
      subtitle = "WHO FluNet surveillance data, 2015-2019",
      x = "Week",
      y = "Percent positive"
    ) +
    ggplot2::theme_minimal()

  ggplot2::ggsave(output_file, plot = plot, width = 9, height = 5, dpi = 300)
  output_file
}

save_seasonal_plot <- function(
  processed_data,
  output_file = here::here("figures", "seasonal_plot_by_iso_week.png")
) {
  plot <- ggplot2::ggplot(
    processed_data,
    ggplot2::aes(
      x = .data$iso_week,
      y = .data$percent_positive,
      color = factor(.data$iso_year),
      group = .data$iso_year
    )
  ) +
    ggplot2::geom_line(linewidth = 0.8, alpha = 0.9) +
    ggplot2::scale_y_continuous(labels = scales::label_percent(scale = 1), limits = c(0, NA)) +
    ggplot2::scale_x_continuous(breaks = seq(1, 52, by = 4)) +
    ggplot2::labs(
      title = "Seasonal Pattern by ISO Week",
      subtitle = "Canada influenza percent positivity, 2015-2019",
      x = "ISO week",
      y = "Percent positive",
      color = "ISO year"
    ) +
    ggplot2::theme_minimal()

  ggplot2::ggsave(output_file, plot = plot, width = 9, height = 5, dpi = 300)
  output_file
}

save_stl_plot <- function(
  ts_data,
  output_file = here::here("figures", "stl_decomposition.png")
) {
  decomposition <- stats::stl(ts_data, s.window = "periodic")

  plot <- forecast::autoplot(decomposition) +
    ggplot2::labs(title = "STL Decomposition of Influenza Percent Positivity") +
    ggplot2::theme_minimal()

  ggplot2::ggsave(output_file, plot = plot, width = 9, height = 7, dpi = 300)
  output_file
}

save_acf_plot <- function(
  ts_data,
  output_file = here::here("figures", "acf_percent_positive.png")
) {
  plot <- forecast::ggAcf(ts_data) +
    ggplot2::labs(title = "ACF of Influenza Percent Positivity") +
    ggplot2::theme_minimal()

  ggplot2::ggsave(output_file, plot = plot, width = 8, height = 5, dpi = 300)
  output_file
}

save_pacf_plot <- function(
  ts_data,
  output_file = here::here("figures", "pacf_percent_positive.png")
) {
  plot <- forecast::ggPacf(ts_data) +
    ggplot2::labs(title = "PACF of Influenza Percent Positivity") +
    ggplot2::theme_minimal()

  ggplot2::ggsave(output_file, plot = plot, width = 8, height = 5, dpi = 300)
  output_file
}

save_forecast_comparison_plot <- function(
  train_data,
  test_data,
  forecasts,
  output_file = here::here("figures", "forecast_comparison_arima_sarima.png")
) {
  observed_data <- dplyr::bind_rows(
    train_data |> dplyr::mutate(series = "Training data"),
    test_data |> dplyr::mutate(series = "Hold-out test data")
  )

  forecast_data <- dplyr::bind_rows(
    tibble::tibble(
      week_start = test_data$week_start,
      percent_positive = as.numeric(forecasts$arima$mean),
      model = "ARIMA forecast"
    ),
    tibble::tibble(
      week_start = test_data$week_start,
      percent_positive = as.numeric(forecasts$sarima$mean),
      model = "SARIMA forecast"
    )
  )

  plot <- ggplot2::ggplot() +
    ggplot2::geom_line(
      data = observed_data,
      ggplot2::aes(x = .data$week_start, y = .data$percent_positive, color = .data$series),
      linewidth = 0.7
    ) +
    ggplot2::geom_line(
      data = forecast_data,
      ggplot2::aes(x = .data$week_start, y = .data$percent_positive, linetype = .data$model),
      color = "#d95f02",
      linewidth = 0.8
    ) +
    ggplot2::scale_y_continuous(labels = scales::label_percent(scale = 1), limits = c(0, NA)) +
    ggplot2::labs(
      title = "ARIMA and SARIMA Forecasts for the Hold-out Period",
      subtitle = "Final 52 weeks used as chronological test data",
      x = "Week",
      y = "Percent positive",
      color = NULL,
      linetype = NULL
    ) +
    ggplot2::theme_minimal()

  ggplot2::ggsave(output_file, plot = plot, width = 10, height = 5.5, dpi = 300)
  output_file
}
