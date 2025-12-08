# Bayesian Hierarchical Model for Handball Match Prediction

A Stan implementation of a Bayesian hierarchical model for predicting handball match outcomes, adapted from Baio & Blangiardo (2010)'s football prediction framework.

## Model Description

This model estimates team-specific attacking and defensive strengths, along with home advantage effects, to predict handball match scores using a Poisson likelihood framework.

### Likelihood

For match $i$ between home team $h$ and away team $a$:

$$
\begin{align}
y_{i,\text{home}} &\sim \text{Poisson}(\theta_{i,\text{home}}) \\
y_{i,\text{away}} &\sim \text{Poisson}(\theta_{i,\text{away}})
\end{align}
$$

where the scoring intensities are modeled on the log scale:

$$
\begin{align}
\log(\theta_{i,\text{home}}) &= \text{home\_adv}_h + \text{att}_h - \text{def}_a \\
\log(\theta_{i,\text{away}}) &= \text{att}_a - \text{def}_h
\end{align}
$$

### Team-Specific Home Advantage

Unlike the original Baio & Blangiardo model with a single fixed home effect, this implementation allows for **team-specific home advantages**:

$$
\text{home\_adv}_t = \mu_{\text{ha}} + \sigma_{\text{ha}} \cdot z_t, \quad z_t \sim \mathcal{N}(0, 1)
$$

**Priors:**
$$
\begin{align}
\mu_{\text{ha}} &\sim \mathcal{N}(0.2, 0.01^2) \\
\sigma_{\text{ha}} &\sim \text{Exponential}(10)
\end{align}
$$

### Correlated Attack-Defense Structure

Team abilities are modeled with a **bivariate hierarchical structure** allowing correlation between attacking and defensive strengths:

$$
\begin{bmatrix} \text{att}_t - \bar{a}_1 \\ \text{def}_t - \bar{a}_2 \end{bmatrix} \sim \mathcal{N}\left(\begin{bmatrix} 0 \\ 0 \end{bmatrix}, \boldsymbol{\Sigma}\right)
$$

where the covariance matrix is decomposed as:

$$
\boldsymbol{\Sigma} = \text{diag}(\boldsymbol{\sigma}_{\text{teams}}) \cdot \mathbf{R} \cdot \text{diag}(\boldsymbol{\sigma}_{\text{teams}})
$$

**Implementation:** Using Cholesky decomposition for computational efficiency:

$$
\begin{bmatrix} \text{att}_t \\ \text{def}_t \end{bmatrix} = \begin{bmatrix} \bar{a}_1 \\ \bar{a}_2 \end{bmatrix} + \text{diag}(\boldsymbol{\sigma}_{\text{teams}}) \cdot \mathbf{L}_R \cdot \begin{bmatrix} z_{t,1} \\ z_{t,2} \end{bmatrix}
$$

where $z_{t,j} \sim \mathcal{N}(0,1)$ and $\mathbf{L}_R$ is the Cholesky factor of the correlation matrix.

**Priors:**
$$
\begin{align}
\bar{a}_1 &\sim \mathcal{N}(3.3, 0.2^2) \quad \text{(baseline attack)} \\
\bar{a}_2 &\sim \mathcal{N}(0.1, 0.2^2) \quad \text{(baseline defense)} \\
\boldsymbol{\sigma}_{\text{teams}} &\sim \text{Exponential}(5) \\
\mathbf{L}_R &\sim \text{LKJ}(2) \quad \text{(correlation matrix prior)}
\end{align}
$$

## Key Features

### 1. **Team-Specific Home Advantage**
- Recognizes that home court advantage varies across teams
- Particularly relevant in handball where venue characteristics differ
- Hierarchical structure pools information across teams while allowing variation

### 2. **Attack-Defense Correlation**
- Models the relationship between offensive and defensive capabilities
- Captures realistic team profiles (e.g., high-scoring but defensively vulnerable teams)
- LKJ prior promotes modest correlations while allowing data to determine strength

### 3. **Sport-Specific Calibration**
- Prior on baseline attack (`abar[1] ~ N(3.3, 0.2)`) reflects handball's higher scoring rates
- Tighter prior on home advantage mean reflects domain knowledge

### 4. **Non-Centered Parameterization**
- Improves MCMC sampling efficiency
- Better suited for Stan's Hamiltonian Monte Carlo algorithm
- Reduces posterior correlations between parameters

## Model Comparison with Baio & Blangiardo (2010)

| Feature | Original (Football) | This Model (Handball) |
|---------|-------------------|----------------------|
| Home advantage | Single fixed effect | Team-specific hierarchical |
| Attack/Defense structure | Independent | Correlated bivariate |
| Parameter recovery | Centered | Non-centered |
| Prior specification | Vague | Weakly informative |
| Extreme teams | Mixture model | Hierarchical shrinkage |
| Implementation | WinBUGS | Stan |

## Usage

### Data Format

```r
data_list <- list(
  N = nrow(matches),                    # Number of matches
  N_teams = n_teams,                    # Number of teams
  home_team_id = matches $ home_id,       # Home team indices
  away_team_id = matches $ away_id,       # Away team indices
  home_team_score = matches $ home_score, # Home team goals
  away_team_score = matches $ away_score  # Away team goals
)
