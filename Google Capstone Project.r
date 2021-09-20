## Packages for the analysis
library(tidyverse) ## to wrangle data
library(lubridate) ## to wrangle date attributes
library(ggplot2) ## to visualize data
library(dplyr)
library(data.table)


## First, I merged all the data into a single file 

setwd('C:/Users/.../Case Study (Cyclistic)/csv')
files <- list.files(pattern = '.csv')
temp <- lapply(files, fread, sep = ',')
data <- rbindlist( temp )
write.csv(data, file = 'cyclistic_merged.csv', row.names = FALSE)

## Eliminating columns that I won't be using for my analysis
cyc_data <- select(data, -c(9, 10, 11, 12))

## CLEANING AND ANALYSIS

## Separating the dates into day of the week and time. I'll apply this to started_at and ended_at.
cyc_data$date <- as.Date(cyc_data$started_at) 
cyc_data$month <- format(as.Date(cyc_data$date), "%m")
cyc_data$day <- format(as.Date(cyc_data$date), "%d")
cyc_data$year <- format(as.Date(cyc_data$date), "%Y")
cyc_data$day_of_week <- format(as.Date(cyc_data$date), "%A")

## Filtering out NA values
trips <- cyc_data %>%
  filter(!is.na(start_station_id) & !is.na(end_station_id))

## Calculating a new column "ride_length" to check the duration of every trip  
trips$ride_length <- difftime(trips$ended_at,trips$started_at)

## Inspecting the results in ride_length
## Note: I got 10520 negative results which I decided to delete in the next step to create a cleaner dataframe, 
## I did it for practice purposes but in a real environment scenario I'd have to dig deeper to understand why that happens 
## and see if I can really discard them 
trips %>%
  select(ride_length) %>%
  filter(ride_length<0)

## Deleting negative ride_lengths and creating a new "trips" dataframe for further analysis
trips <- trips[!(trips$ride_length<0)]

## First, I checked how many users are members and casual and how many types of bikes there are
table(trips$member_casual)
table(trips$rideable_type)

## I made a descriptive analysis of ride length
mean(trips$ride_length)
median(trips$ride_length)
max(trips$ride_length)
min(trips$ride_length)

# Comparing members and casuals
aggregate(trips$ride_length ~ trips$member_casual, FUN = mean)
aggregate(trips$ride_length ~ trips$member_casual, FUN = median)
aggregate(trips$ride_length ~ trips$member_casual, FUN = max)
aggregate(trips$ride_length ~ trips$member_casual, FUN = min)

# Average ride_length per day_of_week for members and casuals
aggregate(trips$ride_length ~ trips$member_casual + trips$day_of_week, FUN = mean)

# Number of rides per day_of_week and avg_duration 
trips %>%
  mutate(weekday = wday(started_at)) %>% #creates weekday field using wday()
  group_by(member_casual, weekday) %>% #groups by usertype and weekday
  summarise(number_of_rides = n(),average_duration = mean(ride_length)) %>% # calculates the average duration
  arrange(member_casual, weekday)

## Number of rides and avg duration per year-month and per type of client
## Note: I couldn't find a way to calculate everything in one sitting, so I performed this calculation manually
## changing year, month, and member_casual. I know it wasn't optimal but I got the job done!
trips %>%
  select(member_casual, started_at, ended_at, ride_length) %>%
  filter(year == '2020') %>%
  group_by(member_casual) %>%
  summarise(number_of_rides = n(), avg = mean(ride_length))

## Number of rides and avg duration per customer and per type of bike
trips %>%
  select(rideable_type, member_casual, ride_length) %>%
  group_by(rideable_type, member_casual) %>%
    summarise(number_of_rides = n(), avg = mean(ride_length))
  
