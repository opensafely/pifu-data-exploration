
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
freq <- function(df, var, name) {
  df %>%
    mutate(total = n(), variable = name) %>%
    group_by(variable, category = as.character({{var}}), total) %>%
    summarise(count = n()) 
}

#####



dataset <- read_csv(here::here("output", "dataset.csv.gz")) %>%
  mutate(count_pfu_gp = ifelse(count_pfu >= 6, "6+", as.character(count_pfu)))

pfu <- dataset %>% subset(any_pfu == TRUE)
pfu_moved <- dataset %>% subset(any_pfu == TRUE & pfu_cat == "4")
pfu_discharged <- dataset %>% subset(any_pfu == TRUE & pfu_cat == "5")
pfu_rheum <- dataset %>% subset(any_pfu == TRUE & treatment_function_code == "410")


# People with personalised follow-up only
table_pfu <- rbind(
    freq(pfu, age_group, "age"),
    freq(pfu, sex, "sex"),
    freq(pfu, region, "region"),
    freq(pfu, first_pfu_year, "first PFU year"),
    freq(pfu, treatment_function_code, "treatment function code"),
    freq(pfu, count_pfu_gp, "number of pfu records")
  ) %>%
  mutate(pfu_all_count = rounding(count), pfu_all_total = rounding(total)) %>%
  subset(variable != "treatment function code" | ((variable == "treatment function code" & count >= 100))) %>%
  select(!c("count", "total"))

# People "moved" to personalised follow-up only (outcome_of_attendance = 4)
table_pfu_moved <- rbind(
  freq(pfu_moved, age_group, "age"),
  freq(pfu_moved, sex, "sex"),
  freq(pfu_moved, region, "region"),
  freq(pfu_moved, first_pfu_year, "first PFU year"),
  freq(pfu_moved, treatment_function_code, "treatment function code"),
  freq(pfu_moved, pfu_cat, "personalised followup category"),
  freq(pfu_moved, count_pfu_gp, "number of pfu records")
) %>%
  mutate(pfu_moved_count = rounding(count), pfu_moved_total = rounding(total)) %>%
  subset(variable != "treatment function code" | ((variable == "treatment function code" & count >= 100))) %>%
  select(!c("count", "total"))

# People "discharged" to personalised follow-up only (outcome_of_attendance = 5)
table_pfu_discharged <- rbind(
  freq(pfu_discharged, age_group, "age"),
  freq(pfu_discharged, sex, "sex"),
  freq(pfu_discharged, region, "region"),
  freq(pfu_discharged, first_pfu_year, "first PFU year"),
  freq(pfu_discharged, treatment_function_code, "treatment function code"),
  freq(pfu_discharged, pfu_cat, "personalised followup category"),
  freq(pfu_discharged, count_pfu_gp, "number of pfu records")
) %>%
  mutate(pfu_discharged_count = rounding(count), pfu_discharged_total = rounding(total)) %>%
  subset(variable != "treatment function code" | ((variable == "treatment function code" & count >= 100))) %>%
  select(!c("count", "total"))

# People with rheumatology personalised follow-up only
table_rheum <- rbind(
    freq(pfu_rheum, age_group, "age"),
    freq(pfu_rheum, sex, "sex"),
    freq(pfu_rheum, region, "region"),
    freq(pfu_rheum, first_pfu_year, "first PFU year"),
    freq(pfu_rheum, treatment_function_code, "treatment function code"),
    freq(pfu_rheum, pfu_cat, "personalised followup category"),
    freq(pfu_rheum, count_pfu_gp, "number of pfu records")
  ) %>%
    mutate(pfu_rheum_count = rounding(count), pfu_rheum_total = rounding(total)) %>%
    select(!c("count", "total"))


# Combine into one table
table_pfu_all <- merge(table_pfu, table_rheum, all = T) %>% 
  merge(table_pfu_moved, all = T) %>% 
  merge(table_pfu_discharged, all = T)


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
write.csv(table_pfu_all, file = here::here("output", "processed", "table_pfu.csv"), row.names = FALSE)
write.csv(table, file = here::here("output", "processed", "table.csv"), row.names = FALSE)
write.csv(table_rheum, file = here::here("output", "processed", "table_rheum.csv"), row.names = FALSE)


