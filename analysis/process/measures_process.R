
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
  rename(month = interval_start) %>%
  mutate(numerator = rounding(numerator), denominator = rounding(denominator))

count_opa <- measures %>%
  rename(total_pop = denominator, num_op_visits = numerator) %>%
  subset(measure == "count_opa") %>%
  select(c("month", "num_op_visits", "total_pop"))

patients_opa <- measures %>%
  rename(num_op_patients = numerator) %>%
  subset(measure == "patients_opa") %>%
  select(c("month", "num_op_patients"))
 
count_pfu <- measures %>%
  rename(num_pfu_visits = numerator) %>%
  subset(measure == "count_pfu") %>%
  select(c("month", "num_pfu_visits"))

patients_pfu <- measures %>%
  rename(num_pfu_patients = numerator) %>%
  subset(measure == "patients_pfu")  %>%
  select(c("month", "num_pfu_patients"))

all <- merge(count_opa, patients_opa) %>%
  merge(count_pfu) %>%
  merge(patients_pfu)


# Save
write.csv(all, file = here::here("output", "processed", "time_series.csv"), row.names = FALSE)
