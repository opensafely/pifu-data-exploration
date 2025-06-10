####################################################
# Time between visits stratified by time period 
# (before or after start of personalised follow-up)
####################################################


# Import libraries #
library(tidyverse)
library(fs)
library(anytime)
library(survminer)
library(survival)

# Create directory
dir_create(here::here("output", "processed"), showWarnings = FALSE, recurse = TRUE)
dir_create(here::here("output", "processed", "figures"), showWarnings = FALSE, recurse = TRUE)


##### Functions

# Rounding and redaction
rounding <- function(vars) {
  case_when(vars == 0 ~ 0,
            vars > 7 ~ round(vars / 5) * 5)
}


dataset <- read_csv(here::here("output", "dataset.csv.gz")) %>%
  mutate_at(vars(starts_with(c("before_3yr_date","after_date","first_pfu_date","first_opa_date"))), 
            as.Date, format="%Y-%m-%d") %>%
  mutate(last_date = as.Date("2025-03-30"))


# summarise columns
dataset_summ <- dataset %>% 
  summary() %>%
  as.data.frame()

# calculate time between visits and create censoring variable
#   for whether they had a subsequent visit or not
times <- dataset %>%
  subset(any_pfu == TRUE) %>%
  mutate(
    before_time_1 = ifelse(!is.na(before_3yr_date_2), 
                           as.numeric(before_3yr_date_2 - before_3yr_date_1),
                           as.numeric(first_pfu_date - before_3yr_date_1)),
    before_time_2 = ifelse(!is.na(before_3yr_date_3), 
                           as.numeric(before_3yr_date_3 - before_3yr_date_2),
                           as.numeric(first_pfu_date - before_3yr_date_2)),
    before_time_3 = ifelse(!is.na(before_3yr_date_4), 
                           as.numeric(before_3yr_date_4 - before_3yr_date_3),
                           as.numeric(first_pfu_date - before_3yr_date_3)),
    before_time_4 = ifelse(!is.na(before_3yr_date_5), 
                           as.numeric(before_3yr_date_5 - before_3yr_date_4),
                           as.numeric(first_pfu_date - before_3yr_date_4)),
    
    before_censor_1 = ifelse(!is.na(before_3yr_date_2), 1, 0),
    before_censor_2 = ifelse(!is.na(before_3yr_date_3), 1, 0),    
    before_censor_3 = ifelse(!is.na(before_3yr_date_4), 1, 0),    
    before_censor_4 = ifelse(!is.na(before_3yr_date_5), 1, 0),
    
    after_time_1 = ifelse(!is.na(after_date_2),
                          as.numeric(after_date_2 - after_date_1),
                          as.numeric(last_date - after_date_1)),
    after_time_2 = ifelse(!is.na(after_date_3),
                          as.numeric(after_date_3 - after_date_2),
                          as.numeric(last_date - after_date_2)),
    after_time_3 = ifelse(!is.na(after_date_4),
                          as.numeric(after_date_4 - after_date_3),
                          as.numeric(last_date - after_date_3)),
    after_time_4 = ifelse(!is.na(after_date_5),
                          as.numeric(after_date_5 - after_date_4),
                          as.numeric(last_date - after_date_4)),
    
    after_censor_1 = ifelse(!is.na(after_date_2), 1, 0),
    after_censor_2 = ifelse(!is.na(after_date_3), 1, 0),
    after_censor_3 = ifelse(!is.na(after_date_4), 1, 0),
    after_censor_4 = ifelse(!is.na(after_date_5), 1, 0)    
    )

# reshape wide to long and merge
days <- reshape2::melt(times, id = c("patient_id", "first_pfu_date", "last_date", "pfu_cat", "sex", "age", "region"),
                         value.name = "days") %>%
  subset(variable %in% c("after_time_1", "after_time_2", "after_time_3", "after_time_4", 
                         "before_time_1", "before_time_2", "before_time_3", "before_time_4")) %>%
  mutate(when = ifelse((variable %in% c("after_time_1", "after_time_2", "after_time_3", "after_time_4")),
                        "after","before")) %>%
  select(!variable) 

censor <- reshape2::melt(times, id = c("patient_id", "first_pfu_date", "last_date", "pfu_cat", "sex", "age", "region"),
                         value.name = "censor") %>%
  subset(variable %in% c("after_censor_1", "after_censor_2", "after_censor_3", "after_censor_4", 
                         "before_censor_1", "before_censor_2", "before_censor_3", "before_censor_4")) %>%
  mutate(when = ifelse((variable %in% c("after_censor_1", "after_censor_2", "after_censor_3", "after_censor_4")),
                       "after","before")) %>%
  select(!variable) 

both <- merge(days, censor) %>%
  mutate(days = as.numeric(days), censor = as.numeric(censor))

# save
write.csv(dataset_summ, file = here::here("output", "processed", "summary_stats.csv"), row.names = FALSE)
write.csv(both, file = here::here("output", "processed", "time_to_next_visit.csv"), row.names = FALSE)


# create KM curve
surv_object <- Surv(time = both$days, event = both$censor)
surv_object 

fit1 <- survfit(surv_object ~ when, data = both)
summary(fit1)

ggsurvplot(fit1, data = both)

ggsave(here::here("output", "processed", "figures", "time_to_next_visit.png"))