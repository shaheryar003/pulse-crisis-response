# Pulse — Mobile App

Flutter app with three role-based surfaces: Citizen, Responder, Command.

## Setup
```
flutter pub get
flutter run               # auto-detects emulator / connected device
```

For the Android emulator the default backend URL `http://10.0.2.2:8000` resolves
to your host machine's localhost (where the FastAPI service runs).
For iOS simulator use `http://localhost:8000`; for a physical device use the
LAN IP of your host. The API URL is editable on the sign-in screen.

## Demo login
- Phone: any 11-digit number (e.g. `03001234567`).
- OTP: `654321` (the mock auth route fixes this for the demo).
- Pick role: Citizen / Responder / Command.

## Surfaces
- **Citizen** — bottom-nav: Map of incidents · Report (photo + GPS + voice optional) · Alerts with retraction history.
- **Responder** — Dispatch queue keyed off Asset ID; ack / en-route / on-scene / clear state machine.
- **Command** — Live map + scrolling Antigravity-style trace from WebSocket /trace; run scenario from the menu.

## Offline
Citizen submissions enqueue to `SharedPreferences` if the network is down; queue
flushes on next online submit.
