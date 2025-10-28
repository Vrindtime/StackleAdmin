import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
// Ensure you have a model for your incoming WebSocket notification payload
import 'package:stackle_admin/data/models/push_notification.dart'; 
// Assuming PushNotification is the model for the received notification

class WebSocketNotificationService {
  final String baseUrl; // e.g., 'ws://192.168.1.73:8000'
  final String identifierId;
  final String authToken;

  WebSocketChannel? _channel;
  StreamController<PushNotification> _incomingNotifications = StreamController.broadcast();
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;
  int _reconnectAttempt = 0;
  bool _manuallyClosed = false;

  WebSocketNotificationService({
    required this.baseUrl,
    required this.identifierId,
    required this.authToken,
  });

  // Expose the stream of parsed notifications to the Controller
  Stream<PushNotification> get notificationsStream => _incomingNotifications.stream;

  String _buildUrl() {
    // We'll use the query param method since it's common with Channels and simplifies web/mobile consistency
    // Note: If you have configured Channels middleware to read headers, you might need IOWebSocketChannel for mobile.
    return "$baseUrl/ws/noti/$identifierId/?token=$authToken";
  }

  void connect() {
    if (_channel != null) return; // Prevent double connection
    _manuallyClosed = false;
    final uri = Uri.parse(_buildUrl());
    _reconnectTimer?.cancel();

    try {
      // Use the generic WebSocketChannel for Flutter Web
      _channel = WebSocketChannel.connect(uri);

      _channel!.stream.listen(
        _onMessage,
        onDone: _onDone,
        onError: _onError,
        cancelOnError: true,
      );
      
      _startHeartbeat();
      _reconnectAttempt = 0;
      print('WebSocket connected to $uri');
    } catch (e) {
      print('WebSocket connection error: $e');
      _scheduleReconnect();
    }
  }

  void _onMessage(dynamic raw) {
    try {
      final Map<String, dynamic> jsonMsg = jsonDecode(raw as String);
      final type = jsonMsg['type'];

      if (type == 'new_notification') {
        final notif = PushNotification.fromJson(jsonMsg['notification']);
        _incomingNotifications.add(notif);
      } else if (type == 'pong') {
        // Handle pong response
      } else if (type == 'initial_notifications') {
        // Handle initial history if implemented
      }
    } catch (e) {
      print('Error processing WS message: $e');
    }
  }

  void _onDone() {
    _stopHeartbeat();
    if (!_manuallyClosed) _scheduleReconnect();
  }

  void _onError(error) {
    print('WebSocket error: $error');
    _stopHeartbeat();
    if (!_manuallyClosed) _scheduleReconnect();
  }

  void close() {
    _manuallyClosed = true;
    _stopHeartbeat();
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    try {
      _channel?.sink.close(status.goingAway);
    } catch (e) {}
    _channel = null;
    print('WebSocket closed.');
  }

  // --- Reconnect & Heartbeat Logic ---

  void _scheduleReconnect() {
    _reconnectAttempt++;
    final delaySeconds = (_reconnectAttempt > 6) ? 30 : (1 << (_reconnectAttempt.clamp(0, 6)));
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: delaySeconds), connect);
    print('Scheduled reconnect in $delaySeconds seconds. Attempt: $_reconnectAttempt');
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(Duration(seconds: 25), (_) {
      try {
        _channel?.sink.add(jsonEncode({"type": "ping"}));
      } catch (e) {}
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }
}