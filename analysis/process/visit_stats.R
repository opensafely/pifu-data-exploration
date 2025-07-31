#####################################################
# This code creates tables describing the
# demographics of people with outpatient visits,
# and on personalised follow-up pathways
# ###################################################


# Import libraries #
library('tidyverse')
library('fs')

# Create directory
dir_create(here::here("output", "processed"), showWarnings = FALSE, recurse = TRUE)


## Function to calculate median/IQR
options(scipen = 999)

quantile <- scales::percent(c(0,.25,.5,.75,100))


rheum_visits <- read_csv(here::here("output", "dataset_rheum.csv.gz")) %>% 
  subset(any_pfu == TRUE & first_pfu_year < 2025) %>%
  summarise_at(vars(c("before_2yr","before_1yr","after_1yr",
                      "days_from_last_visit","days_to_next_visit")),
               list(min = ~quantile(., 0, na.rm = TRUE),
                    p25 = ~quantile(., .25, na.rm = TRUE),
                    p50 = ~quantile(., .5, na.rm=TRUE),
                    p75 = ~quantile(., .75, na.rm=TRUE),
                    p90 = ~quantile(., .9, na.rm = TRUE))) %>%
  reshape2::melt() 

write.csv(rheum_visits, file = here::here("output", "processed", "visit_stats.csv"), row.names = FALSE)


#########
