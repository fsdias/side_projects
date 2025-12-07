# Testing the Plackett–Luce Model in Stan Using UCI World Tour Cycling Data (2017–2023)

This repository contains R code and a Stan model used to explore and test the **Plackett–Luce ranking model** using **professional cycling data**, specifically **Individual Time Trial (ITT)** stages from the **UCI World Tour (2017–2023)**.

---

## Project Overview

The **Plackett–Luce model** is a statistical model for ranking data. It estimates the probability of different ranking outcomes based on underlying ability parameters. It is widely used in:

- sports analytics  
- machine learning  
- choice modelling  
- ranking and preference analysis  

In this project, the model is applied to **UCI World Tour Individual Time Trials**, allowing us to infer the relative ITT performance level of elite cyclists even when they did not compete directly against each other in the same race.

The analysis identifies the strongest ITT riders of the 2017–2023 period, quantifies uncertainty in their estimated abilities, and produces interpretable tables and summaries.

---

## Repository Contents

### **1. R Code**

The R script:

- loads the cycling dataset  
- filters for UCI World Tour ITT stages  
- identifies riders with enough participation to be modeled reliably  
- prepares ranking data for Stan  
- fits the Bayesian Plackett–Luce model using **cmdstanr**  
- extracts posterior estimates  
- produces summary tables and visualisations  

### **2. Stan Model (`plackett_luce_cycling.stan`)**

The Stan program:

- defines the Plackett–Luce likelihood (with helper functions by Dr. Scott Spencer)  
- places a Dirichlet prior on rider abilities  
- computes the likelihood across all stages  
- generates posterior predictive rankings  

---

## 🚴 Key Findings

Using results from **2017–2023 UCI World Tour ITTs**, the model estimates each rider's **latent time trial ability**.

Notable insights:

- **Filippo Ganna** emerges as the strongest ITT rider of the period, with 7 wins from 12 ITTs and the highest ability score.  
- **Wout van Aert** and **Tadej Pogačar** closely follow, showing consistently elite performance.  
- The rankings reveal a **generational transition** between former TT specialists (Rohan Dennis, Tom Dumoulin) and newer stars (Ganna, Evenepoel, Pogačar).  

---

## Acknowledgements

Thanks to **Dr. Scott Spencer (AthlyticZ)** for the Plackett–Luce functions and for the course that inspired this project.

---

