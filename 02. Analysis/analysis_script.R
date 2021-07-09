# Update Working directory to this script path
library(rstudioapi)
script_dir = rstudioapi::getActiveDocumentContext()$path
setwd(dirname(script_dir))

# Load Packages
library(readr)
library(tidyverse)
library(dplyr)
library(lubridate)
library(skimr)
library(janitor)

# Add files to the list
files <- dir("CSV/", full.names = T)

# Combining all 12 files into a single csv file
combined <- map_df(files, read_csv, col_types = cols(start_station_id = col_character(),end_station_id = col_character()))
str(combined)
write_csv(combined, "combined_datasets.csv")

# Load the combined csv file
df <- read_csv("combined_datasets.csv", col_types = cols(start_station_id = col_character(),end_station_id = col_character()))
str(df)

# Due to computational power limitation, we need to take a random
# sample without replacement from total 4,073,561 observations
# Here is how the sample size was calculated
# Population size : 4,073,561
# Confidence level : 99.99%
# Margin of Error : 0.2
# Sample size: 767554

sample_df <- sample_n(df, 767554, replace=F)
str(sample_df)
write_csv(sample_df, "sample_dataset.csv")

# Load the sample dataset
df <- read_csv("sample_dataset.csv")

colnames(df)
nrow(df)  
dim(df) 
head(df)  
str(df)  
summary(df)

# Add new columns to calculate the following for each ride
# the length of each ride
# Date
# Year
# Month
# Day
# day of the week

df$date <- as.Date(df$started_at)
df$year <- format(as.Date(df$date), "%Y")
df$month <- format(as.Date(df$date), "%m")
df$day <- format(as.Date(df$date), "%d")

df <- df %>% 
  mutate(ride_length = ended_at - started_at) %>% 
  mutate(day_of_week = weekdays(as.Date(df$started_at)))

head(df)

# Removed rows which had negative ride_length
df <- df %>%
  filter(ride_length > 0)

#Clean columns names and removed duplicates 
df <- df %>% 
  clean_names() %>% 
  unique()

# Export cleaned df to a new csv
write_csv(df, "2020-2021_divvy-tripdata_cleaned.csv")
df <- read_csv("2020-2021_divvy-tripdata_cleaned.csv")

# Descriptive Analysis

# Descriptive analysis on ride_length (all figures in seconds)
summary(df$ride_length)
# Compare members and casual users
aggregate(df$ride_length ~ df$member_casual, FUN = mean)
aggregate(df$ride_length ~ df$member_casual, FUN = median)
aggregate(df$ride_length ~ df$member_casual, FUN = max)
aggregate(df$ride_length ~ df$member_casual, FUN = min)

# See the average ride time by each day for members vs casual users
aggregate(df$ride_length ~ df$member_casual + df$day_of_week, , FUN = mean)

# Sort days of the week
df$day_of_week <- ordered(df$day_of_week, levels=c("Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"))

# Analyze ridership data by type and weekday
df %>% 
  mutate(weekday = wday(started_at, label = TRUE)) %>%  
  group_by(member_casual, weekday) %>%  
  summarise(number_of_rides = n()
            ,average_duration = mean(ride_length)) %>%    
  arrange(member_casual, weekday)

# Visualize the number of rides by rider type
df %>% 
  mutate(weekday = wday(started_at, label = TRUE)) %>% 
  group_by(member_casual, weekday) %>% 
  summarise(number_of_rides = n()
            ,average_duration = mean(ride_length)) %>% 
  arrange(member_casual, weekday)  %>% 
  ggplot(aes(x = weekday, y = number_of_rides, fill = member_casual)) +
  geom_col(position = "dodge")

# Visualize average duration of ride by rider type
df%>% 
  mutate(weekday = wday(started_at, label = TRUE)) %>% 
  group_by(member_casual, weekday) %>% 
  summarise(number_of_rides = n()
            ,average_duration = mean(ride_length)) %>% 
  arrange(member_casual, weekday)  %>% 
  ggplot(aes(x = weekday, y = average_duration, fill = member_casual)) +
  geom_col(position = "dodge")

# EXPORT SUMMARY FILE FOR FURTHER ANALYSIS

# Total and Average number of weekly rides by rider type
summary_wd <- df %>% 
  mutate(weekday = wday(started_at, label = TRUE)) %>%  
  group_by(member_casual, weekday) %>%  
  summarise(number_of_rides = n()
            ,average_duration = mean(ride_length)) %>%    
  arrange(member_casual, weekday)
write_csv(summary_wd, "summary_ride_length_weekday.csv")

# Total and Average number of monthly rides by rider type
summary_month <- df %>% 
  mutate(month = month(started_at, label = TRUE)) %>%  
  group_by(month,member_casual) %>%  
  summarise(number_of_rides = n()
            ,average_duration = mean(ride_length)) %>%    
  arrange(month, member_casual)
write_csv(summary_month, "summary_ride_length_month.csv")

# Stations most used by each user group
summary_station <- df %>% 
  mutate(station = start_station_name) %>%
  drop_na(start_station_name) %>% 
  group_by(start_station_name, member_casual) %>%  
  summarise(number_of_rides = n()) %>%    
  arrange(number_of_rides)
write_csv(summary_station, "summary_stations.csv")
