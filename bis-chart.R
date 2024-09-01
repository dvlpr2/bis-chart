library(magrittr)
library (dplyr)
library(ggplot2)

# ------------------------------------------------------------------------------
# unzip a remote file into a df
# ------------------------------------------------------------------------------
get_data <- function(ziiped_data_url, filename) {
  tmp_file <- tempfile()
  download.file(ziiped_data_url, tmp_file)
  unzipped_data <- unz(tmp_file, filename)
  df <- read.csv(unzipped_data, sep=',', check.names = FALSE)
  unlink(tmp_file)
  return(df)
}

cols <- c("2016-S1", "2016-S2", "2017-S1", "2017-S2", "2018-S1", "2018-S2",
          "2019-S1", "2019-S2", "2020-S1", "2020-S2", "2021-S1", "2021-S2",
          "2022-S1", "2022-S2", "2023-S1")

# ------------------------------------------------------------------------------
get_x_labels <- function(cols) {
# #  res <- cols %>% substr(3,4)
#   res <- cols %>% ifelse(grepl("S2"), substr(3,4), substr(3,7))
#
#   res <- data.frame(year = res)
  years <- c("16", "16-S2", "17", "17-S2", "18", "18-S2",
             "19", "19-S2", "20", "20-S2", "21", "21-S2",
             "22", "22-S2", "23")
  res <- data.frame(year = years)
  return(res)
}

# ------------------------------------------------------------------------------
summarise_notionals <- function(notionals_df, cols) {
  res <-
    notionals_df %>%
    dplyr::select(all_of(cols)) %>%
    dplyr::summarise_all(function (x) sum(x, na.rm = TRUE)/(10**6))
  rownames(res) <- c("value")
  res <- res %>% t()
  res <- data.frame(value = res)
  rownames(res) <- c()
  return(res)
}

# ------------------------------------------------------------------------------
get_notional_by_risk_category <- function(notionals_df, risk_category) {
  res <-
    notionals_df %>%
    dplyr::filter(
      Measure == "Outstanding - notional amounts",
      `Risk category` == risk_category
    )
  return(res)
}

# ------------------------------------------------------------------------------
get_all <- function(notionals_df, cols) {
  res <-
    notionals_df %>%
    get_notional_by_risk_category("Total (all risk categories)") %>%
    summarise_notionals(cols)
  return(res)
}

# ------------------------------------------------------------------------------
get_ir <- function(notionals_df, cols) {
  res <-
    notionals_df %>%
    get_notional_by_risk_category("Interest rate") %>%
    dplyr::filter(
      Maturity %in% c("Total (all maturities)"),
      Instrument %in% c("Forward rate agreements",
                        "Interest rate swaps",
                        "Options",
                        "Other instruments"),
      `Counterparty sector` %in% c("Non-financial customers",
                                   "Other financial institutions",
                                   "Reporting dealers"),
      DER_CURR_LEG1 == "TO1",
      DER_CURR_LEG2 == "TO1"
    ) %>%
    summarise_notionals(cols)
  return(res)
}

# ------------------------------------------------------------------------------
get_fx <- function(notionals_df, cols) {
  res <-
    notionals_df %>%
    get_notional_by_risk_category("Foreign exchange") %>%
    dplyr::filter(
      Maturity %in% c("Total (all maturities)"),
      Instrument %in% c("Outright forwards and FX swaps",
                        "Currency swaps",
                        "Options",
                        "Other instruments"),
      `Counterparty sector` %in% c("Non-financial customers",
                                   "Other financial institutions",
                                   "Reporting dealers"),
      DER_CURR_LEG1 == "TO1",
      DER_CURR_LEG2 == "TO1"
    ) %>%
    summarise_notionals(cols)
  return(res)
}

# ------------------------------------------------------------------------------
get_equity <- function(notionals_df, cols) {
  res <-
    notionals_df %>%
    get_notional_by_risk_category("Equity") %>%
    dplyr::filter(
      Maturity %in% c("Over 1 year and up to 5 years",
                      "Up to and including 1 year",
                      "Over 5 years"),
      Instrument %in% c("Forwards and swaps",
                        "Options"),
      `Counterparty sector` %in% c("Non-financial customers",
                                   "Other financial institutions",
                                   "Reporting dealers"),
      DER_CURR_LEG1 == "TO1",
      DER_CURR_LEG2 == "TO1"
    ) %>%
    summarise_notionals(cols)
  return(res)
}

# ------------------------------------------------------------------------------
get_commodities <- function(notionals_df, cols) {
  res <-
    notionals_df %>%
    get_notional_by_risk_category("Commodities") %>%
    dplyr::filter(
      Maturity %in% c("Total (all maturities)"),
      Instrument %in% c("Forwards and swaps",
                        "Options")
    ) %>%
    summarise_notionals(cols)
  return(res)
}

# ------------------------------------------------------------------------------
get_credit <- function(notionals_df, cols) {
  res <-
    notionals_df %>%
    get_notional_by_risk_category("Credit Derivatives") %>%
    dplyr::filter(
      Maturity %in% c("Over 1 year and up to 5 years",
                      "Up to and including 1 year",
                      "Over 5 years"),
      Instrument %in%    c("Credit default swaps"),
      `Counterparty sector` %in%
        c("Non-financial customers",
          "Other financial institutions",
          "Reporting dealers")
    ) %>%
    summarise_notionals(cols)
  return(res)
}

# ------------------------------------------------------------------------------
# main
# ------------------------------------------------------------------------------
draw_bis_chart <- function() {
  zipped_data_location <- "https://data.bis.org/static/bulk/WS_OTC_DERIV2_csv_col.zip"
  filename <- "WS_OTC_DERIV2_csv_col.csv"

  notionals_df <- get_data(zipped_data_location, filename)
  print(dim(notionals_df))
  colnames(notionals_df)

  # ------------------------------------------------------------------------------
  # get all notionals per category
  # ------------------------------------------------------------------------------
  all_notionals <- notionals_df %>% get_all(cols)
  ir_notionals <- notionals_df %>% get_ir(cols)
  fx_notionals <- notionals_df %>% get_fx(cols)
  eq_notionals <- notionals_df %>% get_equity(cols)
  com_notionals <- notionals_df %>% get_commodities(cols)
  credit_notionals <- notionals_df %>% get_credit(cols)

  # ------------------------------------------------------------------------------
  # Prepare dataframes for charts
  # ------------------------------------------------------------------------------
  x_labels <- get_x_labels(cols)
  curve_group <- rbind(
    data.frame(year=x_labels$year, risk="Total", value=all_notionals),
    data.frame(year=x_labels$year, risk="Interest rate", value=ir_notionals)
  )

  bar_group <- rbind(
    data.frame(year=x_labels$year, risk="Foreign Exchange", value=fx_notionals),
    data.frame(year=x_labels$year, risk="Equity", value=eq_notionals),
    data.frame(year=x_labels$year, risk="Commodity", value=com_notionals),
    data.frame(year=x_labels$year, risk="Credit", value=credit_notionals)
  )

  # ------------------------------------------------------------------------------
  # Plot
  # ------------------------------------------------------------------------------
  res <-
    ggplot() +
    ggtitle("A. Notional amounts outstanding") +
    geom_bar(data=bar_group, aes(x=year,y=6*value,fill=risk), stat="identity", position = "stack", alpha=0.8)+
    scale_y_continuous(breaks=seq(0,700,100), sec.axis = sec_axis(~./6, breaks=seq(0,120,30)))+
    geom_line(data=curve_group, aes(x=year, y=value, color=risk, group=risk), linetype="solid", linewidth=3)+
    scale_color_manual(values=c('blue', 'red'))+
    theme(axis.text=element_text(size=30)) +
    labs(x = NULL, y = NULL) +
    scale_x_discrete(breaks = x_labels$year[seq(1, length(x_labels$year), by = 2)]) +
    theme(
      plot.title = element_text(color="black", size=30),
      panel.grid.major = element_line(linewidth = 2),
      panel.grid.minor = element_blank(),
      plot.margin=unit(c(0.5,0,0.5,0), 'cm'),
      legend.position="bottom",
      legend.title = element_blank(),
      legend.text=element_text(size=30)
    )

  return(res)
}
