library(class)

df <- read.csv("data/health_data.csv")

features <- c("age", "bmi", "exercise", "sleep", "sugar_intake", "smoking", "alcohol")
target <- "health_risk"

# text -> number maps, so KNN can compute distances on these columns
exercise_map <- c(none = 0, low = 1, medium = 2, high = 3)
sugar_map    <- c(low = 0, medium = 1, high = 2)
yesno_map    <- c(no = 0, yes = 1)

df$exercise     <- exercise_map[df$exercise]
df$sugar_intake <- sugar_map[df$sugar_intake]
df$smoking      <- yesno_map[df$smoking]
df$alcohol      <- yesno_map[df$alcohol]

X <- df[, features]
Y <- as.factor(df[[target]])

# scale each feature to 0-1 so age/bmi don't dominate the distance
# just because they're on a bigger scale than the yes/no columns
mins <- sapply(X, min)
maxs <- sapply(X, max)
X_norm <- as.data.frame(scale(X, center = mins, scale = maxs - mins))

k <- 5

knn_data <- list(
  X = X_norm,
  Y = Y,
  k = k,
  mins = mins,
  maxs = maxs,
  features = features,
  exercise_map = exercise_map,
  sugar_map = sugar_map,
  yesno_map = yesno_map
)

saveRDS(knn_data, "models/knn_model.rds")

cat("Trained on", nrow(X), "rows. Model saved to models/knn_model.rds\n")
