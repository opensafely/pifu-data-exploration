
# Import libraries #
library('tidyverse')
library('fs')

# Create directory
dir_create(here::here("output", "processed"), recurse = TRUE)

# Rounding and redaction
rounding <- function(vars) {
  case_when(vars == 0 ~ 0,
            vars > 7 ~ round(vars / 5) * 5)
}


measures_time_rheum <- read_csv(here::here("output", "measures", "measures_time_rheum.csv")) %>%
  select(measure, numerator, denominator, interval_start, type) %>%
  rename(n_patients = denominator) %>%
  pivot_wider(names_from = measure, values_from = numerator) 

measures_wide_rheum <- measures_time_rheum %>%
  mutate(time = seq_len(nrow(measures_time_rheum)),
         period = case_when(
           time < 13 ~ "Pre-PFU",
           time == 13 ~ "PFU",
           time > 13 ~ "Post-PFU"
         )
         ) %>%
  select(!interval_start)

# Save
write.csv(measures_wide_rheum, file = here::here("output", "processed", "outpatient_time_rheum.csv"), row.names = FALSE)



##
measures_time_derm <- read_csv(here::here("output", "measures", "measures_time_derm.csv")) %>%
  select(measure, numerator, denominator, interval_start, type) %>%
  rename(n_patients = denominator) %>%
  pivot_wider(names_from = measure, values_from = numerator) 

measures_wide_derm <- measures_time_derm %>%
  mutate(time = seq_len(nrow(measures_time_derm)),
         period = case_when(
           time < 13 ~ "Pre-PFU",
           time == 13 ~ "PFU",
           time > 13 ~ "Post-PFU"
         )
  ) %>%
  select(!interval_start)

# Save
write.csv(measures_wide_derm, file = here::here("output", "processed", "outpatient_time_derm.csv"), row.names = FALSE)





##
measures_time_gastro <- read_csv(here::here("output", "measures", "measures_time_gastro.csv")) %>%
  select(measure, numerator, denominator, interval_start, type) %>%
  rename(n_patients = denominator) %>%
  pivot_wider(names_from = measure, values_from = numerator) 

measures_wide_gastro <- measures_time_gastro %>%
  mutate(time = seq_len(nrow(measures_time_gastro)),
         period = case_when(
           time < 13 ~ "Pre-PFU",
           time == 13 ~ "PFU",
           time > 13 ~ "Post-PFU"
         )
  ) %>%
  select(!interval_start)


# Save
write.csv(measures_wide_gastro, file = here::here("output", "processed", "outpatient_time_gastro.csv"), row.names = FALSE)


###########################################################

