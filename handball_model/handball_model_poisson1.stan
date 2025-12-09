data {
  int<lower=0> N;
  int<lower=0> N_teams;
  array[N] int<lower=0> home_team_id;
  array[N] int<lower=0> away_team_id;
  array[N] int<lower=0> home_team_score;
  array[N] int<lower=0> away_team_score;
}

parameters {
    
    vector[N_teams] home_adv_nc;
    real mu_ha;
    real<lower=0> sigma_ha;

    matrix[2, N_teams] Z;
    cholesky_factor_corr[2] L_R;
    vector<lower=0>[2] sigma_teams;  // Let the data determine this
    vector[2] abar;
    
}

transformed parameters {
    vector[N_teams] home_adv = mu_ha + home_adv_nc * sigma_ha;
    
    matrix[N_teams, 2] v = (diag_pre_multiply(sigma_teams, L_R) * Z)';
    vector[N_teams] att = abar[1]+v[, 1];
    vector[N_teams] def = abar[2]+v[, 2];
}

model {
    // Priors
    mu_ha~normal(0.2,0.01);
    sigma_ha~exponential(10);
    home_adv_nc ~ normal(0,1);
    

    abar[1]~normal(3.3,0.2);
    abar[2]~normal(0.1,0.2);
    sigma_teams~exponential(5);
    L_R ~ lkj_corr_cholesky(2);
    to_vector(Z) ~ normal(0,1);
    
    
    // Likelihood
    for (i in 1:N) {
        home_team_score[i] ~ poisson_log(
            home_adv[home_team_id[i]] + 
            att[home_team_id[i]] - def[away_team_id[i]]
        );        
        away_team_score[i] ~ poisson_log(
            att[away_team_id[i]] - def[home_team_id[i]]
        );
    }
}

generated quantities {
  array[N] real log_lik;
  array[N] int home_team_score_pred;
  array[N] int away_team_score_pred;
  
  for(i in 1:N) {
    log_lik[i] = 
      poisson_log_lpmf(home_team_score[i] | 
        home_adv[home_team_id[i]] + 
        att[home_team_id[i]] - def[away_team_id[i]]) +
      poisson_log_lpmf(away_team_score[i] | 
        att[away_team_id[i]] - def[home_team_id[i]]);
    
    home_team_score_pred[i] = poisson_log_rng(
      home_adv[home_team_id[i]] + 
      att[home_team_id[i]] - def[away_team_id[i]]
    );
    
    away_team_score_pred[i] = poisson_log_rng(
      att[away_team_id[i]] - def[home_team_id[i]]
    );
  }
}
