from flask import Flask, render_template, request
import subprocess

app = Flask(__name__)

FEATURES = ["age", "bmi", "exercise", "sleep", "sugar_intake", "smoking", "alcohol"]


def predict_with_r(age, bmi, exercise, sleep, sugar_intake, smoking, alcohol):
    """Calls predict_knn.R as a subprocess, so the prediction comes straight
    from the actual model in models/knn_model.rds — trained by train_knn.R."""
    result = subprocess.run(
        ["Rscript", "predict_knn.R", str(age), str(bmi), exercise,
         str(sleep), sugar_intake, smoking, alcohol],
        capture_output=True, text=True, check=True,
    )
    return result.stdout.strip()  # "low" or "high"


@app.route("/", methods=["GET", "POST"])
def index():
    prediction = None
    error = None
    form_values = {
        "age": "40", "bmi": "24", "exercise": "medium",
        "sleep": "7", "sugar_intake": "medium",
        "smoking": "no", "alcohol": "no",
    }

    if request.method == "POST":
        form_values = {k: request.form[k] for k in FEATURES}
        try:
            risk = predict_with_r(
                form_values["age"], form_values["bmi"], form_values["exercise"],
                form_values["sleep"], form_values["sugar_intake"],
                form_values["smoking"], form_values["alcohol"],
            )
            prediction = risk.capitalize() + " risk"
        except subprocess.CalledProcessError as e:
            error = "R script failed: " + e.stderr
        except FileNotFoundError:
            error = "Rscript not found. Make sure R is installed and on your PATH."

    return render_template(
        "index.html",
        prediction=prediction,
        error=error,
        values=form_values,
    )


if __name__ == "__main__":
    app.run(debug=True)
