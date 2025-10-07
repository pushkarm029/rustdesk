import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// IPC Service for Connection Manager window visibility control
///
/// Provides cross-platform Inter-Process Communication to toggle CM window:
/// - Linux/macOS: Unix domain socket at /tmp/rustdesk_cm.sock
/// - Windows: TCP localhost at 127.0.0.1:21118
///
/// Protocol:
/// - Commands: "toggle", "show", "hide"
/// - Responses: "shown", "hidden", "unknown command", "error"
/// - Format: newline-terminated strings
class CmIpcService {
  ServerSocket? _server;
  final Future<String> Function(String command) onCommand;
  bool _isRunning = false;
  String? _socketPath;
  int? _tcpPort;

  // Configuration constants
  static const String defaultUnixSocketPath = '/tmp/rustdesk_cm.sock';
  static const int defaultTcpPort = 9999;  // Match activator's expectation
  static const int maxTcpPort = 10009;     // Range: 9999-10009
  static const Duration clientTimeout = Duration(seconds: 5);

  CmIpcService({required this.onCommand});

  /// Start the IPC listener
  /// Automatically chooses Unix socket (Linux/macOS) or TCP (Windows)
  Future<void> start() async {
    if (_isRunning) {
      debugPrint('[CM-IPC] Service already running');
      return;
    }

    try {
      if (Platform.isLinux || Platform.isMacOS) {
        await _startUnixSocket();
      } else if (Platform.isWindows) {
        await _startTcpServer();
      } else {
        throw UnsupportedError('Platform ${Platform.operatingSystem} not supported for IPC');
      }

      _isRunning = true;
      debugPrint('[CM-IPC] ✓ IPC service started successfully');

      // Start listening for connections
      _listenForConnections();

    } catch (e) {
      debugPrint('[CM-IPC] ✗ Failed to start IPC service: $e');
      rethrow;
    }
  }

  /// Stop the IPC listener and clean up resources
  Future<void> stop() async {
    if (!_isRunning) {
      return;
    }

    try {
      await _server?.close();
      _server = null;

      // Clean up Unix socket file
      if (_socketPath != null) {
        try {
          await File(_socketPath!).delete();
          debugPrint('[CM-IPC] Cleaned up socket file: $_socketPath');
        } catch (e) {
          debugPrint('[CM-IPC] Could not delete socket file: $e');
        }
      }

      _isRunning = false;
      debugPrint('[CM-IPC] IPC service stopped');
    } catch (e) {
      debugPrint('[CM-IPC] Error stopping IPC service: $e');
    }
  }

  /// Start Unix domain socket server (Linux/macOS)
  Future<void> _startUnixSocket() async {
    // Get socket path from environment or use default
    _socketPath = Platform.environment['RUSTDESK_CM_SOCKET_PATH'] ??
                  defaultUnixSocketPath;

    // Remove stale socket file if exists
    try {
      final socketFile = File(_socketPath!);
      if (await socketFile.exists()) {
        await socketFile.delete();
        debugPrint('[CM-IPC] Deleted stale socket file: $_socketPath');
      }
    } catch (e) {
      debugPrint('[CM-IPC] Could not delete old socket: $e');
    }

    // Try to bind to socket
    try {
      _server = await ServerSocket.bind(
        InternetAddress(_socketPath!, type: InternetAddressType.unix),
        0,
      );
      debugPrint('[CM-IPC] Unix socket listening at: $_socketPath');
    } catch (e) {
      // Fallback to user home directory
      final fallbackPath = '${Platform.environment['HOME']}/.rustdesk_cm.sock';
      debugPrint('[CM-IPC] Failed to bind to $_socketPath, trying $fallbackPath');

      try {
        final fallbackFile = File(fallbackPath);
        if (await fallbackFile.exists()) {
          await fallbackFile.delete();
        }
      } catch (_) {}

      _socketPath = fallbackPath;
      _server = await ServerSocket.bind(
        InternetAddress(_socketPath!, type: InternetAddressType.unix),
        0,
      );
      debugPrint('[CM-IPC] Unix socket listening at: $_socketPath (fallback)');
    }

    // Set socket file permissions (readable/writable by user)
    try {
      await Process.run('chmod', ['600', _socketPath!]);
    } catch (e) {
      debugPrint('[CM-IPC] Could not set socket permissions: $e');
    }
  }

  /// Start TCP server (Windows)
  Future<void> _startTcpServer() async {
    // Get port from environment or use default
    final portEnv = Platform.environment['RUSTDESK_CM_IPC_PORT'];
    int startPort = portEnv != null ? int.parse(portEnv) : defaultTcpPort;

    // Try ports in range until one succeeds
    for (int port = startPort; port <= maxTcpPort; port++) {
      try {
        _server = await ServerSocket.bind(
          InternetAddress.loopbackIPv4,
          port,
          shared: false,
        );
        _tcpPort = port;
        debugPrint('[CM-IPC] TCP server listening on 127.0.0.1:$_tcpPort');
        return;
      } catch (e) {
        if (port == maxTcpPort) {
          throw Exception(
            'All TCP ports $startPort-$maxTcpPort are busy. '
            'Cannot start IPC server.'
          );
        }
        debugPrint('[CM-IPC] Port $port busy, trying next...');
      }
    }
  }

  /// Listen for incoming client connections
  void _listenForConnections() {
    if (_server == null) {
      return;
    }

    _server!.listen(
      (Socket client) async {
        debugPrint('[CM-IPC] Client connected from ${client.remoteAddress.address}:${client.remotePort}');
        await _handleClient(client);
      },
      onError: (error) {
        debugPrint('[CM-IPC] Server error: $error');
      },
      onDone: () {
        debugPrint('[CM-IPC] Server closed');
      },
    );
  }

  /// Handle individual client connection
  Future<void> _handleClient(Socket client) async {
    String response = 'error';

    try {
      // Set timeout to prevent hanging clients
      client.timeout(clientTimeout, onTimeout: (sink) {
        debugPrint('[CM-IPC] Client timeout - closing connection');
        sink.close();
      });

      // Read command from client (wait for first data chunk)
      final data = await client.first.timeout(
        clientTimeout,
        onTimeout: () {
          debugPrint('[CM-IPC] Read timeout');
          throw TimeoutException('Client read timeout');
        },
      );

      final command = utf8.decode(data).trim();
      debugPrint('[CM-IPC] Received command: "$command"');

      // Process command through callback
      response = await onCommand(command);
      debugPrint('[CM-IPC] Command result: "$response"');

    } on TimeoutException catch (e) {
      debugPrint('[CM-IPC] Timeout handling client: $e');
      response = 'timeout';
    } catch (e, stackTrace) {
      debugPrint('[CM-IPC] Error handling client: $e');
      debugPrint('[CM-IPC] Stack trace: $stackTrace');
      response = 'error';
    } finally {
      // Always send response and close connection
      try {
        client.write('$response\n');
        await client.flush();
        debugPrint('[CM-IPC] Sent response: "$response"');
      } catch (e) {
        debugPrint('[CM-IPC] Error sending response: $e');
      }

      try {
        await client.close();
        debugPrint('[CM-IPC] Client connection closed');
      } catch (e) {
        debugPrint('[CM-IPC] Error closing client: $e');
      }
    }
  }

  /// Get current socket path (for Unix) or null if not applicable
  String? get socketPath => _socketPath;

  /// Get current TCP port (for Windows) or null if not applicable
  int? get tcpPort => _tcpPort;

  /// Check if service is running
  bool get isRunning => _isRunning;
}
