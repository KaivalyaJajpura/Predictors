if (!require("randomForest")) install.packages("randomForest", repos = "https://cloud.r-project.org")
library(randomForest)
set.seed(42)

df <- read.csv("C:\Users\Ethnotech\Desktop\git project\Predictors\data\merged_jee_cutoff_2018_2025.csv", stringsAsFactors = FALSE)
names(df) <- c("Institute","Program","Quota","SeatType","Gender","OpeningRank","ClosingRank","Round","Year")

df$Gender[df$Gender == "F"] <- "Female-only (including Supernumerary)"
df <- df[df$Gender %in% c("Gender-Neutral","Female-only (including Supernumerary)") &
           !is.na(df$ClosingRank) & df$ClosingRank > 0, ]

df$LogClosing <- log1p(df$ClosingRank)
inst_avg <- tapply(df$LogClosing, df$Institute, mean)
prog_avg <- tapply(df$LogClosing, df$Program, mean)
df$InstituteScore <- inst_avg[df$Institute]
df$ProgramScore   <- prog_avg[df$Program]

df$Quota    <- factor(df$Quota)
df$SeatType <- factor(df$SeatType)
df$Gender   <- factor(df$Gender)
df$Target   <- df$LogClosing

n <- nrow(df)
train_i <- sample(seq_len(n), size = floor(0.8 * n))
train <- df[train_i, ]
test  <- df[-train_i, ]

features <- c("InstituteScore","ProgramScore","Quota","SeatType","Gender","Round","Year")

model <- randomForest(x = train[, features], y = train$Target, ntree = 200, importance = TRUE)

pred   <- expm1(predict(model, test[, features]))
actual <- expm1(test$Target)
cat("RMSE:", sqrt(mean((pred - actual)^2)), "\n")
cat("R^2 :", 1 - sum((actual - pred)^2) / sum((actual - mean(actual))^2), "\n")

dir.create("model", showWarnings = FALSE)
saveRDS(list(model = model,
             inst_avg = inst_avg, prog_avg = prog_avg,
             quota_levels = levels(df$Quota), seattype_levels = levels(df$SeatType),
             gender_levels = levels(df$Gender),
             institutes = sort(unique(df$Institute)), programs = sort(unique(df$Program))),
        "model/rank_predictor.rds")
cat("Saved model/rank_predictor.rds\n")