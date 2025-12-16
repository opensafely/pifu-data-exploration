
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


measures_rheum_stp_cnt_opa <- read_csv(here::here("output", "measures", "measures_rheum_stp_cnt_opa.csv")) %>%
  select(c("stp", "interval_start", "numerator", "denominator")) %>%
  rename(month = interval_start, count_opa = numerator, total_pop = denominator) 
  
measures_rheum_stp_cnt_pfu <- read_csv(here::here("output", "measures", "measures_rheum_stp_cnt_pfu.csv")) %>%
  select(c("stp", "interval_start", "numerator", "denominator")) %>%
  rename(month = interval_start, count_pfu = numerator, opa_pop = denominator) 

measures_rheum_stp_pat_opa <- read_csv(here::here("output", "measures", "measures_rheum_stp_pat_opa.csv")) %>%
  select(c("stp", "interval_start", "numerator")) %>%
  rename(month = interval_start, patients_opa = numerator) 

measures_rheum_stp_pat_pfu <- read_csv(here::here("output", "measures", "measures_rheum_stp_pat_pfu.csv")) %>%
  select(c("stp", "interval_start", "numerator")) %>%
  rename(month = interval_start, patients_pfu = numerator) 


opa <- measures_rheum_stp_cnt_opa %>% 
  merge(measures_rheum_stp_pat_opa, all = T) %>%
  replace(is.na(.), 0) %>%
  mutate(across(c(starts_with(c("count","patients","total","any","opa"))), rounding)) %>%
  mutate(opa_rate = count_opa / total_pop * 1000)

pfu <- measures_rheum_stp_cnt_pfu %>% 
  merge(measures_rheum_stp_pat_pfu, all = T) %>%
  replace(is.na(.), 0) %>%
  mutate(across(c(starts_with(c("count","patients","total","any","pfu"))), rounding)) %>%
  mutate(pfu_rate = patients_pfu / opa_pop * 1000)

#save 
write.csv(opa, file = here::here("output", "processed", "ts_rheum_stp_opa.csv"), row.names = FALSE)
write.csv(pfu, file = here::here("output", "processed", "ts_rheum_stp_pfu.csv"), row.names = FALSE)


ggplot(opa) +
  geom_line(aes(x = month, y = opa_rate, group = stp, colour = stp)) +
  scale_colour_discrete(guide = "none") +
  theme_bw()

ggsave(here::here("output", "processed", "rheum_stp_opa.png"),
       width = 12, height = 8, units = "cm")

ggplot(pfu) +
  geom_line(aes(x = month, y = pfu_rate, group = stp, colour = stp)) +
  scale_colour_discrete(guide = "none") +
  theme_bw()

ggsave(here::here("output", "processed", "rheum_stp_pfu.png"),
       width = 12, height = 8, units = "cm")
