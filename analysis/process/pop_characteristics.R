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
    mutate(total = n_distinct(patient_id), variable = name) %>%
    group_by(variable, category = as.character({{var}}), total) %>%
    summarise(count = n()) %>%
    ungroup()
}

#####

# Read in data
everyone <- read_csv(here::here("output", "dataset_everyone.csv.gz")) %>%
  mutate(count_pfu_gp = ifelse(count_pfu >= 6, "6+", as.character(count_pfu)),
         before_2yr_any = (before_2yr > 0),
         before_1yr_any = (before_1yr > 0),
         after_1yr_any = (after_1yr > 0))
    
pfu <- everyone %>% subset(any_pfu == TRUE)
pfu_moved <- everyone %>% subset(any_pfu == TRUE & pfu_cat == "4")
pfu_discharged <- everyone %>% subset(any_pfu == TRUE & pfu_cat == "5")


rheum <- read_csv(here::here("output", "dataset_rheum.csv.gz")) %>%
  mutate(count_pfu_gp = ifelse(count_pfu >= 3, "3+", as.character(count_pfu)),
         before_2yr_any = (before_2yr > 0),
         before_1yr_any = (before_1yr > 0),
         after_1yr_any = (after_1yr > 0))

pfu_rheum <- rheum %>% subset(any_pfu == TRUE)
pfu_moved_rheum <- rheum %>% subset(any_pfu == TRUE & pfu_cat == "4")
pfu_discharged_rheum <- rheum %>% subset(any_pfu == TRUE & pfu_cat == "5")


#####################################


# Everyone with outpatient visit
df <- everyone
table <- rbind(
    freq(age_opa_group, "age"),
    freq(sex, "sex"),
    freq(region, "region"),
    freq(any_pfu, "personalised follow-up")
  ) %>%
  mutate(category = ifelse(is.na(category), "missing", category),
           who = "All outpatients")

table_spec <- everyone %>%
  select(starts_with(c("patient_id","any_opa_"))) %>%
  reshape2::melt(id = "patient_id") %>%
  mutate(category = substr(variable, 9, 11), total = n_distinct(patient_id)) %>%
  group_by(total, category) %>% 
  mutate(count = sum(value), who = "All outpatients", variable = "treatment_function_code") %>%
  ungroup() %>%
  select(c("variable", "category", "count", "who", "total")) %>%
  distinct() 

table_all <- table %>%
  rbind(table_spec) 
  
# rheumatology patient with outpatient visit 
df <- rheum
table_rheum <- rbind(
  freq(age_opa_group, "age"),
  freq(sex, "sex"),
  freq(region, "region"),
  freq(any_pfu, "personalised follow-up")
) %>%
  mutate(count = rounding(count), total = rounding(total),
         category = ifelse(is.na(category), "missing", category),
         who = "Rheumatology")

# Combine everyone and rheumatology
both <- table_all %>%
  rbind(table_rheum) %>%
  mutate(count = rounding(count), total = rounding(total)) 

# Save
write.csv(both, file = here::here("output", "processed", "table.csv"), row.names = FALSE)


#########


# People with personalised follow-up only
df <- pfu
table_pfu <- rbind(
  freq(age_pfu_group, "age"),
  freq(sex, "sex"),
  freq(region, "region"),
  freq(first_pfu_year, "first PFU year"),
  freq(pfu_cat, "personalised followup category"),
  freq(count_pfu_gp, "number of pfu records")
) %>%
  mutate(pfu_all_count = count, pfu_all_total = total) %>%
  select(!c("count", "total"))

table_pfu_spec <- pfu %>%
  select(starts_with(c("patient_id","any_pfu_"))) %>%
  reshape2::melt(id = "patient_id") %>%
  mutate(category = substr(variable, 9, 11),
         pfu_all_total = n_distinct(patient_id)) %>%
  group_by(pfu_all_total, category) %>% 
  mutate(pfu_all_count = sum(value), 
         variable = "treatment_function_code") %>%
  ungroup() %>%
  select(c("variable", "category", "pfu_all_count", "pfu_all_total")) %>%
  distinct() 

table_pfu_all <- table_pfu %>%
  rbind(table_pfu_spec) %>%
  mutate(across(c(starts_with("pfu")), rounding),
       category = ifelse(is.na(category), "missing", category)) %>%
  replace(is.na(.), 0) 
  
# Save
write.csv(table_pfu_all, file = here::here("output", "processed", "table_pfu.csv"), row.names = FALSE)


#####################


# People with personalised follow-up only
df <- pfu_rheum
table_pfu_rheum <- rbind(
  freq(age_pfu_group, "age"),
  freq(sex, "sex"),
  freq(region, "region"),
  freq(first_pfu_year, "first PFU year"),
  freq(pfu_cat, "personalised followup category"),
  freq(count_pfu_gp, "number of pfu records"),
  freq(before_2yr_any, "any visit 2 yrs pre"),
  freq(before_1yr_any, "any visit 1 yr pre"),
  freq(after_1yr_any, "any visit 1 yr post")
) %>%
  mutate(pfu_all_count = count, pfu_all_total = total) %>%
  select(!c("count", "total"))

# People "moved" to personalised follow-up only (outcome_of_attendance = 4)
df <- pfu_moved_rheum
table_pfu_moved_rheum <- rbind(
  freq(age_pfu_group, "age"),
  freq(sex, "sex"),
  freq(region, "region"),
  freq(first_pfu_year, "first PFU year"),
  freq(pfu_cat, "personalised followup category"),
  freq(count_pfu_gp, "number of pfu records"),
  freq(before_2yr_any, "any visit 2 yrs pre"),
  freq(before_1yr_any, "any visit 1 yr pre"),
  freq(after_1yr_any, "any visit 1 yr post")
) %>%
  mutate(pfu_moved_count = count, pfu_moved_total = total) %>%
  select(!c("count", "total"))

# People "discharged" to personalised follow-up only (outcome_of_attendance = 5)
df <- pfu_discharged_rheum
table_pfu_discharged_rheum <- rbind(
  freq(age_pfu_group, "age"),
  freq(sex, "sex"),
  freq(region, "region"),
  freq(first_pfu_year, "first PFU year"),
  freq(pfu_cat, "personalised followup category"),
  freq(count_pfu_gp, "number of pfu records"),
  freq(before_2yr_any, "any visit 2 yrs pre"),
  freq(before_1yr_any, "any visit 1 yr pre"),
  freq(after_1yr_any, "any visit 1 yr post")
) %>%
  mutate(pfu_discharged_count = count, pfu_discharged_total = total) %>%
  select(!c("count", "total"))

rheum_pfu <- merge(table_pfu_rheum, table_pfu_moved_rheum, all = T) %>%
  merge(table_pfu_discharged_rheum, all = T) %>% 
  fill(ends_with("total")) %>%
  replace(is.na(.), 0) %>%
  mutate(across(c(starts_with("pfu")), rounding),
         category = ifelse(category == 0, "missing", category),
         pfu_moved_count = ifelse(variable == "region" & pfu_moved_count == 0, NA, pfu_moved_count),
         pfu_discharged_count = ifelse(variable == "region" & pfu_discharged_count == 0, NA, pfu_discharged_count))  

# Save
write.csv(rheum_pfu, file = here::here("output", "processed", "table_rheum.csv"), row.names = FALSE)


###################

