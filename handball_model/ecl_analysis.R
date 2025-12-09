library(tidyverse)
library(readr)
library(cmdstanr)
library(bayesplot)
library(tidybayes)
library(posterior)
library(MASS)
library(patchwork)

#### 1. Load the EHF Champions League 2025/26 data for Group A
data <- read_csv("ehf_champions_league_results.csv") |> 
  filter(group=="A")
  

#### 2. Data exploration

#Distribution of goals scored by the home and away teams
home_plot <- data |> 
  ggplot(mapping=aes(x=home_team_score))+
  geom_histogram(breaks=seq(15,50,by=1),col='white')+
  labs(x="Goals scored",title="Goals scored by the Home team")

away_plot <- data |> 
  ggplot(mapping=aes(x=away_team_score))+
  geom_histogram(breaks=seq(15,50,by=1),col='white')+
  labs(x="Goals scored",title="Goals scored by the Away team")

home_plot/away_plot


#### 2. Fit the model

teams = unique(data$home_team_name)
data$home_team_id = unlist(sapply(1:nrow(data), function(g) which(teams == data$home_team_name[g])))
data$away_team_id = unlist(sapply(1:nrow(data), function(g) which(teams == data$away_team_name[g])))

df_teams<-data.frame(id=seq(1,8),team_name=teams)

#Create list
dat<-data  |>  
  dplyr::select(
    home_team_score,
    away_team_score,
    home_team_id,
    away_team_id) |>  
  as.list()

dat$N <- nrow(data)
dat$N_teams<-8


m_poisson<-cmdstan_model('handball_model_poisson1.stan')
fit_poisson<-m_poisson$sample(data=dat, parallel_chains = 4)


#### 3. Model validation
fit_poisson$cmdstan_diagnose()
fit_poisson$loo()

ppc_bars(dat$home_team_score,
         fit_poisson$draws(variables = "home_team_score_pred",format="matrix")
)+scale_x_discrete(breaks=seq(20,50,by=5))

ppc_bars(dat$away_team_score,
         fit_poisson$draws(variables = "away_team_score_pred",format="matrix")
)+scale_x_discrete(breaks=seq(20,50,by=5))


#### 4. Posterior parameter estimates 

#Attacking ability
fit_poisson |> 
  spread_draws(att[home_team_id]) |> 
  left_join(df_teams,by=join_by(home_team_id==id)) |> 
  ggplot(mapping=aes(y=team_name,x=att))+
  stat_halfeye()+
  labs(y="Posterior estimate",x="Attacking ability")+
  theme_minimal()

#Defensive ability
fit_poisson |> 
  spread_draws(def[home_team_id]) |> 
  left_join(df_teams,by=join_by(home_team_id==id)) |> 
  ggplot(mapping=aes(y=team_name,x=def))+
  stat_halfeye()+
  labs(y="Posterior estimate",x="Defensive ability")+
    theme_minimal()


#Posterior estimates of mean attacking and defensive ability
fit_poisson |> 
  spread_draws(att[home_team_id], def[home_team_id]) |> 
  left_join(df_teams, by = join_by(home_team_id == id)) |> 
  group_by(home_team_id, team_name) |>  
  mean_hdi(att, def) |>
  ggplot(mapping = aes(y = def, x = att,label=team_name)) +
  geom_point(col='red')+
  geom_text(hjust = 1, vjust = -1)+
  labs(y="Mean defensive ability",x="Mean offensive ability")+
  theme_bw()

