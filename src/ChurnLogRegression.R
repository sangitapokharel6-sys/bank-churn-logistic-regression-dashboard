# ================================
# Logistic Regression: Bank Churn
# ================================

# 1. Load dataset
bank <- read.csv("Bank Customer Churn Prediction.csv")

# 2. Inspect the data
str(bank)
summary(bank)
head(bank)

# 3. Convert categorical variables to factors
bank$churn <- factor(bank$churn, levels = c(0, 1), labels = c("No", "Yes"))
bank$country <- as.factor(bank$country)
bank$gender <- as.factor(bank$gender)

bank$credit_card <- factor(bank$credit_card, levels = c(0, 1), labels = c("No", "Yes"))
bank$active_member <- factor(bank$active_member, levels = c(0, 1), labels = c("No", "Yes"))

# 4. Remove customer_id because it is only an identifier
bank$customer_id <- NULL

# 5. Split into training and testing sets
set.seed(123)

sample_index <- sample(
  1:nrow(bank),
  size = 0.8 * nrow(bank)
)

train_data <- bank[sample_index, ]
test_data <- bank[-sample_index, ]

# 6. Fit logistic regression model
churn_model <- glm(
  churn ~ credit_score +
    country +
    gender +
    age +
    tenure +
    balance +
    products_number +
    credit_card +
    active_member +
    estimated_salary,
  data = train_data,
  family = binomial
)

# 7. View model summary
summary(churn_model)

# 8. Predict churn probabilities on the test set
churn_probabilities <- predict(
  churn_model,
  newdata = test_data,
  type = "response"
)

# 9. Convert probabilities into Yes/No predictions
# If probability >= 0.50, predict churn
churn_predictions <- ifelse(churn_probabilities >= 0.50, "Yes", "No")

churn_predictions <- factor(
  churn_predictions,
  levels = c("No", "Yes")
)

# 10. Confusion matrix
confusion_matrix <- table(
  Actual = test_data$churn,
  Predicted = churn_predictions
)

confusion_matrix

# 11. Model evaluation metrics

accuracy <- sum(diag(confusion_matrix)) / sum(confusion_matrix)

precision <- confusion_matrix["Yes", "Yes"] /
  sum(confusion_matrix[, "Yes"])

recall <- confusion_matrix["Yes", "Yes"] /
  sum(confusion_matrix["Yes", ])

specificity <- confusion_matrix["No", "No"] /
  sum(confusion_matrix["No", ])

accuracy
precision
recall
specificity


# 12. AUC score

install.packages("pROC")
library(pROC)

roc_curve <- roc(
  response = test_data$churn,
  predictor = churn_probabilities,
  levels = c("No", "Yes")
)

auc(roc_curve)

plot(roc_curve)

library(ggplot2)

# Create a prediction dataset varying age
age_grid <- data.frame(
  credit_score = mean(train_data$credit_score, na.rm = TRUE),
  country = factor("France", levels = levels(train_data$country)),
  gender = factor("Male", levels = levels(train_data$gender)),
  age = seq(
    min(train_data$age, na.rm = TRUE),
    max(train_data$age, na.rm = TRUE),
    length.out = 100
  ),
  tenure = mean(train_data$tenure, na.rm = TRUE),
  balance = mean(train_data$balance, na.rm = TRUE),
  products_number = round(mean(train_data$products_number, na.rm = TRUE)),
  credit_card = factor("Yes", levels = levels(train_data$credit_card)),
  active_member = factor("Yes", levels = levels(train_data$active_member)),
  estimated_salary = mean(train_data$estimated_salary, na.rm = TRUE)
)

# Predict churn probabilities
age_grid$predicted_churn_prob <- predict(
  churn_model,
  newdata = age_grid,
  type = "response"
)

# Plot fitted logistic regression curve
ggplot(age_grid, aes(x = age, y = predicted_churn_prob)) +
  geom_line(linewidth = 1.2) +
  labs(
    title = "Fitted Logistic Regression Curve: Probability of Customer Churn by Age",
    x = "Customer Age",
    y = "Predicted Probability of Churn"
  ) +
  theme_minimal()

ggplot() +
  geom_jitter(
    data = train_data,
    aes(x = age, y = as.numeric(churn) - 1),
    height = 0.05,
    alpha = 0.25
  ) +
  geom_line(
    data = age_grid,
    aes(x = age, y = predicted_churn_prob),
    linewidth = 1.2
  ) +
  labs(
    title = "Observed Churn and Fitted Logistic Regression Curve",
    x = "Customer Age",
    y = "Churn Probability"
  ) +
  theme_minimal()

library(ggplot2)

# Create prediction dataset varying active member status
active_grid <- data.frame(
  credit_score = mean(train_data$credit_score, na.rm = TRUE),
  country = factor("France", levels = levels(train_data$country)),
  gender = factor("Male", levels = levels(train_data$gender)),
  age = mean(train_data$age, na.rm = TRUE),
  tenure = mean(train_data$tenure, na.rm = TRUE),
  balance = mean(train_data$balance, na.rm = TRUE),
  products_number = round(mean(train_data$products_number, na.rm = TRUE)),
  credit_card = factor("Yes", levels = levels(train_data$credit_card)),
  active_member = factor(c("No", "Yes"), levels = levels(train_data$active_member)),
  estimated_salary = mean(train_data$estimated_salary, na.rm = TRUE)
)

# Predict fitted churn probabilities
active_grid$predicted_churn_prob <- predict(
  churn_model,
  newdata = active_grid,
  type = "response"
)

# Plot fitted probabilities only
ggplot(active_grid, aes(x = active_member, y = predicted_churn_prob)) +
  geom_col(width = 0.6) +
  labs(
    title = "Fitted Logistic Regression: Churn Probability by Active Member Status",
    x = "Active Member Status",
    y = "Predicted Probability of Churn"
  ) +
  theme_minimal()

# ================================
# Create dashboard-ready test dataset
# ================================

dashboard_data <- test_data

# Add predicted churn probability
dashboard_data$predicted_churn_probability <- churn_probabilities

# Add predicted churn class
dashboard_data$predicted_churn <- churn_predictions

# Add actual churn as numeric: No = 0, Yes = 1
dashboard_data$actual_churn_numeric <- ifelse(dashboard_data$churn == "Yes", 1, 0)

# Add predicted churn as numeric: No = 0, Yes = 1
dashboard_data$predicted_churn_numeric <- ifelse(dashboard_data$predicted_churn == "Yes", 1, 0)

# Create churn risk category
dashboard_data$risk_category <- cut(
  dashboard_data$predicted_churn_probability,
  breaks = c(-Inf, 0.20, 0.50, Inf),
  labels = c("Low Risk", "Medium Risk", "High Risk")
)

# Create age groups
dashboard_data$age_group <- cut(
  dashboard_data$age,
  breaks = c(18, 30, 40, 50, 60, 100),
  labels = c("18-30", "31-40", "41-50", "51-60", "60+"),
  right = TRUE
)

# Create balance groups
dashboard_data$balance_group <- cut(
  dashboard_data$balance,
  breaks = c(-Inf, 0, 50000, 100000, 150000, Inf),
  labels = c("Zero Balance", "Low Balance", "Medium Balance", "High Balance", "Very High Balance")
)

# Create credit score groups
dashboard_data$credit_score_group <- cut(
  dashboard_data$credit_score,
  breaks = c(-Inf, 500, 600, 700, 800, Inf),
  labels = c("Very Low", "Low", "Medium", "High", "Excellent")
)

# Create salary groups
dashboard_data$salary_group <- cut(
  dashboard_data$estimated_salary,
  breaks = c(-Inf, 50000, 100000, 150000, Inf),
  labels = c("Low Salary", "Medium Salary", "High Salary", "Very High Salary")
)

install.packages("writexl")
library(writexl)

write_xlsx(
  dashboard_data,
  "Bank_Churn_Dashboard_Data.xlsx"
)
