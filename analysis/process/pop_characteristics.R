
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


dataset <- read_csv(here::here("output", "dataset.csv.gz")) 

# Create frequency distribution
freq <- function(df, var, name) {
  df %>%
    mutate(total = n(), variable = name) %>%
    group_by(variable, category = as.character({{var}}), total) %>%
    summarise(count = n()) 
}

pfu <- dataset %>% subset(any_pfu == TRUE)

# People with personalised follow-up only
table_pfu <- rbind(
  freq(pfu, age_group, "age"),
  freq(pfu, sex, "sex"),
  freq(pfu, region, "region"),
  freq(pfu, first_pfu_year, "first PFU year"),
  freq(pfu, treatment_function_code, "treatment function code")
) %>%
  subset(variable != "treatment function code" | ((variable == "treatment function code" & count >= 100))) %>%
  mutate(count = rounding(count), total = rounding(total))

# Everyone with outpatient visit
table <- rbind(
  freq(dataset, age_group, "age"),
  freq(dataset, sex, "sex"),
  freq(dataset, region, "region"),
  freq(dataset, treatment_function_code, "treatment function code"),
  freq(dataset, any_pfu, "personalised follow-up")
) %>%
  subset(variable != "treatment function code" | ((variable == "treatment function code" & count >= 100))) %>%
  mutate(count = rounding(count), total = rounding(total))


# Save
write.csv(table_pfu, file = here::here("output", "processed", "table_pfu.csv"), row.names = FALSE)
write.csv(table, file = here::here("output", "processed", "table.csv"), row.names = FALSE)
