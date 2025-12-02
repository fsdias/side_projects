####### Testing the Plackett-Luce model in Stan with cycling data

#I wrote this code to test/play with Plackett-Luce models. I used
#stage data I found here https://doi.org/10.6084/m9.figshare.24566542


#######Step 1 - Load the data and select individual time trial stages from the UCI World Tour 2017-2023
################################################################################
library(tidyverse)
library(stringr)
library(lubridate)
library(gt)
library(cmdstanr)

data <- read.csv("race_results_2017_2023.csv")

#Load a list with UCI World Tour Races and use it to filter the data
worldtour <- read.csv("worldtour.csv")
pattern <- str_c(worldtour$Race, collapse = "|")
data<-data |> 
  filter(str_detect(Race.Name, pattern))

#Remove female races
data<- data %>%
  filter(!str_detect(Race.Name, regex("Female|Femmes|Women|Femminile|Feminin|Ladies", ignore_case = TRUE)))

#Remove Under 23 races
data<- data %>%
  filter(!str_detect(Race.Name, regex("Under 23", ignore_case = TRUE)))

#Remove Team Time Trials
data<-data |> 
  filter(Team.Time.Trial==0)

#Remove riders who DNF, DNS, OTL, DSP, DF or DSQ
data<-data %>% 
  filter(!Rank %in% c("DNF", "DNS","OTL","DSP","DF","DSQ"))
data<-data |> 
  mutate(Rank=as.numeric(Rank))

#Create a unique stage identifier
data<-data |> 
  mutate(stage_id = cumsum(Rank==1))

#Identify Individual Time Trial stages based on the time of the stage winner

itt_stages<-data |>  
  filter(Rank==1) |> 
  mutate(Time=hms(Time)) |> 
  filter(hour(Time) < 1) |> #finishing time < 1 hour
  pull(stage_id)

data<- data |> 
  filter(stage_id %in% itt_stages)

#######Step 2 - Identify riders who participated in at least 12 ITT
###################################################################

eligible_riders<- data |> 
  group_by(Name) |> 
  summarise(n_itts=n_distinct(stage_id)) |> 
  filter(n_itts>=12) |> 
  pull(Name)

#Filter the data to include only races in which any of these riders participated
data <- data |> 
  semi_join(
    data |> filter(Name %in% eligible_riders),
    by = "Race.Name"
  )

#######Step 3 - Data Exploration
################################################################################

#How many individual time trials (ITT) did each rider compete in between 2017 and 2023?
data |> 
  group_by(Name) |> 
  summarise(n_stages=n_distinct(stage_id)) |> 
  arrange(desc(n_stages)) |> 
  gt_preview(top_n=5,bottom_n=5)

#How many ITT victories per rider between 2017-2023?"
data |> 
  filter(Rank==1) |> 
  group_by(Name) |> 
  summarise(n_victories=n()) |> 
  arrange(desc(n_victories))  |> 
  gt_preview(top_n=5,bottom_n=5)

#What was the average finishing position for each rider in ITTs between 2017-2023?
data |> 
  group_by(Name) |> 
  summarise(m_pos=mean(Rank),sd=sd(Rank)) |> 
  arrange(m_pos)  |> 
  gt_preview(top_n=25,bottom_n=5)


#######Step 3 - Prepare the data for Stan
################################################################################
riders<-factor(sort(unique(as.character(data$Name))))

data<-data |> 
  mutate(rider_idx=factor(Name,levels=riders),
         riders=as.integer(rider_idx))

stages<-data |> 
  mutate(s=row_number()) |> 
  summarise(s=first(s),
            N=n(),
            .by=stage_id)


dat<-list(
  y=data$rider_idx, #Factor with rider identification
  R=nlevels(data$rider_idx), #Number of riders
  N_stages=length(stages$s), #Number of stages
  N_finish=stages$N, #Number of riders who finished each stage
  s=c(stages$s,length(data$rider_idx)) #start indexes for each new stage
)

#######Step 4 - Fit the model and validate it
################################################################################
m<-cmdstan_model('plackett_luce_cycling.stan')
f<-m$sample(data=dat,parallel_chains = 4)
f$cmdstan_diagnose()



#######Step 5 - Inspect the results
###############################################################################

#Estimated latent ability parameter for each rider (underlying ITT performance level)
tibble(riders) |> 
  bind_cols(
    f$summary(variables="theta",mean)
  ) |> 
  arrange(mean) |> 
  gt_preview(top_n=100,bottom_n=5)

#Expected finishing position of each rider in a hypothetical mass ITT with 1000+ participants

tibble(riders) |> 
  bind_cols(
    f$summary(variables="positions",mean,sd)
  ) |> 
  arrange(mean) |> 
  gt_preview(top_n=100,bottom_n=5)
