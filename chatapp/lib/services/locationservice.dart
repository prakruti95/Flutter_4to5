// simple_location_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:firebase_database/firebase_database.dart';

class SimpleLocationService {
  Timer? _updateTimer;
  Timer? _expiryTimer;
  String? _currentSessionId;
  bool _isSharing = false;

  // Store duration for timer
  int _durationInMinutes = 0;

  // Live Location शुरू करें
  Future<Map<String, dynamic>> startSimpleLiveLocation({
    required String senderId,
    required String receiverId,
    required int durationInMinutes,
  }) async {
    _currentSessionId = "${DateTime.now().millisecondsSinceEpoch}_$senderId";
    _isSharing = true;
    _durationInMinutes = durationInMinutes; // Store duration

    // Get current location
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    String address = await _getAddress(position);
    DateTime expiryTime = DateTime.now().add(Duration(minutes: durationInMinutes));

    // Simple map preview generate करें (बिना API key के)
    String? mapPreview = await _generateSimpleMapPreview(position.latitude, position.longitude);

    // WhatsApp जैसा message create करें
    String messageId = "live_${_currentSessionId}";

    DatabaseReference myRef = FirebaseDatabase.instance
        .ref("Chats/$senderId/$receiverId/$messageId");

    DatabaseReference otherRef = FirebaseDatabase.instance
        .ref("Chats/$receiverId/$senderId/$messageId");

    Map<String, dynamic> liveLocationMessage = {
      "senderId": senderId,
      "receverId": receiverId,
      "message": "📍 Live Location", // WhatsApp जैसा
      "latitude": position.latitude,
      "longitude": position.longitude,
      "address": address,
      "timestamp": ServerValue.timestamp,
      "day": "Today",
      "isSeen": false,
      "messageType": "live_location",
      "isLive": true,
      "sessionId": _currentSessionId,
      "expiryTime": expiryTime.millisecondsSinceEpoch,
      "duration": durationInMinutes,
      "isActive": true,
      "previewImage": mapPreview, // Map preview image
    };

    await Future.wait([
      myRef.set(liveLocationMessage),
      otherRef.set(liveLocationMessage),
    ]);

    // Real-time updates के लिए separate node
    DatabaseReference liveRef = FirebaseDatabase.instance
        .ref("LiveLocations/$_currentSessionId");

    await liveRef.set({
      "currentLocation": {
        "latitude": position.latitude,
        "longitude": position.longitude,
        "address": address,
        "timestamp": ServerValue.timestamp,
      },
      "senderId": senderId,
      "receiverId": receiverId,
      "startTime": ServerValue.timestamp,
      "expiryTime": expiryTime.millisecondsSinceEpoch,
      "isActive": true,
      "duration": durationInMinutes,
    });

    // Start real-time updates
    _startRealTimeUpdates(senderId, receiverId, expiryTime, durationInMinutes);

    return {
      'sessionId': _currentSessionId,
      'messageId': messageId,
      'latitude': position.latitude,
      'longitude': position.longitude,
      'address': address,
    };
  }

  // Simple map preview generate करें (बिना API key के)
  Future<String?> _generateSimpleMapPreview(double lat, double lng) async {
    try {
      // एक simple widget paint करें
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final size = Size(200, 150);
      final paint = Paint();

      // Background
      paint.color = Colors.grey[200]!;
      canvas.drawRect(Offset.zero & size, paint);

      // Grid lines (map जैसा दिखे)
      paint.color = Colors.grey[400]!;
      paint.strokeWidth = 1.0;

      for (int i = 0; i < 5; i++) {
        double y = size.height / 5 * i;
        canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      }

      for (int i = 0; i < 5; i++) {
        double x = size.width / 5 * i;
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      }

      // Center point (location pin)
      paint.color = Colors.red;
      canvas.drawCircle(
          Offset(size.width / 2, size.height / 2),
          8,
          paint
      );

      // Location pin icon
      paint.color = Colors.white;
      canvas.drawCircle(
          Offset(size.width / 2, size.height / 2),
          4,
          paint
      );

      // Finish painting
      final picture = recorder.endRecording();
      final image = await picture.toImage(size.width.toInt(), size.height.toInt());
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();

      // Convert to base64
      return base64Encode(bytes);
    } catch (e) {
      print("Error generating map preview: $e");
      return null;
    }
  }

  // Real-time location updates शुरू करें
  void _startRealTimeUpdates(
      String senderId,
      String receiverId,
      DateTime expiryTime,
      int durationInMinutes, // Add this parameter
      ) {
    _updateTimer = Timer.periodic(Duration(seconds: 10), (timer) async {
      if (!_isSharing || _currentSessionId == null) {
        timer.cancel();
        return;
      }

      try {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        String address = await _getAddress(position);

        // Update live location
        DatabaseReference liveRef = FirebaseDatabase.instance
            .ref("LiveLocations/$_currentSessionId/currentLocation");

        await liveRef.update({
          "latitude": position.latitude,
          "longitude": position.longitude,
          "address": address,
          "timestamp": ServerValue.timestamp,
        });

      } catch (e) {
        print("Real-time update error: $e");
      }
    });

    // Set expiry timer - use the parameter
    _expiryTimer = Timer(Duration(minutes: durationInMinutes), () {
      stopLiveLocation(senderId: senderId, receiverId: receiverId);
    });
  }

  // Address पाएं
  Future<String> _getAddress(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        List<String> parts = [];
        if (place.street != null && place.street!.isNotEmpty) parts.add(place.street!);
        if (place.locality != null && place.locality!.isNotEmpty) parts.add(place.locality!);
        return parts.join(", ");
      }
    } catch (e) {
      print("Address error: $e");
    }
    return "Current Location";
  }

  // Live Location बंद करें
  Future<void> stopLiveLocation({
    required String senderId,
    required String receiverId,
  }) async {
    if (!_isSharing || _currentSessionId == null) return;

    _isSharing = false;
    _updateTimer?.cancel();
    _expiryTimer?.cancel();

    // Mark as inactive
    DatabaseReference liveRef = FirebaseDatabase.instance
        .ref("LiveLocations/$_currentSessionId");

    await liveRef.update({
      "isActive": false,
      "endTime": ServerValue.timestamp,
    });

    // Update chat message
    String endMessageId = "end_${_currentSessionId}";

    DatabaseReference myRef = FirebaseDatabase.instance
        .ref("Chats/$senderId/$receiverId/$endMessageId");

    DatabaseReference otherRef = FirebaseDatabase.instance
        .ref("Chats/$receiverId/$senderId/$endMessageId");

    Map<String, dynamic> endMessage = {
      "senderId": senderId,
      "receverId": receiverId,
      "message": "Live location ended",
      "timestamp": ServerValue.timestamp,
      "day": "Today",
      "isSeen": false,
      "messageType": "text",
      "sessionId": _currentSessionId,
    };

    await Future.wait([
      myRef.set(endMessage),
      otherRef.set(endMessage),
    ]);

    _currentSessionId = null;
    _durationInMinutes = 0;
  }

  // Live location stream पाएं
  Stream<Map<String, dynamic>> getLiveLocationStream(String sessionId) {
    return FirebaseDatabase.instance
        .ref("LiveLocations/$sessionId/currentLocation")
        .onValue
        .map((event) {
      if (event.snapshot.value != null) {
        Map<dynamic, dynamic> data = event.snapshot.value as Map<dynamic, dynamic>;
        return {
          'latitude': data['latitude']?.toDouble() ?? 0.0,
          'longitude': data['longitude']?.toDouble() ?? 0.0,
          'address': data['address']?.toString() ?? '',
          'timestamp': data['timestamp'] ?? 0,
        };
      }
      return {};
    });
  }

  String? get currentSessionId => _currentSessionId;

  void dispose() {
    _updateTimer?.cancel();
    _expiryTimer?.cancel();
  }
}