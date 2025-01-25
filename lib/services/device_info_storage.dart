import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/device_model.dart';

class DeviceStorage {
  static const String _savedDevicesKey = 'saved_devices';

  // Load saved devices from SharedPreferences
  Future<List<Device>> loadSavedDevices() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? savedDevicesJson = prefs.getStringList(_savedDevicesKey);

    if (savedDevicesJson != null) {
      return savedDevicesJson
          .map((deviceJson) => Device.fromJsonString(deviceJson))
          .toList();
    } else {
      return [];
    }
  }

  // Save a new device info to SharedPreferences
  Future<void> saveDeviceInfo(Device device) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> savedDevicesJson = prefs.getStringList(_savedDevicesKey) ?? [];

    // Check if device is already saved
    bool deviceExists = savedDevicesJson.any((json) {
      Device existingDevice = Device.fromJsonString(json);
      return existingDevice.deviceAddress == device.deviceAddress;
    });

    if (!deviceExists) {
      savedDevicesJson.add(device.toJsonString());
      await prefs.setStringList(_savedDevicesKey, savedDevicesJson);
      print("Device saved: ${device.deviceName}");
    } else {
      print("Device already saved: ${device.deviceName}");
    }
  }

  // Check if the device is already saved
  Future<bool> isDeviceSaved(Device device) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? savedDevicesJson = prefs.getStringList(_savedDevicesKey);

    if (savedDevicesJson != null) {
      return savedDevicesJson.any((json) {
        Device existingDevice = Device.fromJsonString(json);
        return existingDevice.deviceAddress == device.deviceAddress;
      });
    }
    return false;
  }

  // Save or check if device is already saved
  Future<void> saveOrCheckDevice(String deviceName, String deviceAddress) async {
    Device device = Device(deviceName: deviceName, deviceAddress: deviceAddress);

    bool deviceSaved = await isDeviceSaved(device);

    if (!deviceSaved) {
      // Save the device if not already saved
      await saveDeviceInfo(device);
      print("Device saved: ${device.deviceName}");
    } else {
      // If device is already saved, print a message
      print("Device already saved: ${device.deviceName}");
    }
  }
}
