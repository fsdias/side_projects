library(tidyverse)
library(dplyr)
library(cmdstanr)
library(bayesplot)
library(MASS)

#### 1- Generate fake data

#Simulate handball matches
gen_results <- function() {
  # Data generation parameters
  N_teams <- 8
  N_games <- 56
  
  # Generate all possible matchups
  matchups <- expand.grid(
    home_team_id = 1:N_teams,
    away_team_id = 1:N_teams
  ) %>%
    filter(home_team_id != away_team_id)
  
  ## Parameters

  # Home advantage parameter
  mu_ha <- 0.2  
  sigma_ha <- 0.1
  home_adv <- rnorm(N_teams, mu_ha, sigma_ha)
  
  # Attack and defense ability
  abar <- c(3.3,0.1)
  sigma_teams <- c(0.2,0.2) 
  
  rho <- 2 * 0.70 - 1
  R <- matrix(c(1, rho, rho, 1), 2, 2)
  Sigma <- diag(sigma_teams) %*% R %*% diag(sigma_teams)
  
  att_def <- mvrnorm(N_teams, mu = abar, Sigma = Sigma)
  att <- att_def[, 1]
  def <- att_def[, 2]
  
  # Generate scores
  home_team_score <- numeric(N_games)
  away_team_score <- numeric(N_games)
  
  for (i in 1:N_games) {
    log_lambda_home <- home_adv[matchups$home_team_id[i]] + 
      att[matchups$home_team_id[i]] - 
      def[matchups$away_team_id[i]]
    
    log_lambda_away <- att[matchups$away_team_id[i]] - 
      def[matchups$home_team_id[i]]
    
    lambda_home <- exp(log_lambda_home)
    lambda_away <- exp(log_lambda_away)
    
    # Generate from negative binomial
    home_team_score[i] <- rpois(1, lambda = lambda_home)
    away_team_score[i] <- rpois(1, lambda = lambda_away)
  }
  
  matchups <- matchups |> 
    mutate(home_team_score,
           away_team_score)
  
  assign("matchups", matchups, envir = .GlobalEnv)
  
  return(matchups)
}


matchups<-gen_results()

#Check that the generated data look like real handball data
ggplot(matchups,mapping=aes(x=home_team_score))+
         geom_histogram(col="white")

ggplot(matchups,mapping=aes(x=away_team_score))+
  geom_histogram(col="white")

### 2. Fit the model and check that it can recover the selected parameters

data <- matchups 

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

#Fit
m<-cmdstan_model('handball_model_poisson1.stan')
fit<-m$sample(data=dat,parallel_chains = 4)

#Diagnostics
fit$cmdstan_diagnose()
fit$loo()

#Model validation
ppc_bars(dat$home_team_score,
              fit$draws(variables = "home_team_score_pred",format="matrix")
              )+
  scale_x_discrete(breaks=seq(20,50,by=5))

ppc_bars(dat$away_team_score,
         fit$draws(variables = "away_team_score_pred",format="matrix")
)+
  scale_x_discrete(breaks=seq(20,50,by=5))


fit$summary(
  variables = c("mu_ha",
  "sigma_ha", "abar","sigma_teams"
))
