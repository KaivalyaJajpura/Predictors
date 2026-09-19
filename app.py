from flask import Flask, render_template, request, jsonify
import subprocess
import os
import re

app = Flask(__name__)

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
MODEL_PATH = os.path.join(BASE_DIR, "model", "rank_predictor.rds")


# =========================
# HEALTH PREDICTOR
# =========================

def predict_health_with_r(age, bmi, exercise, sleep, sugar_intake, smoking, alcohol):

    result = subprocess.run(
        [
            "Rscript",
            os.path.join(BASE_DIR, "predict_knn.R"),
            str(age),
            str(bmi),
            exercise,
            str(sleep),
            sugar_intake,
            smoking,
            alcohol
        ],
        cwd=BASE_DIR,
        capture_output=True,
        text=True
    )

    if result.returncode != 0:
        raise RuntimeError(result.stderr.strip())

    return result.stdout.strip()


# =========================
# JEE PREDICTOR
# =========================

def predict_jee_with_r(
    institute,
    program,
    quota,
    seattype,
    gender,
    round_no,
    year
):

    result = subprocess.run(
        [
            "Rscript",
            os.path.join(BASE_DIR, "predict.R"),
            str(institute),
            str(program),
            str(quota),
            str(seattype),
            str(gender),
            str(round_no),
            str(year)
        ],
        cwd=BASE_DIR,
        capture_output=True,
        text=True
    )

    if result.returncode != 0:
        raise RuntimeError(result.stderr.strip())

    output = result.stdout.strip()

    match = re.search(
        r"Predicted closing rank:\s*([\d.]+)",
        output
    )

    if match:
        rank = float(match.group(1))

        if rank.is_integer():
            rank = int(rank)

        return rank

    return output


# =========================
# READ JEE OPTIONS FROM RDS
# =========================

def get_jee_options():

    r_script = r'''
saved <- readRDS("model/rank_predictor.rds")

cat(jsonlite::toJSON(
    list(
        institutes = saved$institutes,
        programs = saved$programs,
        quotas = saved$quota_levels,
        seattype = saved$seattype_levels,
        genders = saved$gender_levels
    ),
    auto_unbox = TRUE
))
'''

    result = subprocess.run(
        ["Rscript", "-e", r_script],
        cwd=BASE_DIR,
        capture_output=True,
        text=True
    )

    if result.returncode != 0:
        raise RuntimeError(result.stderr.strip())

    import json
    return json.loads(result.stdout)


# =========================
# HOME PAGE
# =========================

@app.route("/")
def index():
    return render_template("index.html")


# =========================
# JEE OPTIONS API
# =========================

@app.route("/jee/options", methods=["GET"])
def jee_options():

    try:
        options = get_jee_options()
        return jsonify(options)

    except Exception as e:
        return jsonify({
            "error": str(e)
        }), 500


# =========================
# HEALTH API
# =========================

@app.route("/predict/health", methods=["POST"])
def predict_health():

    try:
        data = request.get_json()

        prediction = predict_health_with_r(
            data["age"],
            data["bmi"],
            data["exercise"],
            data["sleep"],
            data["sugar_intake"],
            data["smoking"],
            data["alcohol"]
        )

        return jsonify({
            "prediction": prediction.capitalize() + " risk"
        })

    except Exception as e:
        return jsonify({
            "error": str(e)
        }), 500


# =========================
# JEE API
# =========================

@app.route("/predict/jee", methods=["POST"])
def predict_jee():

    try:
        data = request.get_json()

        prediction = predict_jee_with_r(
            data["institute"],
            data["program"],
            data["quota"],
            data["seattype"],
            data["gender"],
            data["round"],
            data["year"]
        )

        return jsonify({
            "prediction": prediction
        })

    except Exception as e:
        return jsonify({
            "error": str(e)
        }), 500


# =========================
# RUN
# =========================

if __name__ == "__main__":
    app.run(debug=True)