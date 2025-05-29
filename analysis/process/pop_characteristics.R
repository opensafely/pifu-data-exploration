
# Import libraries #
library('tidyverse')
library('fs')
library('gtsummary')

library('janitor')

# Create directory
dir_create(here::here("output", "dataset"), showWarnings = FALSE, recurse = TRUE)

dataset <- read_csv(here::here("output", "dataset.csv.gz")) 


# Create frequency distribution
freq <- function(var, name) {
  pfu <- dataset %>%
    subset(any_pfu == TRUE) %>%
    mutate(pfu_total = n(), variable = name) %>%
    group_by(variable, category = as.character({{var}}), pfu_total) %>%
    summarise(pfu_count = n()) 
  
  no_pfu <- dataset %>%
    subset(any_pfu == FALSE) %>%
    mutate(no_pfu_total = n(), variable = name) %>%
    group_by(variable, category = as.character({{var}}), no_pfu_total) %>%
    summarise(no_pfu_count = n()) 
  
  both <- merge(pfu, no_pfu)
  
  return(both)
  
}

table <- rbind(
  freq(age_group, "age"),
  freq(sex, "sex"),
  freq(region, "region"),
  freq(first_pfu_year, "first PFU year"),
  freq(treatment_function_code, "treatment function code")
)

write.csv(table, file = here::here("output", "dataset", "table.csv"), row.names = FALSE)