## 📋 **Bayesian hierarchical model for predicting handball results **

A Bayesian hierarchical model for predicting handball game scores using Stan. This model accounts for team-specific attacking and defensive strengths, home advantage, and correlations between team abilities.

**Model Overview**

This model predicts game scores using a Poisson distribution where the log-rate depends on:

- Team attacking strength
- Opponent defensive strength  
- Home field advantage

  
**Score Model**

For each game, scores are modeled as:

home_score ~ Poisson(exp(home_adv + att_home - def_away))
away_score ~ Poisson(exp(att_away - def_home))


Where:

att_t = attacking strength of team t
def_t = defensive strength of team t
home_adv = home advantage (varies by team)

Attack and defense parameters are drawn from a bivariate normal distribution, allowing the model to learn correlations between offensive and defensive strength:

[att_t,def_t]~Normal([mu_att, mu_def], Sigma)

The covariance matrix "Sigma" captures whether teams that are strong offensively tend to also be strong (or weak) defensively.

Home Advantage: Each team has its own home advantage parameter drawn from a common distribution:

home_adv_t ~ Normal(mu_ha, sigma_ha)

        
