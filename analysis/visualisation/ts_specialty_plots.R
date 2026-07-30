library(tidyverse)
library(dplyr)
library(tidyr)
library(readr)

prep_ts <- function(file, specialty_name) {
  read_csv(file) %>%
    transmute(
      month,
      specialty = specialty_name,
      pfu_rate  = if_else(count_pfu == 0, NA, count_pfu / count_opa *10000),
      pfu4_rate = if_else(count_pfu4 == 0, NA, count_pfu4 / count_opa *10000),
      pfu5_rate = if_else(count_pfu5 == 0, NA, count_pfu5 / count_opa *10000),
    ) %>%
    filter(month >= as.Date("2022-01-01"),
           month <  as.Date("2025-12-01")) %>%
    pivot_longer(
      cols = c(pfu_rate, pfu4_rate, pfu5_rate),
      names_to = "pfu_type",
      values_to = "pfu_rate"
    ) %>%
    mutate(
      pfu_type = recode(
        pfu_type,
        pfu_rate  = "All",
        pfu4_rate = "Moved",
        pfu5_rate = "Discharged"
      )
    )
}

ts_all <- bind_rows(
  prep_ts("C:/Users/aschaffer/OneDrive - Nexus365/Documents/GitHub/pifu-data-exploration/output/ts_rheum.csv", "Rheumatology"),
  prep_ts("C:/Users/aschaffer/OneDrive - Nexus365/Documents/GitHub/pifu-data-exploration/output/ts_derm.csv", "Dermatology"),
  prep_ts("C:/Users/aschaffer/OneDrive - Nexus365/Documents/GitHub/pifu-data-exploration/output/ts_gastro.csv", "Gastroenterology")
)

ts_all$specialty <- factor(ts_all$specialty, levels = c("Rheumatology", 
                                                      "Dermatology",
                                                      "Gastroenterology"))

ts_all$pfu_type <- factor(ts_all$pfu_type, levels = c("All", "Discharged", "Moved"),
labels = c("All personalised follow-up","Discharged to personalised follow-up pathway",
                                                    "Moved to personalised follow-up pathway"))



ggplot(ts_all) +
  geom_line(aes(x = month, y = pfu_rate, col = pfu_type), linewidth =  1) +
  scale_colour_viridis_d(option = "D") +
  xlab("Month") + 
  ylab("Personalised follow-up episodes\nper 10,000 outpatient attendances") +
  facet_wrap(~ specialty) +
  theme_bw() +
  theme(text = element_text(size = 10),
        panel.grid.major.x = element_blank(),
        panel.grid.minor.x = element_blank(),
        axis.text.x = element_text(size = 10, angle = 45, hjust=1),
        axis.text.y = element_text(size = 10),
        legend.title = element_blank(),
        strip.text = element_text(hjust = 0, size = 10),
        strip.background = element_blank(),
        legend.text = element_text(size = 10),
        legend.position = "bottom")


ggplot(subset(ts_all, pfu_type != "All")) +
  geom_line(aes(x = month, y = pfu_rate, col = pfu_type)) +
  scale_colour_manual(values = c("dodgerblue3","maroon")) +
  xlab("Month") + 
  ylab("Personalised follow-up episodes\nper 10,000 outpatient attendances") +
 # facet_wrap(~ specialty) +
  theme_bw() +
  theme(text = element_text(size = 10),
        panel.grid.major.x = element_blank(),
        panel.grid.minor.x = element_blank(),
        axis.text.x = element_text(size = 10, angle = 45, hjust=1),
        axis.text.y = element_text(size = 10),
        legend.title = element_blank(),
        strip.text = element_text(hjust = 0, size = 10),
        strip.background = element_blank())
