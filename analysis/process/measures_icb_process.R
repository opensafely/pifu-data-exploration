
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


measures_stp_1 <- read_csv(here::here("output", "measures", paste0("measures_stp_1.csv"))) %>%
  subset(interval_start < as.Date("2025-06-01")) %>%
  select(!"ratio") %>%
  rename(month = interval_start) 

measures_stp_2 <- read_csv(here::here("output", "measures", paste0("measures_stp_2.csv"))) %>%
  subset(interval_start < as.Date("2025-06-01")) %>%
  select(!"ratio") %>%
  rename(month = interval_start) 

measures_wide <- measures_stp_1 %>%
  select(!("denominator")) %>%
  spread("measure", "numerator")

measure_total_denom <- measures_stp_1 %>% 
  subset(measure == "count_opa") %>%
  select(c("denominator", "month")) %>%
  rename(total_pop = denominator)

measure_opa_denom <- measures_stp_1 %>% 
  subset(measure == "count_pfu") %>%
  select(c("denominator", "month")) %>%
  rename(opa_pop = denominator)

all <- measures_wide %>% 
  merge(measure_total_denom, all = T) %>%
  merge(measure_opa_denom, all = T) %>%
  replace(is.na(.), 0) %>%
  mutate(across(c(starts_with(c("count","patients","total","any","opa"))), rounding),
         stp = stp)

stp_pop <- all %>%
  select(c("stp", "month", "total_pop", "count_opa", "count_pfu", "patients_opa", "patients_pfu"))
stp_opa <- all %>%
  select(c("stp", "month", "count_opa", "patients_opa"))
stp_pfu <- all %>%
  select(c("stp", "month", "count_pfu", "patients_pfu"))

# Save
write.csv(stp_pop, file = here::here("output", "processed", "ts_stp_pop.csv"), row.names = FALSE)
write.csv(stp_opa, file = here::here("output", "processed", "ts_stp_opa.csv"), row.names = FALSE)
write.csv(stp_pfu, file = here::here("output", "processed", "ts_stp_pfu.csv"), row.names = FALSE)



