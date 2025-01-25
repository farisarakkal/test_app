import 'dart:convert';

class Device {
  final String deviceName;
  final String deviceAddress;

  Device({
    required this.deviceName,
    required this.deviceAddress,
  });

  // Method to convert Device object to JSON string
  String toJsonString() {
    final Map<String, dynamic> data = {
      'deviceName': deviceName,
      'deviceAddress': deviceAddress,
    };
    return jsonEncode(data); // Encode the map into a JSON string
  }

  // Factory method to create Device from JSON string
  factory Device.fromJsonString(String jsonString) {
    final Map<String, dynamic> data = jsonDecode(jsonString);
    return Device(
      deviceName: data['deviceName'],
      deviceAddress: data['deviceAddress'],
    );
  }
}
