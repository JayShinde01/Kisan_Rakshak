from flask import Flask, render_template, request, jsonify
from flask_cors import CORS
from werkzeug.utils import secure_filename
import tensorflow as tf
from tensorflow.keras.models import load_model
from tensorflow.keras.preprocessing.image import load_img, img_to_array
from tensorflow.keras.applications.efficientnet import preprocess_input
import os
import time
import uuid
import logging

# -----------------------
# Optional: quiet oneDNN custom-op messages (uncomment to disable)
# os.environ["TF_ENABLE_ONEDNN_OPTS"] = "0"
# -----------------------

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("cropcare-backend")

app = Flask(__name__)
CORS(app)

# Upload configuration
UPLOAD_FOLDER = os.path.join("static", "uploads")
os.makedirs(UPLOAD_FOLDER, exist_ok=True)
app.config["UPLOAD_FOLDER"] = UPLOAD_FOLDER
# limit upload size if desired (e.g. 8MB)
app.config["MAX_CONTENT_LENGTH"] = 8 * 1024 * 1024

ALLOWED_EXTENSIONS = {"png", "jpg", "jpeg", "bmp", "gif", "tiff"}


def allowed_file(filename: str) -> bool:
    return "." in filename and filename.rsplit(".", 1)[1].lower() in ALLOWED_EXTENSIONS


# ---- CHANGE THIS TO YOUR MODEL'S LOCATION or set MODEL_PATH env var ----
MODEL_PATH = os.environ.get(
    "MODEL_PATH",
    r"C:\Users\jaysh\Desktop\CropCareAI\backend\model\best_wheat_model.keras",
)

# Load model
logger.info("📌 Loading model from: %s", MODEL_PATH)
try:
    model = load_model(MODEL_PATH, compile=False)
    logger.info("✅ Model loaded successfully.")
except Exception as e:
    logger.exception("❌ Failed to load model. Make sure MODEL_PATH is correct.")
    raise

# Class names for your model's outputs — keep in same order as model training
class_names = [
    "Aphid", "Brown Rust", "Healthy", "Leaf Blight",
    "Mildew", "Mite", "Septoria", "Smut", "Yellow Rust"
]


@app.route("/")
def home():
    """Render the main page (expects templates/index.html to exist)."""
    return render_template("index.html")


@app.route("/predict", methods=["POST"])
def web_predict():
    """Endpoint for form uploads that returns rendered HTML."""
    if "file" not in request.files:
        return render_template("index.html", error="No file uploaded")

    file = request.files["file"]
    if file.filename == "":
        return render_template("index.html", error="No file selected")

    if not allowed_file(file.filename):
        return render_template("index.html", error="File type not allowed")

    # make filename safe and unique
    orig_name = secure_filename(file.filename)
    unique_name = f"{os.path.splitext(orig_name)[0]}_{uuid.uuid4().hex}{os.path.splitext(orig_name)[1]}"
    filepath = os.path.join(app.config["UPLOAD_FOLDER"], unique_name)
    file.save(filepath)

    return _predict_response(filepath, render_html=True)


@app.route("/api/predict", methods=["POST"])
def api_predict():
    """API endpoint for programmatic uploads — returns JSON."""
    if "file" not in request.files:
        return jsonify({"error": "No file uploaded"}), 400

    file = request.files["file"]
    if file.filename == "":
        return jsonify({"error": "No file selected"}), 400

    if not allowed_file(file.filename):
        return jsonify({"error": "File type not allowed", "allowed": list(ALLOWED_EXTENSIONS)}), 400

    orig_name = secure_filename(file.filename)
    timestamp = int(time.time())
    unique_name = f"{os.path.splitext(orig_name)[0]}_{timestamp}_{uuid.uuid4().hex}{os.path.splitext(orig_name)[1]}"
    filepath = os.path.join(app.config["UPLOAD_FOLDER"], unique_name)
    file.save(filepath)

    return _predict_response(filepath, render_html=False)


def _predict_response(filepath: str, render_html: bool = False):
    """Shared prediction logic. Returns rendered HTML or JSON depending on render_html flag."""
    try:
        # Load, preprocess
        img = load_img(filepath, target_size=(256, 256))
        img_array = img_to_array(img)
        img_array = preprocess_input(img_array)
        img_array = tf.expand_dims(img_array, axis=0)

        # Predict
        prediction = model.predict(img_array)[0]
        idx = int(prediction.argmax())
        label = class_names[idx] if 0 <= idx < len(class_names) else f"class_{idx}"
        confidence = round(float(prediction[idx]) * 100, 2)

        # Build absolute URL to uploaded file
        # request.host_url includes trailing slash e.g. "http://localhost:5000/"
        file_url = f"{request.host_url.rstrip('/')}/{app.config['UPLOAD_FOLDER'].replace(os.path.sep, '/')}/{os.path.basename(filepath)}"

        if render_html:
            return render_template(
                "index.html",
                file_path=file_url,
                result=label,
                confidence=confidence
            )

        return jsonify({
            "prediction": label,
            "confidence": confidence,
            "image_url": file_url
        })

    except Exception as e:
        logger.exception("Prediction error for file %s", filepath)
        if render_html:
            return render_template("index.html", error=f"Prediction Error: {e}")
        return jsonify({"error": str(e)}), 500


if __name__ == "__main__":
    # Change host/port/debug as you like. For production use a WSGI server (gunicorn, waitress, etc.)
    app.run(host="0.0.0.0", port=5000, debug=True)
