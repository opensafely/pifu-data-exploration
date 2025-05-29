

# Import libraries #
library('tidyverse')
library('fs')
library('gtsummary')

library('janitor')

# Create directory
dir_create(here::here("output", "dataset"), showWarnings = FALSE, recurse = TRUE)

dataset <- read_csv(here::here("output", "dataset.csv.gz")) %>%
  mutate(first_pfu_year = as.character(first_pfu_year))

freq <- function(var, name) {
  dataset %>%
    mutate(total = n(), variable = name) %>%
      group_by(variable, category = {{var}}, total) %>%
      summarise(count = n()) 
      
}

table <- rbind(
    freq(age_group, "age"),
    freq(sex, "sex"),
    freq(region, "region"),
    freq(first_pfu_year, "first PFU year"),
    freq(treatment_function_code, "treatment function code")
)

write.csv(table, file = here::here("output", "dataset", "table.csv"), row.names = FALSE)