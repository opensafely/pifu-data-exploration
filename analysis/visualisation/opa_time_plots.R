library(tidyverse)
library(readr)
library(dplyr)
library(purrr)
library(viridis)
library(here)
library(fs)

# Create directory
dir_create(here::here("output", "figures"), recurse = TRUE)

time_rheum <- read_csv(here::here("output","processed","outpatient_time_rheum.csv")) %>%
  mutate(time_since = time-16, specialty = "Rheumatology",
         opa_rate = n_attendances / n_patients * 100,
         opa_rate_lci = opa_rate - 1.96 * sqrt((opa_rate * (100 - opa_rate))/ n_patients),
         opa_rate_uci = opa_rate + 1.96 * sqrt((opa_rate * (100 - opa_rate))/ n_patients)
         )

time_rheum$type <- factor(time_rheum$type, levels = c(4,5), labels = c("Moved to personalised follow-up pathway",
                                                                       "Discharged to personalised follow-up pathway"))

time_rheum$specialist <- factor(time_rheum$specialist, levels = c("All attendances", "Specialist"),
                                labels = c("All attendances", "Rheumatology attendances"))
  
time_derm <- read_csv(here::here("output","processed","outpatient_time_derm.csv")) %>%
  mutate(time_since = time-16, specialty = "Dermatology",
         opa_rate = n_attendances / n_patients * 100,
         opa_rate_lci = opa_rate - 1.96 * sqrt((opa_rate * (100 - opa_rate))/ n_patients),
         opa_rate_uci = opa_rate + 1.96 * sqrt((opa_rate * (100 - opa_rate))/ n_patients)
  )

time_derm$type <- factor(time_derm$type, levels = c(4,5), labels = c("Moved to personalised follow-up pathway",
                                                                       "Discharged to personalised follow-up pathway"))

time_derm$specialist <- factor(time_derm$specialist, levels = c("All attendances", "Specialist"),
                                labels = c("All attendances", "Dermatology attendances"))

time_gastro <- read_csv(here::here("output","processed","outpatient_time_gastro.csv")) %>%
  mutate(time_since = time-16, specialty = "Gastroenterology",
         opa_rate = n_attendances / n_patients * 100,
         opa_rate_lci = opa_rate - 1.96 * sqrt((opa_rate * (100 - opa_rate))/ n_patients),
         opa_rate_uci = opa_rate + 1.96 * sqrt((opa_rate * (100 - opa_rate))/ n_patients)
  )

time_gastro$type <- factor(time_gastro$type, levels = c(4,5), labels = c("Moved to personalised follow-up pathway",
                                                                       "Discharged to personalised follow-up pathway"))

time_gastro$specialist <- factor(time_gastro$specialist, levels = c("All attendances", "Specialist"),
                                labels = c("All attendances", "Gastroenterology attendances"))


##################

base_theme <- theme_bw() +
  theme(
    panel.grid.major.x = element_blank(),
    panel.grid.minor.x = element_blank(),
    strip.background = element_blank(),
    strip.text = element_text(hjust = 0),
    legend.title = element_blank(),
    legend.text = element_text(size = 11),
    legend.position = "bottom"
  )

time_plot_nozero <- function(df){
  
  ggplot() +
    geom_line(data = subset(df, group== "By PFU type" & time_since <0),
              aes(x = time_since, y = opa_rate, col = type, group= type)) +
    geom_point(data = subset(df, group== "By PFU type" & time_since < 0),
               aes(x = time_since, y =opa_rate, col = type, group= type))+
    geom_errorbar(data = subset(df, group== "By PFU type" & time_since < 0),
                  aes(x = time_since, y = opa_rate, ymin = opa_rate_lci, ymax = opa_rate_uci, col = type), width = 0.2) +
    geom_line(data = subset(df, group== "By PFU type" & time_since > 0),
              aes(x = time_since, y = opa_rate, col = type, group= type)) +
    geom_point(data = subset(df, group== "By PFU type" & time_since > 0),
               aes(x = time_since, y =opa_rate, col = type, group= type))+
    geom_errorbar(data = subset(df, group== "By PFU type" & time_since > 0),
                  aes(x = time_since, y = opa_rate, ymin = opa_rate_lci, ymax = opa_rate_uci, col = type), width = 0.2) +
    geom_vline(xintercept = 0, linetype = "longdash", col = "gray80") +
    facet_wrap(~ specialist, scales = "free_y") + 
    scale_y_continuous( expand = expansion(mult = c(0.2, 0.2))) + 
    scale_colour_manual(values = c("#21908CFF","#440154FF")) +
    scale_x_continuous(breaks = c(-15, -12, -9, -6, -3, 0, 3, 6, 9, 12)) +
    ylab("No. attendances per 100 people") + xlab("4-week period relative to first personalised follow-up") +
    base_theme
  
}

time_plot_zero <- function(df){
  
  ggplot(subset(df, group== "By PFU type"),
         aes(x = time_since, y = opa_rate)) +
    geom_line(aes(col = type, group= type)) +
    geom_point(aes(col = type, group= type))+
    geom_errorbar(aes(ymin = opa_rate_lci, ymax = opa_rate_uci, col = type), width = 0.2) +
    geom_vline(xintercept = 0, linetype = "longdash", col = "gray80") +
    facet_wrap(~ specialist, scales = "free_y") + 
    scale_y_continuous( expand = expansion(mult = c(0.2, 0.2))) + 
    scale_colour_manual(values = c("#21908CFF","#440154FF")) +
    scale_x_continuous(breaks = c(-15, -12, -9, -6, -3, 0, 3, 6, 9, 12)) +
    ylab("No. attendances per 100 people") + xlab("4-week period relative to first personalised follow-up")+
    base_theme
}

######################


time_plot_nozero(time_rheum)
ggsave(here::here("output", "figures", "opa_rheum_nozero.png"), dpi = 300, units = "in", width = 11, height = 4)

time_plot_zero(time_rheum)
ggsave(here::here("output", "figures", "opa_rheum_zero.png"), dpi = 300, units = "in", width = 11, height = 4)

time_plot_nozero(time_derm)
ggsave(here::here("output", "figures", "opa_derm_nozero.png"), dpi = 300, units = "in", width = 11, height = 4)

time_plot_zero(time_derm)
ggsave(here::here("output", "figures", "opa_derm_zero.png"), dpi = 300, units = "in", width = 11, height = 4)

time_plot_nozero(time_gastro)
ggsave(here::here("output", "figures", "opa_gastro_nozero.png"), dpi = 300, units = "in", width = 11, height = 4)

time_plot_zero(time_gastro)
ggsave(here::here("output", "figures", "opa_gastro_zero.png"), dpi = 300, units = "in", width = 11, height = 4)


######################

time_plot_patients <- function(df){
  
  ggplot(df, aes(x=time_since, y = n_patients)) +
    geom_bar(stat = "identity", fill = "goldenrod2") +
    geom_vline(xintercept = 0, linetype = "longdash", col = "gray80", width = 2) +
    scale_y_continuous(limits = c(0,7000)) + 
    scale_x_continuous(breaks = c(-12, -9, -6, -3, 0, 3, 6, 9, 12)) +
    ylab("No. eligible people") + xlab("4-week period relative to first personalised follow-up")+
    theme_bw() +
    theme(panel.grid.major.x = element_blank(),
          panel.grid.minor.x = element_blank())
  
}

time_plot_patients(time_rheum)
ggsave(here::here("output", "figures", "opa_rheum_pat.png"), dpi = 300, units = "in", width = 6, height = 4)

time_plot_patients(time_derm)
ggsave(here::here("output", "figures", "opa_derm_pat.png"), dpi = 300, units = "in", width = 6, height = 4)

time_plot_patients(time_gastro)
ggsave(here::here("output", "figures", "opa_gastro_pat.png"), dpi = 300, units = "in", width = 6, height = 4)

