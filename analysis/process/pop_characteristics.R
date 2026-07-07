#####################################################
# This code creates tables describing the
# demographics of people with outpatient visits,
# and on personalised follow-up pathways
# ###################################################

library(dplyr)
library(purrr)
library(rlang)
library(readr)
library(here)
library(fs)

# Create directory
dir_create(here::here("output", "processed"), showWarnings = FALSE, recurse = TRUE)


##### Functions

# Rounding and redaction
rounding <- function(vars) {
  case_when(vars == 0 ~ 0,
            vars > 7 ~ round(vars / 5) * 5)
}


# Frequency tables
freq <- function(data, var, name) {
  var <- enquo(var)
  
  data %>%
    mutate(
      total = n_distinct(patient_id),
      variable = name,
      before_2yr_gp = ifelse(before_2yr > 8, "8+", before_2yr),
      before_1yr_gp = ifelse(before_1yr > 4, "4+", before_1yr),
      after_2yr_gp  = ifelse(after_2yr > 8, "8+", after_2yr),
      after_1yr_gp  = ifelse(after_1yr > 4, "4+", after_1yr)
    ) %>%
    group_by(
      variable,
      category = as.character(!!var),
      total
    ) %>%
    summarise(count = n(), .groups = "drop")
}

build_freq_table <- function(data, specs, file) {
  table <- purrr::imap_dfr(
    specs,
    ~ rlang::inject(freq(data, !!.x, .y))
  ) %>%
    mutate(
      category = ifelse(is.na(category), "missing", category),
      total = rounding(total),
      count = rounding(count)
    ) %>%
    subset(
      (variable != "treatment function code") | (variable == "treatment function code" & count >= 100 )
  )
  
  write.csv(
    table,
    file = here::here("output", "processed", file),
    row.names = FALSE
  )
  
  table
}

#############################################

# Read in data

everyone_all <- read_csv(here::here("output", "dataset_everyone.csv.gz"))
everyone_pfu <- everyone_all %>% subset(any_pfu == TRUE)

rheum_all <- read_csv(here::here("output", "dataset_rheumatology.csv.gz"))
rheum_pfu <- rheum_all %>% subset(any_pfu == TRUE)

derm_all <- read_csv(here::here("output", "dataset_dermatology.csv.gz"))
derm_pfu <- derm_all %>% subset(any_pfu == TRUE)

gastro_all <- read_csv(here::here("output", "dataset_gastroenterology.csv.gz"))
gastro_pfu <- gastro_all %>% subset(any_pfu == TRUE) 

#############################################

# Define variables and labels in one place
all_specs <- exprs(
  age = age_opa_group,
  sex = sex,
  region = region,
  `personalised follow-up` = any_pfu,
  `personalised follow-up 2022` = any_pfu_2022,
  `personalised follow-up 2023` = any_pfu_2023,
  `personalised follow-up 2024` = any_pfu_2024,
  `personalised follow-up 2025` = any_pfu_2025,
  `treatment function code` = trt_func_code,
  `IMD decile` = imd_decile
)

pfu_specs <- exprs(
  age = age_pfu_group,
  sex = sex,
  region = region,
  `IMD decile` = imd_decile,
  `first PFU year` = first_pfu_year,
  `personalised follow-up 2022` = any_pfu_2022,
  `personalised follow-up 2023` = any_pfu_2023,
  `personalised follow-up 2024` = any_pfu_2024,
  `personalised follow-up 2025` = any_pfu_2025,
  `personalised follow-up category` = first_pfu_type,
  `treatment function code` = pfu_trt_func_code,
  `visits 2 years before` = before_2yr_gp,
  `visits 1 year before` = before_1yr_gp,
  `visits 2 years after` = after_2yr_gp,
  `visits 1 year after` = after_1yr_gp
)

#############################################

# Everyone with outpatient visit
table_everyone <- build_freq_table(
  data = everyone_all,
  specs = all_specs,
  file = "table_everyone.csv"
)

table_rheum <- build_freq_table(
  data = rheum_all,
  specs = all_specs,
  file = "table_rheum.csv"
)

table_derm <- build_freq_table(
  data = derm_all,
  specs = all_specs,
  file = "table_derm.csv"
)

table_gastro <- build_freq_table(
  data = gastro_all,
  specs = all_specs,
  file = "table_gastro.csv"
)


#############################################

# People with personalised follow-up only

table_everyone_pfu <- build_freq_table(
  data = everyone_pfu,
  specs = pfu_specs,
  file = "table_everyone_pfu.csv"
)

table_rheum_pfu <- build_freq_table(
  data = rheum_pfu,
  specs = pfu_specs,
  file = "table_rheum_pfu.csv"
)

table_derm_pfu <- build_freq_table(
  data = derm_pfu,
  specs = pfu_specs,
  file = "table_derm_pfu.csv"
)

table_gastro_pfu <- build_freq_table(
  data = gastro_pfu,
  specs = pfu_specs,
  file = "table_gastro_pfu.csv"
)
