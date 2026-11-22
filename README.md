# FaceUp-Alarm-
### Chehra Alarm (چہرہ الارم) — Professional Flutter Android Application

A smart and reliable Android alarm application built with **Flutter**, designed to make sure you are truly awake.

Normal alarm apps let you dismiss the alarm with a single tap. **FaceUp Alarm** requires you to wake up, show your face to the front camera, verify both eyes are open, complete an interactive challenge, and hold your gaze for 3 continuous seconds before the alarm stops.

---

## 🚀 Key Features
- **Smart Face Verification:** Google ML Kit on-device face detection.
- **Liveness & Wake-up Check:**
  - Face positioning guide
  - Eyes open detection (Confidence threshold > 0.7)
  - Interactive challenge (Smile or Blink)
  - 3-second continuous hold timer
- **100% Privacy-First:**
  - All processing is done locally on your device.
  - No photos, videos, or raw frames are ever saved or uploaded anywhere.
- **Real Android Reliability:**
  - Exact alarm scheduling via Android `AlarmManager`.
  - Full-screen lock-screen alert notifications.
  - Device reboot recovery.
- **Bilingual Interface:** Urdu & English text throughout for effortless usability.

---

## 🛠️ Tech Stack
- **Framework:** Flutter 3.x (Dart 3.x)
- **Target Platform:** Android (minSdk 24, compileSdk 36)
- **Face Detection:** `google_mlkit_face_detection` (on-device)
- **Camera:** `camera` (Front camera integration)
- **Alarm Scheduling:** Android `AlarmManager` & Native Kotlin BroadcastReceiver
- **Notifications:** `flutter_local_notifications`
- **Local Storage:** `shared_preferences`

---

## 📄 Privacy Commitment
> **"آپ کی تصویر کہیں محفوظ نہیں ہوتی / Your face image is never stored."**
> FaceUp Alarm does not require an account, has no backend server, and processes camera frames purely in real-time memory.
