
# Import libraries #
library('tidyverse')
library('fs')

# Create directory
dir_create(here::here("output", "processed"), recurse = TRUE)


measures_time <- read_csv(here::here("output", "measures", "measures_time.csv")) %>%
  mutate(time = seq(1,24,1),
         period = ifelse(time < 13, "Pre-PFU", "Post-PFU")) %>%
  select(period, time, numerator, denominator) %>%
  rename(n_outpatient = numerator, n_patients = denominator)


# Save
write.csv(measures_time, file = here::here("output", "processed", "outpatient_time.csv"), row.names = FALSE)


###########################################################

