Here's the copy/paste friendly version:
# Bayesian Hierarchical Model for Handball Match Prediction

A Stan implementation of a Bayesian hierarchical model for predicting handball match outcomes, adapted from Baio & Blangiardo (2010)'s football prediction framework.

## Model Description

This model estimates team-specific attacking and defensive strengths, along with home advantage effects, to predict handball match scores using a Poisson likelihood framework.

### Likelihood

For match *i* between home team *h* and away team *a*:
y_i,home ~ Poisson(θ_i,home)
y_i,away ~ Poisson(θ_i,away)

where the scoring intensities are modeled on the log scale:
log(θ_i,home) = home_adv_h + att_h - def_a
log(θ_i,away) = att_a - def_h

**Interpretation:**
- Home team's scoring rate depends on: their home advantage + their attack + opponent's (weak) defense
- Away team's scoring rate depends on: their attack - home team's defense

### Team-Specific Home Advantage

Unlike the original Baio & Blangiardo model with a single fixed home effect, this implementation allows for **team-specific home advantages**:
home_adv_t = μ_ha + σ_ha · z_t,  where z_t ~ Normal(0, 1)

**Priors:**
μ_ha ~ Normal(0.2, 0.01²)
σ_ha ~ Exponential(10)

This hierarchical structure allows each team to have its own home advantage while borrowing strength from the population mean.

### Correlated Attack-Defense Structure

Team abilities are modeled with a **bivariate hierarchical structure** allowing correlation between attacking and defensive strengths:
[att_t - ā₁]     [0]
[def_t - ā₂]  ~  N([0], Σ)

where the covariance matrix Σ captures the correlation between attack and defense abilities.

**Implementation:** Using Cholesky decomposition for computational efficiency:
[att_t]   [ā₁]
[def_t] = [ā₂] + diag(σ_teams) · L_R · [z_t,1]
                                        [z_t,2]

where:
- `z_t,j ~ Normal(0,1)` are standard normal draws
- `L_R` is the Cholesky factor of the correlation matrix
- `σ_teams` controls the scale of variation between teams

**Priors:**
ā₁ ~ Normal(3.3, 0.2²)     # baseline attack (higher for handball)
ā₂ ~ Normal(0.1, 0.2²)     # baseline defense
σ_teams ~ Exponential(5)   # between-team variation
L_R ~ LKJ(2)               # correlation matrix prior

**Stan Code Snippet:**
```stan
matrix[N_teams, 2] v = (diag_pre_multiply(sigma_teams, L_R) * Z)';
vector[N_teams] att = abar[1] + v[, 1];
vector[N_teams] def = abar[2] + v[, 2];
Key Features
1. Team-Specific Home Advantage

Recognizes that home court advantage varies across teams
Particularly relevant in handball where venue characteristics differ
Hierarchical structure pools information across teams while allowing variation

2. Attack-Defense Correlation

Models the relationship between offensive and defensive capabilities
Captures realistic team profiles (e.g., high-scoring but defensively vulnerable teams)
LKJ prior promotes modest correlations while allowing data to determine strength

3. Sport-Specific Calibration

Prior on baseline attack (ā₁ ~ N(3.3, 0.2)) reflects handball's higher scoring rates
Tighter prior on home advantage mean reflects domain knowledge

4. Non-Centered Parameterization

Improves MCMC sampling efficiency
Better suited for Stan's Hamiltonian Monte Carlo algorithm
Reduces posterior correlations between parameters

Model Comparison with Baio & Blangiardo (2010)



Feature
Original (Football)
This Model (Handball)



Home advantage
Single fixed effect
Team-specific hierarchical


Attack/Defense structure
Independent
Correlated bivariate


Parameter recovery
Centered
Non-centered


Prior specification
Vague
Weakly informative


Extreme teams
Mixture model
Hierarchical shrinkage


Implementation
WinBUGS
Stan


Installation & Requirements
# Install required packages
install.packages("cmdstanr", repos = c("https://mc-stan.org/r-packages/", getOption("repos")))
cmdstanr::install_cmdstan()
Usage
Data Format
Your data should be structured with one row per match:
data_list <- list(
  N = nrow(matches),                    # Number of matches
  N_teams = n_teams,                    # Number of teams
  home_team_id = matches $ home_id,       # Home team indices (1 to N_teams)
  away_team_id = matches $ away_id,       # Away team indices (1 to N_teams)
  home_team_score = matches $ home_score, # Home team goals
  away_team_score = matches $ away_score  # Away team goals
)
Important: Team IDs must be integers from 1 to N_teams.
Fitting the Model
library(cmdstanr)

# Compile model
model <- cmdstan_model("handball_model.stan")

# Fit model
fit <- model $ sample(
  data = data_list,
  chains = 4,
  parallel_chains = 4,
  iter_warmup = 1000,
  iter_sampling = 2000,
  seed = 123,
  refresh = 500
)

# Check convergence
fit $ diagnostic_summary()
Extracting Results
# Team parameters (with uncertainty quantiles)
att_summary <- fit $ summary("att")
def_summary <- fit $ summary("def")
home_adv_summary <- fit $ summary("home_adv")

# Attack-defense correlation
correlation <- fit $ summary("L_R")

# Predictions for each match
predictions <- fit $ summary(c("home_team_score_pred", "away_team_score_pred"))

# Extract full posterior draws for custom analysis
draws <- fit $ draws(format = "df")
Visualization Example
library(ggplot2)
library(dplyr)

# Plot team attacking strengths
att_summary %>%
  mutate(team = 1:n()) %>%
  ggplot(aes(x = reorder(team, mean), y = mean)) +
  geom_point() +
  geom_errorbar(aes(ymin = q5, ymax = q95), width = 0.2) +
  coord_flip() +
  labs(title = "Team Attacking Strengths",
       x = "Team", y = "Attack Parameter") +
  theme_minimal()
Model Output
The model provides:

att: Team attacking strength (higher = better offense)
def: Team defensive strength (higher = worse defense, more goals conceded)
home_adv: Team-specific home court effect
L_R: Cholesky factor of attack-defense correlation matrix
sigma_teams: Between-team variation in abilities
home_team_score_pred & away_team_score_pred: Posterior predictive distributions

Interpreting Parameters
Attack Parameter:

att[team] = 0.5 → Team scores exp(0.5) ≈ 1.65× the baseline rate
Positive values indicate above-average offense

Defense Parameter:

def[team] = -0.3 → Opponents score exp(-0.3) ≈ 0.74× against this team
Negative values indicate good defense (fewer goals conceded)

Home Advantage:

home_adv[team] = 0.15 → Team scores exp(0.15) ≈ 1.16× more at home
Varies by team based on venue characteristics

Model Validation
# Posterior predictive checks
library(bayesplot)

# Extract observed and predicted scores
y_obs <- c(data_list $ home_team_score, data_list $ away_team_score)
y_rep <- fit$draws("home_team_score_pred", format = "matrix")

# Density overlay
ppc_dens_overlay(y_obs, y_rep[1:50, ])

# Check calibration
ppc_intervals(y_obs, y_rep)
Advantages

✅ Flexibility: Team-specific home effects capture venue heterogeneity
✅ Realism: Correlated abilities reflect true team characteristics
✅ Efficiency: Non-centered parameterization and HMC sampling
✅ Interpretability: Clear parameter meanings for domain experts
✅ Extensibility: Easy to add covariates (injuries, form, etc.)
✅ Uncertainty quantification: Full posterior distributions for predictions

Limitations

⚠️ Overshrinkage: May underestimate extreme team differences (no mixture components)
⚠️ Independence assumption: Home and away scores treated as independent Poisson
⚠️ Static parameters: No time-varying effects or form dynamics
⚠️ Home advantage structure: Assumes constant home effect per team across season
⚠️ Data requirements: Needs sufficient matches per team for stable estimates

