hello# JEE Rank Predictor — R backend

No server, no extra packages beyond randomForest. Two scripts:

```
R/train_model.R -> trains the randomForest, saves model/rank_predictor.rds
R/predict.R      -> command-line script: reads inputs as args, prints CSV to stdout
```

## Run it

```bash
Rscript R/train_model.R
```

Then for predictions:

```bash
Rscript R/predict.R <rank> <quota> <seat_type> <gender> [round=6] [year=2025] [top_n=50]

Rscript R/predict.R 5000 AI OPEN "Gender-Neutral"
```

Prints CSV to stdout:
```
"Institute","Program","PredictedClosingRank"
"...","...",5210
```

## For your teammate

Call `predict.R` as a subprocess from `app.py` and parse stdout as CSV, e.g.:

```python
import subprocess, csv, io

out = subprocess.run(
    ["Rscript", "R/predict.R", "5000", "AI", "OPEN", "Gender-Neutral"],
    capture_output=True, text=True
)
rows = list(csv.DictReader(io.StringIO(out.stdout)))
```