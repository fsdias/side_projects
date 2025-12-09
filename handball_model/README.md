# Bayesian hierarchical model for predicting handball results

A Bayesian hierarchical model for predicting handball game scores using Stan. This model accounts for team-specific attacking and defensive strengths, home advantage, and correlations between team abilities.

---

## 1. Model Overview

Handball scoring can be modeled using Poisson likelihoods with log‑intensities that depend on:

- Team‑specific attack ability
- Team‑specific defense ability
- Team‑specific home‑advantage effect

All team abilities are given hierarchical priors so that information is shared across teams.

--- 

## 2. Conceptual Explanation

This section describes a centered version of the model for readability. The actual Stan file uses a non‑centered parameterization.

### Team Attack and Defense

Each team t has two abilities:

- att_t : attack strength
- def_t : defense strength

We assume:

  (att_t, def_t) ~ Multivariate Normal(mean = (abar_1, abar_2), covariance = Sigma)

  where:

- abar_1 = global average attack
- abar_2 = global average defense
- Sigma = covariance matrix constructed from:
    - sigma_teams (standard deviations for attack and defense)
    - R (2x2 correlation matrix with LKJ prior)
      
 This structure allows attack and defense to be correlated.

### Home advantage

We assume each team t has a home‑advantage effect:

ha_t ~ Normal(mu_ha, sigma_ha)

with hyperpriors:

  mu_ha    ~ Normal(0.2, 0.01)
  sigma_ha ~ Exponential(10)



### Likelihood

The likelihood for each match i is as follows:

- h_i = home team
- a_i = away team
- yH_i = observed home score
- yA_i = observed away score

The scoring intensities are:

  log_lambda_home_i = ha_(h_i) + att_(h_i) - def_(a_i)
  log_lambda_away_i = att_(a_i) - def_(h_i)

and scores follow:

  yH_i ~ Poisson(exp(log_lambda_home_i))
  
  yA_i ~ Poisson(exp(log_lambda_away_i))



## 3. Repository contents

simulate_handball_data_check_model.R - 
