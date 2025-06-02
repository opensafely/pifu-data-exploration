
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


# all outpatient visits
count_opa <- measures %>%
  rename(total_pop = denominator, count_opa = numerator) %>%
  subset(measure == "count_opa") %>%
  select(c("month", "count_opa", "total_pop"))

patients_opa <- measures %>%
  rename(patients_opa = numerator) %>%
  subset(measure == "patients_opa") %>%
  select(c("month", "patients_opa"))

 
# personalised follow-up visits only
count_pfu <- measures %>%
  rename(count_pfu = numerator) %>%
  subset(measure == "count_pfu") %>%
  select(c("month", "count_pfu"))

patients_pfu <- measures %>%
  rename(patients_pfu = numerator) %>%
  subset(measure == "patients_pfu")  %>%
  select(c("month", "patients_pfu"))


# rheumatology personalised follow-up visits only
count_pfu_rheum <- measures %>%
  rename(count_pfu_rheum = numerator) %>%
  subset(measure == "count_pfu_rheum") %>%
  select(c("month", "count_pfu_rheum"))

patients_pfu_rheum <- measures %>%
  rename(patients_pfu_rheum = numerator) %>%
  subset(measure == "patients_pfu_rheum")  %>%
  select(c("month", "patients_pfu_rheum"))


# "moved" to personalised follow-up visits only (outcome of attendance = 4)
count_pfu_moved <- measures %>%
  rename(count_pfu_moved = numerator) %>%
  subset(measure == "count_pfu_moved") %>%
  select(c("month", "count_pfu_moved"))

patients_pfu_moved <- measures %>%
  rename(patients_pfu_moved = numerator) %>%
  subset(measure == "patients_pfu_moved")  %>%
  select(c("month", "patients_pfu_moved"))


# "discharged" to personalised follow-up visits only (outcome of attendance = 5)
count_pfu_discharged <- measures %>%
  rename(count_pfu_discharged = numerator) %>%
  subset(measure == "count_pfu_discharged") %>%
  select(c("month", "count_pfu_discharged"))

patients_pfu_discharged <- measures %>%
  rename(patients_pfu_discharged = numerator) %>%
  subset(measure == "patients_pfu_discharged")  %>%
  select(c("month", "patients_pfu_discharged"))


# combined
all <- merge(count_opa, patients_opa) %>%
  merge(count_pfu) %>%
  merge(patients_pfu) %>%
  merge(count_pfu_rheum) %>%
  merge(patients_pfu_rheum) %>%
  merge(count_pfu_moved) %>%
  merge(patients_pfu_moved) %>%
  merge(count_pfu_discharged) %>%
  merge(patients_pfu_discharged)


# Save
write.csv(all, file = here::here("output", "processed", "time_series.csv"), row.names = FALSE)
