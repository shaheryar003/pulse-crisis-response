/// Push notifications integration stub.
///
/// Real implementation would wire firebase_messaging here. For the hackathon
/// build we use the WebSocket /trace stream as the realtime channel (no FCM
/// setup needed on dev devices). FCM hook is left as a single method for
/// production wiring.
library;

import 'dart:async';

class PushService {
  PushService._();
  static final PushService instance = PushService._();

  final _controller = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get stream => _controller.stream;

  Future<void> register(String userId) async {
    // TODO(production): FirebaseMessaging.instance.getToken() and register at /users/push-token
  }

  void deliver(Map<String, dynamic> event) {
    _controller.add(event);
  }

  Future<void> close() async {
    await _controller.close();
  }
}
