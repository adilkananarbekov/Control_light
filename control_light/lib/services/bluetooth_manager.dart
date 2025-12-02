import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';

class BluetoothManager extends ChangeNotifier {
  BluetoothManager();

  static const String _defaultAddress = '98:D3:41:F7:24:A4';
  static const String _defaultName = "Ma'Dory";
  static const String _defaultPin = '7777';

  final FlutterBluetoothSerial _adapter = FlutterBluetoothSerial.instance;

  BluetoothConnection? _connection;
  StreamSubscription<BluetoothDiscoveryResult>? _discoverySub;
  StreamSubscription<Uint8List>? _inputSub;

  bool _simulate = true;
  bool _busy = false;
  bool _connected = false;
  String _statusText = 'Waiting for connection';

  bool get connected => !_simulate && _connected;
  bool get busy => _busy;
  String get statusText => _statusText;

  Future<void> connect(String query) async {
    _busy = true;
    _statusText = 'Connecting...';
    notifyListeners();

    final customQuery = query.trim();
    final useDefault = customQuery.isEmpty;
    final targetAddress = useDefault ? _defaultAddress : customQuery;
    final targetName = useDefault ? _defaultName : customQuery;
    final normalizedAddress = _normalizeAddress(targetAddress);
    final normalizedName = targetName.trim().toLowerCase();

    try {
      if (!await _ensurePermissions()) {
        throw 'Bluetooth permissions denied';
      }

      final btState = await _adapter.state;
      if (btState != BluetoothState.STATE_ON) {
        _statusText = 'Requesting to enable Bluetooth';
        notifyListeners();
        await _adapter.requestEnable();
      }

      _adapter.setPairingRequestHandler((BluetoothPairingRequest request) {
        final reqAddress = _normalizeAddress(request.address ?? '');
        if (reqAddress == normalizedAddress) {
          return Future.value(_defaultPin);
        }
        return Future.value(null);
      });

      final device = await _resolveDevice(
        normalizedAddress: normalizedAddress,
        normalizedName: normalizedName,
      );
      if (device == null) {
        throw 'Device not found';
      }

      final address = _normalizeAddress(device.address);

      if (!(await _ensureBond(address))) {
        throw 'Pairing failed';
      }

      _statusText = 'Connecting to ${device.name ?? address}';
      notifyListeners();

      _connection = await BluetoothConnection.toAddress(address);
      _simulate = false;
      _connected = true;
      _statusText = 'Connected to ${device.name ?? address}';

      _inputSub?.cancel();
      _inputSub = _connection?.input?.listen(
        (data) {
          // Optionally handle incoming data or logging.
        },
        onDone: () {
          _statusText = 'Disconnected';
          _connected = false;
          _simulate = true;
          notifyListeners();
        },
      );
    } catch (e) {
      await disconnect();
      _statusText = 'Failed: $e';
    } finally {
      _adapter.setPairingRequestHandler(null);
      _busy = false;
      notifyListeners();
    }
  }

  Future<bool> _ensureBond(String address) async {
    final bonded = await _adapter.getBondedDevices();
    if (bonded.any((d) => d.address == address)) {
      return true;
    }
    try {
      final success = await _adapter.bondDeviceAtAddress(address);
      return success ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<BluetoothDevice?> _resolveDevice({
    required String normalizedAddress,
    required String normalizedName,
  }) async {
    final searchByAddress = normalizedAddress.isNotEmpty;
    final searchByName = normalizedName.isNotEmpty;

    final bonded = await _adapter.getBondedDevices();
    for (final device in bonded) {
      final address = _normalizeAddress(device.address);
      final name = device.name?.toLowerCase();
      final matchesAddress = searchByAddress && address == normalizedAddress;
      final matchesName = searchByName && name == normalizedName;
      if (matchesAddress || matchesName) {
        return device;
      }
    }

    final completer = Completer<BluetoothDevice?>();
    _statusText = 'Scanning for device';
    notifyListeners();

    _discoverySub?.cancel();
    _discoverySub = _adapter.startDiscovery().listen((result) {
      final address = _normalizeAddress(result.device.address);
      final name = result.device.name?.toLowerCase();
      final matchesAddress = normalizedAddress.isNotEmpty && address == normalizedAddress;
      final matchesName = name != null && name == normalizedName;
      if (!completer.isCompleted && (matchesAddress || matchesName)) {
        completer.complete(result.device);
      }
    })
      ..onDone(() {
        if (!completer.isCompleted) {
          completer.complete(null);
        }
      });

    final device = await completer.future.timeout(const Duration(seconds: 10), onTimeout: () => null);
    await _discoverySub?.cancel();
    _discoverySub = null;
    return device;
  }

  Future<bool> _ensurePermissions() async {
    if (!Platform.isAndroid) return true;

    final toRequest = <Permission>[
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
    ];

    // Pre-Android 12 still needs location for discovery.
    if (await _requiresLocationPermission()) {
      toRequest.add(Permission.locationWhenInUse);
    }

    final statuses = await toRequest.request();
    final denied = statuses.values.any((s) => s.isDenied || s.isPermanentlyDenied);
    return !denied;
  }

  Future<bool> _requiresLocationPermission() async {
    // Safe default: request location so discovery works on Android < 12.
    // On Android 12+ this permission is ignored for Bluetooth operations.
    return true;
  }

  Future<void> disconnect() async {
    _simulate = true;
    _connected = false;
    _statusText = 'Disconnected';
    await _inputSub?.cancel();
    await _discoverySub?.cancel();
    if (_connection != null) {
      await _connection!.close();
      _connection = null;
    }
    notifyListeners();
  }

  Future<void> sendLightCommand(String blockId, int lightIndex, bool on) async {
    final payload = '$blockId-$lightIndex-${on ? 1 : 0}';
    if (_simulate || !_connected || _connection == null) {
      _statusText = 'Simulated send: $payload';
      notifyListeners();
      return;
    }

    try {
      _connection!.output.add(Uint8List.fromList(utf8.encode('$payload\r\n')));
      await _connection!.output.allSent;
      _statusText = 'Sent $payload';
    } catch (e) {
      _statusText = 'Send failed: $e';
      _connected = false;
      _simulate = true;
      await _connection?.close();
      _connection = null;
    }
    notifyListeners();
  }

  String _normalizeAddress(String input) {
    final hex = input.replaceAll(RegExp('[^A-Fa-f0-9]'), '').toUpperCase();
    if (hex.length == 12) {
      final pairs = <String>[];
      for (var i = 0; i < hex.length; i += 2) {
        pairs.add(hex.substring(i, i + 2));
      }
      return pairs.join(':');
    }
    return input.toUpperCase();
  }
}
