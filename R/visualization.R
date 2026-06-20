# Visualization functions for exploratory time series analysis.

plot_percent_positive <- function(processed_data) {
  ggplot2::ggplot(processed_data, ggplot2::aes(x = .data$week_start, y = .data$percent_positive)) +
    ggplot2::geom_line(color = "#1f78b4", linewidth = 0.7, na.rm = TRUE) +
    ggplot2::scale_y_continuous(
      labels = scales::label_percent(scale = 1),
      limits = c(0, NA)
    ) +
    ggplot2::labs(
      title = "Weekly Influenza Percent Positivity in Canada",
      subtitle = "WHO FluNet data, 2015-2019",
      x = "Week",
      y = "Percent positive"
    ) +
    ggplot2::theme_minimal()
}

save_percent_positive_plot <- function(
  processed_data,
  output_file = here::here("figures", "canada_percent_positive_timeseries.png")
) {
  plot <- plot_percent_positive(processed_data)
  ggplot2::ggsave(output_file, plot = plot, width = 9, height = 5, dpi = 300)
  output_file
}

plot_stl_decomposition <- function(ts_data) {
  forecast::autoplot(stats::stl(ts_data, s.window = "periodic")) +
    ggplot2::labs(title = "STL Decomposition of Influenza Percent Positivity") +
    ggplot2::theme_minimal()
}

save_stl_plot <- function(
  ts_data,
  output_file = here::here("figures", "stl_decomposition.png")
) {
  plot <- plot_stl_decomposition(ts_data)
  ggplot2::ggsave(output_file, plot = plot, width = 9, height = 7, dpi = 300)
  output_file
}

save_acf_pacf_plots <- function(
  ts_data,
  acf_file = here::here("figures", "acf_percent_positive.png"),
  pacf_file = here::here("figures", "pacf_percent_positive.png")
) {
  acf_plot <- forecast::ggAcf(ts_data) +
    ggplot2::labs(title = "ACF of Influenza Percent Positivity") +
    ggplot2::theme_minimal()

  pacf_plot <- forecast::ggPacf(ts_data) +
    ggplot2::labs(title = "PACF of Influenza Percent Positivity") +
    ggplot2::theme_minimal()

  ggplot2::ggsave(acf_file, plot = acf_plot, width = 8, height = 5, dpi = 300)
  ggplot2::ggsave(pacf_file, plot = pacf_plot, width = 8, height = 5, dpi = 300)

  c(acf = acf_file, pacf = pacf_file)
}
