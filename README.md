#  EchoHer 
### *Safety that listens. Evidence that lasts.*

**EchoHer** is a proactive personal safety companion designed for anyone navigating potentially unsafe environments. Developed during a 2026 Hackathon, it moves beyond the standard "SOS button" by providing an automated **Black Box** for evidence and a **Safe Haven** locator.



---

##  The Problem
In moments of high stress, victims often cannot look at their screens or navigate complex menus. Current safety apps are reactive; EchoHer is designed to be proactive and forensic.

##  The Three-Tier Defense

### 1. Prevention: The "Fake Call"
Sometimes you just need an exit strategy. With one tap, EchoHer triggers a realistic incoming call screen. It’s a socially "polite" way to excuse yourself from an uncomfortable conversation or a shady situation.

### 2. Protection: The "Black Box"
When the system is **Armed**, a sudden high-intensity shake (detected via the phone's accelerometer) triggers a silent, automated chain reaction:
* **SOS SMS:** A direct message with your live Google Maps coordinates is sent to your trusted guardian via native Method Channels.
* **Audio Evidence:** The app silently records 20 seconds of ambient audio (encoded in `.aac` via `flutter_sound`).
* **Visual Proof:** A front-camera snapshot is captured to document the immediate surroundings.



### 3. Recovery: The "Safe Map"
If you're being followed, the **Safe Map** tab uses GPS to find the nearest police stations and provides immediate turn-by-turn navigation through a deep-link to the native Maps application.

---

##  Tech Stack
* **Framework:** Flutter (3.x)
* **Language:** Dart & Kotlin (for SMS Method Channels)
* **Sensors:** `sensors_plus` (Accelerometer) & `geolocator` (GPS)
* **Hardware Integration:** `camera` & `flutter_sound`
* **Storage:** `shared_preferences` (Guardian data) & `path_provider` (Local evidence)

---

##  Installation & Setup

1.  **Clone the Repository:**
    ```bash
    git clone [https://github.com/your-username/echoher.git](https://github.com/your-username/echoher.git)
    ```
2.  **Install Dependencies:**
    ```bash
    flutter pub get
    ```
3.  **Permissions:** Ensure you grant **Camera, Microphone, Location, and SMS** permissions on the first launch.
4.  **Configure Guardian:** Head to the **Guardian** tab and save a contact number. The SOS feature requires a saved number to function.

---

##  Future Roadmap
* **Cloud Sync:** Automated upload of Black Box evidence to a secure, encrypted cloud bucket.
* **AI Voice Trigger:** Keyword detection (e.g., "Help!") to trigger the SOS hands-free.
* **Community Heatmaps:** Real-time reporting of "unsafe" areas to warn other users nearby.

---

##  Acknowledgments
Built with ☕ and a commitment to making the world a safer place for everyone.