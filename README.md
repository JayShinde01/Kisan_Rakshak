🌾 CropCareAI – Smart Crop Disease Detection (Flutter Web)
🔗 Live Demo:

👉 https://cropcareai-u7co.onrender.com/

CropCareAI is an AI-powered crop health monitoring web application built using Flutter Web. The app allows farmers to upload crop images and instantly detect diseases using trained machine-learning models.

🚀 Features
🔍 AI-Based Crop Disease Detection

Upload leaf/plant images

AI predicts possible diseases

Shows disease name + confidence score

🧠 Deep Learning Integration

Backend ML API for predictions

Supports multiple crops (wheat, rice, maize, etc.)

🎨 Built With Flutter

Clean and modern UI

Responsive across devices

Runs directly in browser (no installation)

☁️ Hosted on Render

Stable hosting

Fast and lightweight

Optimized for Flutter Web

📁 Project Structure
lib/
│── main.dart
│── screens/
│     └── home_screen.dart
│── widgets/
│     └── upload_card.dart
│── services/
│     └── api_service.dart
assets/
web/

🔧 How It Works (Flow)
**User uploads image**
        ↓
**Flutter Web** → **Sends image to ML API**
        ↓
**API processes image** using trained model
        ↓
**Returns prediction + accuracy**
        ↓
**Flutter Web displays results**

🛠️ Tech Stack
Component	Technology
Frontend	Flutter Web
Backend (API)	Python / FastAPI / Flask
ML Model	TensorFlow / PyTorch
Hosting	Render.com
Storage	Firebase / Cloudinary / Local server
▶️ How to Run Locally
1️⃣ Clone the Repo
git clone <your-repo-url>
cd cropcareai

2️⃣ Install Dependencies
flutter pub get

3️⃣ Enable Web Support
flutter config --enable-web

4️⃣ Run the App
flutter run -d chrome

🌐 Deployment (Render)
Build Flutter Web
flutter build web


This generates:

/build/web


Upload this folder to Render → Static Site.

📸 Screenshots (Optional)

Add your screenshots here.

📞 Contact / Support

If you need help with:

Improving UI

Deploying backend ML model

Generating APK (Android)

Adding new crop disease models

Feel free to ask me anytime! 🚀
