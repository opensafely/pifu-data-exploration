
# Import libraries #
library(dplyr)
library(readr)
library(tidyr)
library(here)
library(glue)
library(tidyverse)
library(fs)

# Create directory
dir_create(here::here("output", "processed"), recurse = TRUE)

process_measures_time <- function(specialty) {
  
  measures_time <- read_csv(
    here("output", "measures", glue("measures_time_{specialty}.csv"))
  ) %>%
    mutate(
      type = replace_na(type, "All"),
      specialist = if_else(
        measure %in% c("opa_spec_count", "opa_spec_count_type"),
        "Specialist",
        "All"
      )
    ) %>%
    arrange(interval_date) %>%
    mutate(
      time = dense_rank(interval_date),
      period = case_when(
        time < 13 ~ "Pre-PFU",
        time == 13 ~ "PFU",
        TRUE ~ "Post-PFU"
      )
    ) %>%
    rename(
      n_patients = denominator,
      n_attendances = numerator
    ) %>%
    select(n_patients, n_attendances, time, period, type, specialist)
  
  write_csv(
    measures_time,
    here("output", "processed", glue("outpatient_time_{specialty}.csv"))
  )
  
  invisible(measures_time)
}

process_measures_time("rheum")
process_measures_time("gastro")
process_measures_time("derm")

