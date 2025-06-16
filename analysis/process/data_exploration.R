#####################################################
# To explore distribution of various columns in
#  outpatient data
# ###################################################


# Import libraries #
library('tidyverse')
library('fs')

# Create directory
dir_create(here::here("output", "processed"), showWarnings = FALSE, recurse = TRUE)


##### Functions

# Rounding and redaction
rounding <- function(vars) {
  case_when(vars == 0 ~ 0,
            vars > 7 ~ round(vars / 5) * 5)
}

# Create frequency distribution
freq <- function(var, name) {
  df %>%
    mutate(total = n(), variable = name) %>%
    group_by(variable, category = as.character({{var}}), total) %>%
    summarise(count = n()) 
}

#####

opa <- read_csv(here::here("output", "dataset_explore.csv.gz"))
pfu <- opa %>% subset(pfu == TRUE)

#####

df <- opa

table <- rbind(
  freq(outcome_of_attendance, "outcome of attendance"),
  freq(treatment_function_code, "treatment function code"),
  freq(attendance_status, "attendance status"),
  freq(consultation_medium_used, "consultation medium used"),
  freq(first_attendance, "first attendance"),
  freq(pfu, "pfu")
) %>%
  mutate(count = rounding(count), total = rounding(total)) %>%
  subset(!(variable == "treatment function code") | (variable == "treatment_function_code" & count >= 100))

# Save
write.csv(table, file = here::here("output", "processed", "table_explore.csv"), row.names = FALSE)

####

df <- pfu

table_pfu <- rbind(
  freq(outcome_of_attendance, "outcome of attendance"),
  freq(treatment_function_code, "treatment function code"),
  freq(attendance_status, "attendance status"),
  freq(consultation_medium_used, "consultation medium used"),
  freq(first_attendance, "first attendance"),
  freq(pfu, "pfu")
) %>%
  mutate(count = rounding(count), total = rounding(total)) %>%
  subset(!(variable == "treatment function code") | (variable == "treatment_function_code" & count >= 100))

# Save
write.csv(table_pfu, file = here::here("output", "processed", "table_pfu_explore.csv"), row.names = FALSE)

