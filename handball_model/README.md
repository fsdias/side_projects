## 📋 **Model Overview**

### **Core Structure**
The model predicts match scores using:
- **Team abilities**: Attack (`att`) and defense (`def`) strengths for each team.
- **Home advantage**: A team-specific boost for home matches.
- **Poisson-distributed goals**: Scores are generated from Poisson distributions with team-dependent rates.

### **Key Equations**
For a match between **home team *h*** and **away team *a***:

1. **Home team's expected goals**:
   \[
   \log(\lambda_h) = \text{home\_adv}_h + \text{att}_h - \text{def}_a
   \]
   \[
   \text{Home Score} \sim \text{Poisson}(\lambda_h)
   \]

2. **Away team's expected goals**:
   \[
   \log(\lambda_a) = \text{att}_a - \text{def}_h
   \]
   \[
   \text{Away Score} \sim \text{Poisson}(\lambda_a)
   \]

---
