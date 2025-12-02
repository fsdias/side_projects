functions {
  //The Plackett-Luce functions were written by Dr Scott Spencer (https://sps.columbia.edu/person/scott-spencer and  https://ssp3nc3r.github.io/)
  
  real plackett_luce_lpmf(array[] int x, vector theta) {
    return sum( log( theta[x] ./ cumulative_sum(theta[x]) ) );
  }
  
    array[] int plackett_luce_rng(vector theta) {
    int P = size(theta);
    array[P] int pos = rep_array(0, P);
    
    for(j in 1:P) {
      vector[P-j+1] remaining_theta;
      array[P-j+1] int remaining_idx;
      int n_remain = 0;
      
      for(k in 1:P) {
        if(pos[k] == 0) {
          n_remain += 1;
          remaining_idx[n_remain] = k;
          remaining_theta[n_remain] = theta[k];
        }
      }
      
      real u = uniform_rng(0, 1);
      real cum_prob = 0;
      real denom = sum( inv(remaining_theta) );
      
      for(k in 1:n_remain) {
        cum_prob += inv(remaining_theta[k]) / denom;
        if(u <= cum_prob) {
          pos[remaining_idx[k]] = j;
          break;
        }
      }
    }
    
    return pos;
  }
  
}
data {
  int R;               // Total number of riders 
  int N_stages;               // Number of staged
  array[N_stages] int N_finish;      // Number of rider who finished the stage
  array[sum(N_finish)] int y; // Finishing orders 
  array[N_stages + 1] int s;  // Start indexes for each new stage
}

parameters {
  simplex[R] theta; // player abilities
}

model {
  // priors
  theta ~ dirichlet( rep_vector(2.0, R) );
  
  // likelihood
  vector[N_stages] ll;
  for (c in 1:N_stages) {
    ll[c] = plackett_luce_lpmf( segment(y, s[c], N_finish[c]) | theta );
  }
  target += sum(ll);
}
generated quantities {
  array[R] int positions;
  positions = plackett_luce_rng(theta);
}
