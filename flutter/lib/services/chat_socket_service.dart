import 'dart:async';

import 'package:get/get.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:vynx/config/env_config.dart';
import 'package:vynx/services/token_service.dart';

class ChatSocketService extends GetxService {
  io.Socket? _socket;
  final _events = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get events => _events.stream;

  bool get isConnected => _socket?.connected == true;

  Future<void> connect() async {
    if (_socket?.connected == true) return;
    final access = await Get.find<TokenService>().getAccessToken();
    if (access == null || access.isEmpty) return;

    final baseApi = EnvConfig.instance.baseUrl;
    final socketBase = baseApi.endsWith('/api')
        ? baseApi.substring(0, baseApi.length - 4)
        : baseApi.replaceFirst(RegExp(r'/api$'), '');

    _socket?.dispose();
    _socket = io.io(
      socketBase,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': access})
          .enableReconnection()
          .build(),
    );

    _socket!.onConnect((_) {});
    _socket!.onDisconnect((_) {});

    void forward(String name) {
      _socket!.on(name, (payload) {
        final map = payload is Map<String, dynamic>
            ? payload
            : Map<String, dynamic>.from(payload as Map);
        _events.add({'event': name, 'payload': map});
      });
    }

    forward('message:new');
    forward('message:delivered');
    forward('message:read');
    forward('message:deleted');
    forward('message:file_downloaded');
    forward('poll:updated');
    forward('conversation:updated');
    forward('conversation:created');
    forward('typing:start');
    forward('typing:stop');
  }

  Future<Map<String, dynamic>> emitWithAck(
    String event, {
    required Map<String, dynamic> payload,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final socket = _socket;
    if (socket == null || !socket.connected) {
      return {'success': false, 'message': 'Socket not connected'};
    }

    final completer = Completer<Map<String, dynamic>>();
    Timer? timer;
    timer = Timer(timeout, () {
      if (!completer.isCompleted) {
        completer.complete({'success': false, 'message': 'Request timeout'});
      }
    });

    socket.emitWithAck(event, payload, ack: (data) {
      timer?.cancel();
      if (data is Map<String, dynamic>) {
        completer.complete(data);
      } else if (data is Map) {
        completer.complete(Map<String, dynamic>.from(data));
      } else {
        completer.complete({'success': false, 'message': 'Invalid ack payload'});
      }
    });

    return completer.future;
  }

  Future<void> disconnect() async {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  @override
  void onClose() {
    _events.close();
    _socket?.dispose();
    super.onClose();
  }
}
