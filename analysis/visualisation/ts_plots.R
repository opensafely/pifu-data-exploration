library(tidyverse)
library(readr)
library(dplyr)
library(purrr)
library(viridis)
library(here)
library(fs)


# Create directory
dir_create(here::here("output", "figures"), recurse = TRUE)

ts_overall <- read_csv(here::here("output","processed","ts_everyone.csv")) %>%
  mutate(pfu_rate = if_else(count_pfu == 0, NA_real_, count_pfu / count_opa *10000),
         region = "England") %>%
  subset(month >= as.Date("2022-01-01") &
           month < as.Date("2025-12-01")) %>%
  select(month, pfu_rate, region)

ts_regions <- read_csv(here::here("output","processed","ts_region_everyone.csv")) %>%
  mutate(pfu_rate = if_else(count_pfu == 0, NA, count_pfu / count_opa * 10000)) %>%
  filter(month >= as.Date("2022-01-01") & month < as.Date("2025-12-01")) %>%
  select(month, region, pfu_rate)

ts_regions <- rbind(ts_regions, ts_overall)

ts_regions$region <- factor(ts_regions$region,
                            levels = c("England","east","eastmidlands","london",
                                       "northeast","northwest","southeast",
                                       "southwest","westmidlands","yorkshire"),
                            labels = c("All of England","East","East Midlands","London",
                                       "Northeast","Northwest","Southeast",
                                       "Southwest","West Midlands","Yorkshire & the Humber")
)

facet_regions <- unique(ts_regions$region)


facet_cols <- c(
  "All of England" = "#440154FF",
  "East" = "#21908CFF",
  "East Midlands" = "#21908CFF",
  "London" = "#21908CFF",
  "Northeast" = "#21908CFF",
  "Northwest" = "#21908CFF",
  "Southeast" = "#21908CFF",
  "Southwest" = "#21908CFF",
  "West Midlands" = "#21908CFF",
  "Yorkshire & the Humber" = "#21908CFF"
)


plot_df <- crossing(ts_regions, facet_region = facet_regions) %>%
  mutate(
    colour_group = if_else(region == facet_region, facet_region, "other"),
    highlight = region == facet_region
  )

ggplot(plot_df, aes(x = month, y = pfu_rate, group = region)) +
  geom_line(aes(
    colour = colour_group,
    linewidth = highlight,
    alpha = highlight
  ), show.legend = FALSE) +
  facet_wrap(~ facet_region) +
  scale_colour_manual(values = c("other" = "grey80", facet_cols)) +
  scale_linewidth_manual(values = c(`TRUE` = 1, `FALSE` = 0.5)) +
  scale_alpha_manual(values = c(`TRUE` = 1, `FALSE` = 0.4)) +
  labs(x = "Month", y = "Personalised follow-up episodes\nper 10,000 outpatient attendances") +
  theme_bw() +
  theme(text = element_text(size = 10),
        panel.grid.major.x = element_blank(),
        panel.grid.minor.x = element_blank(),
        panel.grid.minor.y = element_blank(),
        axis.text.x = element_text(size = 10, angle = 45, hjust=1),
        axis.text.y = element_text(size = 10),
        strip.background = element_blank(),
        strip.text = element_text(hjust = 0))

ggsave(here("output", "figures", "ts_plot.png"), 
       dpi = 300, units = "in", width = 11, height = 6.5)

