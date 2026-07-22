
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


prepare_measures <- function(file, output_file, region = FALSE) {
  
  data <- readr::read_csv(
    here::here("output", "measures", file)
  )
  
  if (region) {
    
    data <- data %>%
      select(measure, interval_start, numerator, denominator, region) %>%
      rename(month = interval_start) %>%
      filter(!(measure %in% c(
        "count_opa", "patients_opa",
        "count_pfu", "patients_pfu"
      ))) %>%
      pivot_wider(
        names_from = measure,
        values_from = c(numerator, denominator)
      ) %>%
      rename(
        denominator_pfu = denominator_patients_pfu_region,
        denominator_opa = denominator_patients_opa_region,
        count_opa = numerator_count_opa_region,
        count_pfu = numerator_count_pfu_region
      ) %>%
      select(
        -starts_with("numerator"),
        -starts_with("denominator_count"),
        -starts_with("denominator_patients")
      ) %>%
      mutate(region = tidyr::replace_na(region, "Missing"))
    
  } else {
    
    data <- data %>%
      select(measure, interval_start, numerator, denominator) %>%
      rename(month = interval_start) %>%
      filter(measure %in% c(
        "count_opa", "patients_opa",
        "count_pfu", "patients_pfu",
        "count_pfu4", "count_pfu5",
        "patients_pfu4", "patients_pfu5"
      )) %>%
      pivot_wider(
        names_from = measure,
        values_from = c(numerator, denominator)
      ) %>%
      rename(
        denominator_pfu = denominator_patients_pfu,
        denominator_opa = denominator_patients_opa,
        count_opa = numerator_count_opa,
        count_pfu = numerator_count_pfu,
        count_pfu4 = numerator_count_pfu4,
        count_pfu5 = numerator_count_pfu5
      ) %>%
      select(
        -starts_with("numerator"),
        -starts_with("denominator_count"),
        -starts_with("denominator_patients")
      )
  }
  
  # Save processed data
  readr::write_csv(
    data,
    here::here("output", "processed", output_file)
  )
  
  # Return processed data
  return(data)
}


measures_everyone <- prepare_measures(
  file = "measures_everyone.csv",
  output_file = "ts_everyone.csv"
)

measures_region_everyone <- prepare_measures(
  file = "measures_everyone.csv",
  output_file = "ts_region_everyone.csv",
  region = TRUE
)

###
measures_rheum <- prepare_measures(
  file = "measures_rheum.csv",
  output_file = "ts_rheum.csv"
)

measures_region_rheum <- prepare_measures(
  file = "measures_rheum.csv",
  output_file = "ts_region_rheum.csv",
  region = TRUE
)

###
measures_derm <- prepare_measures(
  file = "measures_derm.csv",
  output_file = "ts_rheum_processed.csv"
)

measures_region_derm <- prepare_measures(
  file = "measures_derm.csv",
  output_file = "ts_region_rheum.csv",
  region = TRUE
)

###
measures_gastro <- prepare_measures(
  file = "measures_gastro.csv",
  output_file = "ts_gastro.csv"
)

measures_region_gastro <- prepare_measures(
  file = "measures_gastro.csv",
  output_file = "ts_region_gastro.csv",
  region = TRUE
)
