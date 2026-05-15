# Sprint 5 — Flutter Mobile App

## Goal
Production-quality Flutter app with three role-based surfaces.

## Tasks
| # | Task | Owner | Outputs |
|---|---|---|---|
| 5.1 | pubspec + theming + routing | pm | `mobile/pubspec.yaml`, `mobile/lib/main.dart`, `mobile/lib/shared/theme.dart` |
| 5.2 | API client (REST + WebSocket) | pm | `mobile/lib/services/api.dart` |
| 5.3 | Data models | pm | `mobile/lib/models/*.dart` |
| 5.4 | Role selector / mock auth | pm | `mobile/lib/shared/auth.dart` |
| 5.5 | Citizen — home map | pm | `mobile/lib/citizen/home.dart` |
| 5.6 | Citizen — report flow (photo+voice+geo) | pm | `mobile/lib/citizen/report.dart` |
| 5.7 | Citizen — alerts inbox + retraction history | pm | `mobile/lib/citizen/alerts.dart` |
| 5.8 | Citizen — verify-nearby prompts | pm | `mobile/lib/citizen/verify.dart` |
| 5.9 | Responder — dispatch queue | pm | `mobile/lib/responder/queue.dart` |
| 5.10 | Responder — status reporting | pm | `mobile/lib/responder/status.dart` |
| 5.11 | Command — live map + trace pane | pm | `mobile/lib/command/dashboard.dart` |
| 5.12 | Command — simulation toggle | pm | `mobile/lib/command/simulate.dart` |
| 5.13 | FCM push integration | pm | `mobile/lib/services/push.dart` |
| 5.14 | Offline queue | pm | `mobile/lib/services/offline.dart` |
| 5.15 | Widget tests | pm | `mobile/test/*.dart` |

## Acceptance Criteria
- [must] file_exists for every output above
- [must] manual_review: 3 surfaces with role-gated routing
- [must] manual_review: citizen retraction history visible (transparency requirement)
- [must] manual_review: command-center trace pane mirrors WebSocket artifact stream
- [should] test_passes: `flutter analyze` clean (when Flutter SDK present)
- [should] test_passes: `flutter test` (when Flutter SDK present)
