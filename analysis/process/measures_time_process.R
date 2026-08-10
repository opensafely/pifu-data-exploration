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
      group = if_else(
        measure %in% c("opa_spec_count_type","opa_count_type"),
        "By PFU type", "All PFU"),
      specialist = if_else(
        measure %in% c("opa_spec_count", "opa_spec_count_type"),
        "Specialist","All attendances"),
      time = dense_rank(interval_start),
      period = case_when(
        time < 16 ~ "Pre-PFU",
        time == 16 ~ "PFU",
        TRUE ~ "Post-PFU"),
      rate = numerator / denominator * 100) %>%
    rename(n_patients = denominator, n_attendances = numerator) %>%
    select(n_patients, n_attendances, time, period, type, group, specialist)
  
  write_csv(
    measures_time,
    here("output", "processed", glue("outpatient_time_{specialty}.csv"))
  )
  
  invisible(measures_time)
}

process_measures_time("rheum")
process_measures_time("gastro")
process_measures_time("derm")


# Description of outpatient_time* files 

#These files capture the number of outpatient attendances per 100 patients over 4-week periods relative to when patients 
#were placed on PIFU (patient-initiated follow-up). This was done for rheumatology, gastroenterology, and dermatology.
#The study population is all people who had a recorded flag for having been placed on a PIFU pathway for each
#specialty. 

#- n_patients: Number of patients with a PIFU flag who were still alive and registered in that 4-week period;
#- n_attendances: Number of outpatient attendances in that 4-week period;
#- time: Time period;
#- period: Whether the time period is pre- or post- being placed on a PIFU pathway;
#- type: Whether the row is for people MOVED (4) vs DISCHARGED (5) to a PIFU pathway, or all combined (NA);
#- group: Whether the row is group by type ("PFU type"), or all combined ("All PFU");
#- specialist: Whether the attendances included are ALL outpatient attendances, or just those for the given specialty (rheumatology, gastro, dermatology).
