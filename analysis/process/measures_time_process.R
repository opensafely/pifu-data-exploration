
# Import libraries #
library('tidyverse')
library('fs')

# Create directory
dir_create(here::here("output", "processed"), recurse = TRUE)


measures_time <- read_csv(here::here("output", "measures", "measures_time.csv")) %>%
  select(measure, numerator, denominator, interval_start) %>%
  rename(n_patients = denominator) %>%
  pivot_wider(names_from = measure, values_from = numerator) 

measures_wide <- measures_time %>%
  mutate(time = seq_len(nrow(measures_time)),
         period = case_when(
           time < 13 ~ "Pre-PFU",
           time == 13 ~ "PFU",
           time > 13 ~ "Post-PFU"
         )) %>%
  select(!interval_start)


# Save
write.csv(measures_wide, file = here::here("output", "processed", "outpatient_time.csv"), row.names = FALSE)


###########################################################

