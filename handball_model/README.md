# Bayesian hierarchical model for predicting handball results

A Bayesian hierarchical model for predicting handball game scores using Stan. This model accounts for team-specific attacking and defensive strengths, home advantage, and correlations between team abilities.


## Model Overview

Handball scoring can be modeled using Poisson likelihoods with log‑intensities that depend on:

- Team‑specific attack ability
- Team‑specific defense ability
- Team‑specific home‑advantage effect

  
## Conceptual Explanation

Below is the centered version of the model used for description only. The Stan implementation in this repository uses the non‑centered version for sampling performance.

### Team Attack and Defense

Each team t has attack and defense abilities:

\[ 
\begin{pmatrix}
\text{att}_t \\
\text{def}_t
\end{pmatrix}
\sim 
\mathcal{N} \left(
\begin{pmatrix}
\bar{a}_1 \\
\bar{a}_2
\end{pmatrix},
\; \Sigma
\right)
\]

where:

- \( \bar{a}_1 \) = global average attack  
- \( \bar{a}_2 \) = global average defense  
- \( \Sigma = \mathrm{diag}(\sigma_{\text{teams}})\, R \, \mathrm{diag}(\sigma_{\text{teams}}) \)  
- \( R \) = 2×2 correlation matrix with LKJ prior  

This allows correlated attack/defense abilities and enforces reasonable shrinkage.
