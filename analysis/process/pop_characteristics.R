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


everyone <- read_csv(here::here("output", "dataset.csv.gz")) %>%
  mutate(count_pfu_gp = ifelse(count_pfu >= 6, "6+", as.character(count_pfu)),
         before_2yr_any = (before_2yr > 0),
         before_1yr_any = (before_1yr > 0),
         after_1yr_any = (after_1yr > 0))


pfu <- everyone %>% subset(any_pfu == TRUE)
pfu_moved <- everyone %>% subset(any_pfu == TRUE & pfu_cat == "4")
pfu_discharged <- everyone %>% subset(any_pfu == TRUE & pfu_cat == "5")
pfu_rheum <- everyone %>% subset(any_pfu == TRUE & pfu_treatment_function_code == "410")
rheum <- everyone %>% subset(treatment_function_code == "410")


####

# People with personalised follow-up only
df <- pfu
table_pfu <- rbind(
    freq(age_group, "age"),
    freq(sex, "sex"),
    freq(region, "region"),
    freq(first_pfu_year, "first PFU year"),
    freq(treatment_function_code, "treatment function code"),
    freq(pfu_cat, "personalised followup category"),
    freq(count_pfu_gp, "number of pfu records"),
    freq(before_2yr_any, "any visit 2 yrs pre"),
    freq(before_1yr_any, "any visit 1 yr pre"),
    freq(after_1yr_any, "any visit 1 yr post")
  ) %>%
  mutate(pfu_all_count = count, pfu_all_total = total) %>%
  select(!c("count", "total"))

# People "moved" to personalised follow-up only (outcome_of_attendance = 4)
df <- pfu_moved
table_pfu_moved <- rbind(
  freq(age_group, "age"),
  freq(sex, "sex"),
  freq(region, "region"),
  freq(first_pfu_year, "first PFU year"),
  freq(treatment_function_code, "treatment function code"),
  freq(pfu_cat, "personalised followup category"),
  freq(count_pfu_gp, "number of pfu records"),
  freq(before_2yr_any, "any visit 2 yrs pre"),
  freq(before_1yr_any, "any visit 1 yr pre"),
  freq(after_1yr_any, "any visit 1 yr post")
) %>%
  mutate(pfu_moved_count = count, pfu_moved_total = total) %>%
  select(!c("count", "total"))

# People "discharged" to personalised follow-up only (outcome_of_attendance = 5)
df <- pfu_discharged
table_pfu_discharged <- rbind(
  freq(age_group, "age"),
  freq(sex, "sex"),
  freq(region, "region"),
  freq(first_pfu_year, "first PFU year"),
  freq(treatment_function_code, "treatment function code"),
  freq(pfu_cat, "personalised followup category"),
  freq(count_pfu_gp, "number of pfu records"),
  freq(before_2yr_any, "any visit 2 yrs pre"),
  freq(before_1yr_any, "any visit 1 yr pre"),
  freq(after_1yr_any, "any visit 1 yr post")
) %>%
  mutate(pfu_discharged_count = count, pfu_discharged_total = total) %>%
  select(!c("count", "total"))

# People with rheumatology personalised follow-up only
df <- pfu_rheum
table_pfu_rheum <- rbind(
    freq(age_group, "age"),
    freq(sex, "sex"),
    freq(region, "region"),
    freq(first_pfu_year, "first PFU year"),
    freq(treatment_function_code, "treatment function code"),
    freq(pfu_cat, "personalised followup category"),
    freq(count_pfu_gp, "number of pfu records"),
    freq(before_2yr_any, "any visit 2 yrs pre"),
    freq(before_1yr_any, "any visit 1 yr pre"),
    freq(after_1yr_any, "any visit 1 yr post")
  ) %>%
    mutate(pfu_rheum_count = count, pfu_rheum_total = total) %>%
    select(!c("count", "total"))


# Combine into one table
table_pfu_all <- merge(table_pfu, table_pfu_rheum, all = T) %>% 
  merge(table_pfu_moved, all = T) %>% 
  merge(table_pfu_discharged, all = T) %>%
  fill(ends_with("total")) %>%
  replace(is.na(.), 0) %>%
  mutate(across(c(starts_with("pfu")), rounding),
         category = ifelse(category == 0, "missing", category))  


# Everyone with outpatient visit
df <- everyone
table <- rbind(
    freq(age_group, "age"),
    freq(sex, "sex"),
    freq(region, "region"),
    freq(treatment_function_code, "treatment function code"),
    freq(any_pfu, "personalised follow-up")
  ) %>%
    mutate(count = rounding(count), total = rounding(total),
           category = ifelse(is.na(category), "missing", category))

# Everyone rheumatology patient with outpatient visit 
df <- rheum
table_rheum <- rbind(
  freq(age_group, "age"),
  freq(sex, "sex"),
  freq(region, "region"),
  freq(treatment_function_code, "treatment function code"),
  freq(any_pfu, "personalised follow-up")
) %>%
  mutate(count = rounding(count_rheum), total = rounding(total_rheum),
         category = ifelse(is.na(category), "missing", category))


# Combine into one table
table_everyone <- merge(table, table_rheum, all = T) %>% 
  fill(ends_with("total")) %>%
  replace(is.na(.), 0) %>%
  mutate(across(c(starts_with(c("count", "total"))), rounding),
         category = ifelse(category == 0, "missing", category))  



# Save
write.csv(table_pfu_all, file = here::here("output", "processed", "table_pfu.csv"), row.names = FALSE)
write.csv(table, file = here::here("output", "processed", "table.csv"), row.names = FALSE)
write.csv(table_rheum, file = here::here("output", "processed", "table_rheum.csv"), row.names = FALSE)


#########


## Function to calculate median/IQR
options(scipen = 999)

quantile <- scales::percent(c(.25,.5,.75))
  

visits <- pfu %>%
  subset(first_pfu_year < 2025) %>%
  summarise_at(vars(c("before_2yr","before_1yr","after_1yr","days_from_last_visit","days_to_next_visit")),
               list(p25 = ~quantile(., .25, na.rm = TRUE),
                    p50 = ~quantile(., .5, na.rm=TRUE),
                    p75 = ~quantile(., .75, na.rm=TRUE))) %>%
  reshape2::melt()

write.csv(visits, file = here::here("output", "processed", "visits_stats.csv"), row.names = FALSE)


#########
