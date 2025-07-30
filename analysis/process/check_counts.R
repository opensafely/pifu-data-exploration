####################################################################
# compare counts of people with a rheumatology outpatient visits
# generated from two different dataset defs
####################################################################

# Import libraries #
library('tidyverse')
library('fs')

# Create directory
dir_create(here::here("output", "processed"), showWarnings = FALSE, recurse = TRUE)


##### Functions

# Create frequency distribution
freq <- function(var, name) {
  df %>%
    mutate(total = n_distinct(patient_id), variable = name) %>%
    group_by(variable, category = as.character({{var}}), total) %>%
    summarise(count = n()) %>%
    ungroup()
}

#####

# output from "generate_dataset"
df <- read_csv(here::here("output", "dataset_everyone.csv.gz")) 
count_everyone <- rbind(
  freq(any_opa_410, "All rheumatology - full dataset"),
  freq(any_pfu_410, "PFU rheumatology - full dataset")
)

# output fromn"generate_dataset_rheum"
df <- read_csv(here::here("output", "dataset_rheum.csv.gz")) 
count_rheum <- rbind(
  freq(any_opa_410, "All rheumatology - rheum-only dataset"),
  freq(any_pfu_410, "PFU rheumatology - rheum-only dataset")
)

# combine and save
both <- rbind(count_everyone, count_rheum)
write.csv(both, file = here::here("output", "processed", "check_counts.csv"), row.names = FALSE)
