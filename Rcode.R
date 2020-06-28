#===============================================================================
# 2020/06/25
# COVID-19 Japan data collection project
# Fumiya Uchikoshi, uchikoshi@princeton.edu
# with a support from Ryohei Mogi, rmogi@ced.uab.es
#===============================================================================

######################################################################
# Loading packages
######################################################################
library(tidyverse)
library(lubridate)
library(readxl)
library(viridis)   
library(ggrepel)
library(sf)
library(colorspace)
library(NipponMap)
library(BAMMtools)

jpn_death_long <- read_csv("jpn_death_share.csv") %>% 
  mutate(Date=if_else(is.na(Date)==TRUE,Reporting,Date)) %>% 
  dplyr::select(-RegionJP, -RegionNo, -URL, -Reporting) %>% 
  mutate(Value=1) %>% 
  group_by(Date, Region, Sex, Age) %>%
  summarise(Value = sum(Value)) %>% 
  ungroup(Date, Region, Sex, Age) %>% 
  mutate(Sex = case_when(Sex == "M" ~ "m",
                         Sex == "F" ~ "f",
                         T ~ "UNK"),
         Age = factor(Age, levels = c("0", "10", "20", "30", "40", "50",
                                      "60", "70", "80", "90", "UNK")),
         Date = ymd(Date)) 

## Create region
region <- c("Hokkaido", "Aomori", "Iwate", "Miyagi", "Akita", "Yamagata", "Fukushima", "Ibaraki", "Tochigi", "Gunma", 
            "Saitama", "Chiba", "Tokyo", "Kanagawa", "Niigata", "Toyama", "Ishikawa", "Fukui", "Yamanashi", "Nagano", 
            "Gifu", "Shizuoka", "Aichi", "Mie", "Shiga", "Kyoto", "Osaka", "Hyogo", "Nara", "Wakayama", "Tottori", 
            "Shimane", "Okayama", "Hiroshima", "Yamaguchi", "Tokushima", "Kagawa", "Ehime", "Kochi", "Fukuoka", "Saga", 
            "Nagasaki", "Kumamoto", "Oita", "Miyazaki", "Kagoshima", "Okinawa")

region_id <- 1:47
Region <- cbind(region, region_id)
Region <- Region %>% 
  as.data.frame() %>% 
  mutate(region_id = as.numeric(as.character(region_id)))

## Create a box
mindate <- min(jpn_death_long$Date, na.rm = T)
maxdate <- max(jpn_death_long$Date, na.rm = T)
period <- seq(mindate, maxdate, 1)
#age <- unique(jpn_death_long$Age)
age <- c("0", "10", "20", "30", "40", "50",
         "60", "70", "80", "90", "UNK")
sex <- unique(jpn_death_long$Sex)

full_death <- data.frame("Date" = rep(period, length(region) * length(age) * length(sex)),
                         "Region" = rep(region, each = length(period), times = length(sex) * length(age)),
                         "Age" = rep(age, each = length(period) * length(region), times = length(sex)),
                         "Sex" = rep(sex, each = length(period) * length(region) * length(age))
)

D_death_jpn <- full_death %>% 
  left_join(Region, by = c("Region" = "region")) %>% 
  left_join(jpn_death_long, by = c("Region", "Date", "Age", "Sex")) %>% 
  mutate(Country = "Japan",
         AgeInt = case_when(Age == "90" ~ "15",
                            Age == "UNK" ~ "NA",
                            T ~ "10"),
         Metric = "Count",
         Measure = "Deaths",
         Datex = format(Date, format = "%d.%m.%Y"),
         PrefNo = if_else(region_id < 10, paste("0", region_id, sep = ""), as.character(region_id)),
         Code = paste("JP", PrefNo, Datex, sep = "_"),
         Value = ifelse(is.na(Value), 0, Value)) %>% 
  group_by(Region, Age, Sex) %>% 
  mutate(Value = cumsum(Value)) %>% 
  ungroup() %>% 
  mutate(Value = ifelse(is.na(Value), 0, Value)) %>% 
  dplyr::select(Country, Region, PrefNo, Code, Date, Sex, Age, AgeInt, Metric, Measure, Value)

df <- D_death_jpn %>% 
  filter(Date == max(jpn_death_long$Date, na.rm = T)) %>% 
  group_by(Region) %>% 
  summarise(Value = sum(Value)) 

df_age <- D_death_jpn %>% 
  filter(Date == max(jpn_death_long$Date, na.rm = T)) %>% 
  filter(Age >60 & Age　!="UNK") %>% 
  group_by(Region) %>% 
  summarise(Valuex = sum(Value)) %>% 
  ungroup() %>% 
  left_join(df,by="Region") %>% 
  mutate(prop=if_else(Valuex>10,100*Valuex/Value,NaN)) %>% #70才以上が占める割合
  dplyr::select(Region,prop)

df_sex <- D_death_jpn %>% 
  filter(Date == max(jpn_death_long$Date, na.rm = T)) %>% 
  filter(Sex !="UNK") %>% 
  group_by(Region,Sex) %>% 
  summarise(Value = sum(Value)) %>% 
  mutate(Valuex = lead(Value),
         ratio=if_else(Valuex>=10 & Value >= 10,Valuex/Value,NaN)) %>% 
  filter(is.na(Valuex) != TRUE) %>% 
  dplyr::select(Region,ratio)

shp <- system.file("shapes/jpn.shp", package = "NipponMap")[1]
dfm <- sf::read_sf(shp) %>% 
  left_join(df,by = c("name" = "Region")) %>% 
  left_join(df_age,by = c("name" = "Region")) %>% 
  left_join(df_sex,by = c("name" = "Region")) %>% 
  mutate(Value=if_else(Value==0,NaN,Value))
  
dfm_points <- sf::st_point_on_surface(dfm)
dfm_coords <- as.data.frame(sf::st_coordinates(dfm_points))
dfm_coords$NAME <- dfm$jiscode

######################################################################
# Data viz
######################################################################

ggplot() +
  geom_sf(data = dfm[, "Value"], aes(fill = Value))+
  coord_sf(datum = NA) + # 経緯度線を描画しない
  scale_fill_continuous_sequential(palette = "Heat")+labs(fill="# of deaths") + theme_void() #+ggtitle("Geographical distribution of COVID-19 related deaths in Japan as of June 19")
ggsave(height=6,width=9,dpi=200, filename="Viz/map_death.pdf",  family = "Helvetica")

ggplot() +
  geom_sf(data = dfm[, "Value"], aes(fill = Value))+
  coord_sf(datum = NA) + # 経緯度線を描画しない
  geom_label_repel(data = dfm_coords, aes(X, Y, label = NAME), colour = "black",label.size = 0.001,segment.size = 0.3,box.padding=0.3, alpha = 0.8)+
  scale_fill_continuous_sequential(palette = "Heat")+labs(fill="# of deaths") + theme_void() #+ggtitle("Geographical distribution of COVID-19 related deaths in Japan as of June 19")
ggsave(height=6,width=9,dpi=200, filename="Viz/map_name.pdf",  family = "Helvetica")

ggplot() +
  geom_sf(data = dfm[, "prop"], aes(fill = prop))+
  coord_sf(datum = NA) + # 経緯度線を描画しない
  scale_fill_continuous_sequential(palette = "Heat")+labs(fill="% of over 70") + theme_void() #+ggtitle("Geographical distribution of % over age 70 as of June 19")
ggsave(height=6,width=9,dpi=200, filename="Viz/map_prop.pdf",  family = "Helvetica")

ggplot() +
  geom_sf(data = dfm[, "ratio"], aes(fill = ratio))+
  coord_sf(datum = NA) + # 経緯度線を描画しない
  scale_fill_continuous_sequential(palette = "Heat")+labs(fill="% of over 70") + theme_void() #+ggtitle("Geographical distribution of sex ratio for COVID-19 deaths as of June 19")
ggsave(height=6,width=9,dpi=200, filename="Viz/map_ratio.pdf",  family = "Helvetica")

