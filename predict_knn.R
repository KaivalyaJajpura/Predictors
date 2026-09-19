library(class)

args <- commandArgs(trailingOnly = TRUE)

# args, in order: age bmi exercise sleep sugar_intake smoking alcohol
# exercise: none/low/medium/high | sugar_intake: low/medium/high | smoking/alcohol: no/yes
age          <- as.numeric(args[1])
bmi          <- as.numeric(args[2])
exercise     <- args[3]
sleep        <- as.numeric(args[4])
sugar_intake <- args[5]
smoking      <- args[6]
alcohol      <- args[7]

knn_data <- readRDS("models/knn_model.rds")

new_point <- data.frame(
  age          = age,
  bmi          = bmi,
  exercise     = knn_data$exercise_map[[exercise]],
  sleep        = sleep,
  sugar_intake = knn_data$sugar_map[[sugar_intake]],
  smoking      = knn_data$yesno_map[[smoking]],
  alcohol      = knn_data$yesno_map[[alcohol]]
)

new_norm <- as.data.frame(scale(
  new_point,
  center = knn_data$mins,
  scale  = knn_data$maxs - knn_data$mins
))

prediction <- knn(
  train = knn_data$X,
  test  = new_norm,
  cl    = knn_data$Y,
  k     = knn_data$k
)

cat(as.character(prediction))
