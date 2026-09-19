library(randomForest)

args <- commandArgs(trailingOnly = TRUE)
rank      <- as.numeric(args[1])
quota     <- args[2]
seat_type <- args[3]
gender    <- args[4]
round_no  <- if (length(args) >= 5) as.numeric(args[5]) else 6
year      <- if (length(args) >= 6) as.numeric(args[6]) else 2025
top_n     <- if (length(args) >= 7) as.numeric(args[7]) else 50

art <- readRDS("model/rank_predictor.rds")
global_inst_mean <- mean(art$inst_avg)
global_prog_mean <- mean(art$prog_avg)

combos <- expand.grid(Institute = art$institutes, Program = art$programs, stringsAsFactors = FALSE)
combos$InstituteScore <- art$inst_avg[combos$Institute]
combos$ProgramScore   <- art$prog_avg[combos$Program]
combos$InstituteScore[is.na(combos$InstituteScore)] <- global_inst_mean
combos$ProgramScore[is.na(combos$ProgramScore)]     <- global_prog_mean
combos$Quota    <- factor(quota,    levels = art$quota_levels)
combos$SeatType <- factor(seat_type, levels = art$seattype_levels)
combos$Gender   <- factor(gender,   levels = art$gender_levels)
combos$Round    <- round_no
combos$Year     <- year

features <- c("InstituteScore","ProgramScore","Quota","SeatType","Gender","Round","Year")
combos$PredictedClosingRank <- round(expm1(predict(art$model, combos[, features])))

result <- combos[combos$PredictedClosingRank >= rank, ]
result <- result[order(result$PredictedClosingRank), ]
result <- head(result[, c("Institute","Program","PredictedClosingRank")], top_n)
rownames(result) <- NULL

write.csv(result, stdout(), row.names = FALSE)