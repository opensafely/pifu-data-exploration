
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

# Read in data
df <- read_csv(here::here("output", "dataset_everyone.csv.gz")) 

count_everyone <- freq(any_opa_410, "Rheumatology - full dataset")


df <- read_csv(here::here("output", "dataset_rheum.csv.gz")) 

count_rheum <- freq(any_opa_410, "Rheumatology - rheum-only dataset")

both <- rbind(count_everyone, count_rheum)

# Save
write.csv(both, file = here::here("output", "processed", "test_counts.csv"), row.names = FALSE)
