#### Preamble ####
# Purpose: Tests analysis data to verify structure and validity
# Author: Daniel Du
# Date: 24 November 2024
# Contact: danielc.du@mail.utoronto.ca
# License: MIT
# Pre-requisites: Cleaned data and saved as parquet files in data/02-analysis_data
# Any other information needed? Make sure you are in the `HockeyShotAnalysis` rproj

#### Workspace setup ####
library(testthat)
library(tidyverse)
suppressWarnings(library(arrow))
cleaned_data <- read_parquet("../data/02-analysis_data/shotdata.parquet")

#### Test data ####

# Test that the dataset contains valid seasons
test_that("Dataset contains valid seasons", {
  valid_seasons <- c(2021, 2022, 2023, 2024) 
  expect_true(all(unique(cleaned_data$season) %in% valid_seasons))
})

# Test that all shots have a goalie in net (shotOnEmptyNet == 0)
test_that("All shots have a goalie in net", {
  expect_true(all(cleaned_data$shotOnEmptyNet == 0))
})

# Test for no missing values in key columns
test_that("No NA values in key columns", {
  key_columns <- c("GSAx", "goalieNameForShot", "game_id", "time", "goal", "xGoal", "shotWasOnGoal")
  for (col in key_columns) {
    expect_true(sum(is.na(cleaned_data[[col]])) == 0, info = paste("NA values found in", col))
  }
})

# Test that GSAx is correctly calculated as xGoal - goal
test_that("GSAx is calculated correctly", {
  expect_equal(cleaned_data$GSAx, cleaned_data$xGoal - cleaned_data$goal)
})

# Test that game_id values are unique within the dataset
test_that("No duplicate game IDs", {
  expect_true(length(unique(cleaned_data$game_id)) == nrow(distinct(cleaned_data, game_id)))
})

# Test thatgoalie names are valid strings
test_that("Goalie names are non-empty strings", {
  expect_true(all(nchar(cleaned_data$goalieNameForShot) > 0))
})

# Test that time is within valid ranges (0 to 10000 (longest OT had 9000+ min))
test_that("Time values are within valid ranges", {
  expect_true(all(cleaned_data$time >= 0 & cleaned_data$time <= 10000))
})

#### Test Game State ####

#### Test Rolling Averages ####

# Test that rolling shotslast10min counts are accurate
test_that("Rolling shotslast10min counts are valid", {
  test_row <- cleaned_data[1, ] # Example for testing
  test_game_id <- test_row$game_id
  test_goalie <- test_row$goalieNameForShot
  test_time <- test_row$time
  
  shots_in_last_10_min <- sum(
    cleaned_data$game_id == test_game_id &
      cleaned_data$goalieNameForShot == test_goalie &
      cleaned_data$time >= (test_time - 600) &
      cleaned_data$time < test_time &
      cleaned_data$shotWasOnGoal == 1
  )
  
  expect_equal(test_row$shotslast10min, shots_in_last_10_min)
})

# Test that cumulative shots faced is correctly calculated
test_that("Cumulative shots faced is valid", {
  test_row <- cleaned_data[1, ]
  test_game_id <- test_row$game_id
  test_goalie <- test_row$goalieNameForShot
  test_time <- test_row$time
  
  cumulative_shots <- sum(
    cleaned_data$game_id == test_game_id &
      cleaned_data$goalieNameForShot == test_goalie &
      cleaned_data$time <= test_time &
      cleaned_data$shotWasOnGoal == 1) - 1
  
  expect_equal(test_row$shots_faced, cumulative_shots)
})

test_that("Goal is either 0 or 1", {
  expect_true(all(cleaned_data$goal %in% c(0, 1)))
})

test_that("GSAx is within range [-1, 1]", {
  expect_true(all(cleaned_data$GSAx > -1 & cleaned_data$GSAx < 1))
})

test_that("shots_faced is non-decreasing within each game and goalie", {
  grouped_data <- cleaned_data %>% group_by(game_id, goalieNameForShot) %>%
    arrange(time)
  expect_true(!all(diff(grouped_data$shots_faced) < 0))
})
