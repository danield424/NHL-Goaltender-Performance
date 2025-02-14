#### Preamble ####
# Purpose: Simulates a dataset of hockey shots and their associated attributes, 
# creating a model to predict whether or not a goal was scored.
# Author: Daniel Du
# Date: 24 November 2024
# Contact: danielc.du@mail.utoronto.ca
# License: MIT
# Pre-requisites: The `tidyverse` and `caret` packages must be installed
# Any other information needed? Make sure you are in the `HockeyShotAnalysis` rproj

#### Workspace setup ####
# install.packages("caret")
library(tidyverse)
library(caret) # For createDataPartition
set.seed(424)

#### Simulate data ####
# Number of samples
n_samples <- 500

# Simulate predictors
data <- tibble(
  xGoal = pmax(rnorm(n_samples, mean = 0.3, sd = 0.2), 0.001), # Expected goal probability (positive relationship)
  shots_last_3min = rpois(n_samples, lambda = 2),        # Shots faced in last 3 minutes (negative relationship)
  home = rbinom(n_samples, size = 1, prob = 0.5)         # 0 = Away, 1 = Home
)

# Simulate target variable (goalScored) using logistic function
log_odds <- (
  17 * data$xGoal +                # Strong positive relationship with xGoal
    -2.7 * data$shots_last_3min +   # Negative relationship with recent activity
    -1.3 * data$home +              # Less likely to concede at home
    rnorm(n_samples, mean = 0, sd = 0.1)  # Random noise
)
data <- data %>%
  mutate(goalScored = as.integer(runif(n_samples) < plogis(log_odds)))

data

#### Save Dataset ####
write_csv(data, "data/00-simulated_data/simulated_data.csv")
