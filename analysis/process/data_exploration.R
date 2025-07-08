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

opa <- read_csv(here::here("output", "dataset_explore.csv.gz")) %>%
  mutate(same_day = ifelse(count_same_day >= 6, ">=6", count_same_day),
         rheum_same_day = ifelse(count_same_day_rheum >= 6, ">=6", count_same_day_rheum),
         same_day_attended = ifelse(count_same_day_attended >= 6, ">=6", count_same_day_attended),
         rheum_same_day_attended = ifelse(count_same_day_rheum_attended >= 6, ">=6", count_same_day_rheum_attended),
         count_all_gp = ifelse(count_all >= 12, ">=12", count_all),
         count_all_attended_gp = ifelse(count_all_attended >= 12, ">=12", count_all_attended),
         count_rheum_gp = ifelse(count_rheum >= 12, ">=12", count_rheum),
         count_rheum_attended_gp = ifelse(count_rheum_attended >=12, ">=12", count_rheum_attended),
         rrr_year_gp = ifelse(rrr_year < 2020, "<2020", rrr_year),
         rheum_rrr_year_gp = ifelse(rheum_rrr_year < 2020, "<2020", rheum_rrr_year))
       
pfu <- opa %>% subset(pfu == TRUE)

#####

df <- opa

table <- rbind(
  freq(outcome_of_attendance, "outcome of attendance"),
  freq(treatment_function_code, "treatment function code"),
  freq(attendance_status, "attendance status"),
  freq(consultation_medium_used, "consultation medium used"),
  freq(first_attendance, "first attendance"),
  freq(rrr_year_gp, "year of referral"),
  freq(same_day, "no. days with multiple visits"),
  freq(same_day_attended, "no. days with multiple attended visits"),
  freq(count_all_gp, "total outpatient visits"),
  freq(count_all_attended_gp, "total attended outpatient visits"),
  freq(pfu, "pfu")
) %>%
  mutate(count = rounding(count), total = rounding(total), what = "All outpatient") 
  

table_rheum <- rbind(
  freq(rheum_outcome_of_attendance, "outcome of attendance"),
  freq(rheum_treatment_function_code, "treatment function code"),
  freq(rheum_attendance_status, "attendance status"),
  freq(rheum_consultation_medium_used, "consultation medium used"),
  freq(rheum_first_attendance, "first attendance"),
  freq(rheum_rrr_year_gp, "year of referral"),
  freq(rheum_same_day, "no. days with multiple visits"),
  freq(rheum_same_day_attended, "no. days with multiple attended visits"),
  freq(count_rheum_gp, "total rheumatology visits"),
  freq(count_rheum_attended_gp, "total attended rheumatology visits"),
  freq(pfu, "pfu")
) %>%
  mutate(count = rounding(count), total = rounding(total), what = "Rheumatology") 

both <- rbind(table, table_rheum) %>%
  subset(!(variable == "treatment function code") | (variable == "treatment function code" & count >= 1000)) 
  

# Save
write.csv(both, file = here::here("output", "processed", "table_explore.csv"), row.names = FALSE)


#####

quantile <- scales::percent(c(0,.1,.25,.5,.75,.9,.95,.99,100))
  
counts <- opa %>%
  summarise_at(vars(c("count_all","count_all_attended","count_rheum","count_rheum_attended")),
               list(min = ~quantile(., 0, na.rm = TRUE),
                    p10 = ~quantile(., .10, na.rm = TRUE),
                    p25 = ~quantile(., .25, na.rm = TRUE),
                    p50 = ~quantile(., .50, na.rm = TRUE),
                    p75 = ~quantile(., .75, na.rm = TRUE),
                    p90 = ~quantile(., .90, na.rm = TRUE),
                    p95 = ~quantile(., .95, na.rm = TRUE),
                    p99 = ~quantile(., .99, na.rm = TRUE))) %>%
  reshape2::melt() 

write.csv(counts, file = here::here("output", "processed", "counts_explore.csv"), row.names = FALSE)

