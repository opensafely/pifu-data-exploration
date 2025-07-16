
# Import libraries #
library('tidyverse')
library('fs')

# Create directory
dir_create(here::here("output", "processed"), showWarnings = FALSE, recurse = TRUE)

# Rounding and redaction
rounding <- function(vars) {
  case_when(vars == 0 ~ 0,
            vars > 7 ~ round(vars / 5) * 5)
}



measures <- read_csv(here::here("output", "measures", "measures.csv")) %>%
  select(c("measure", "interval_start", "numerator", "denominator")) %>%
  subset(interval_start < as.Date("2025-07-01")) %>%
  rename(month = interval_start) 

measures_wide <- measures %>%
  select(!("denominator")) %>%
  spread("measure", "numerator")

measure_total_denom <- measures %>% 
  subset(measure == "count_opa") %>%
  select(c("denominator", "month")) %>%
  rename(total_pop = denominator)

measure_opa_denom <- measures %>% 
  subset(measure == "count_pfu") %>%
  select(c("denominator", "month")) %>%
  rename(opa_pop = denominator)

all <- measures_wide %>% 
  merge(measure_total_denom, all = T) %>%
  merge(measure_opa_denom, all = T) %>%
  replace(is.na(.), 0) %>%
  mutate(across(c(starts_with(c("count","patients","total","any","opa"))), rounding)) 

overall <- all %>%
  select(c("month", "total_pop", "opa_pop", "count_opa", "count_pfu", "patients_opa", "patients_pfu"))

by_specialty <- all %>%
  select(!c("count_opa", "count_pfu", "patients_opa", "patients_pfu"))


# Save
write.csv(overall, file = here::here("output", "processed", "time_series_overall.csv"), row.names = FALSE)
write.csv(by_specialty, file = here::here("output", "processed", "time_series_specialty.csv"), row.names = FALSE)

