import 'dart:async';
import 'dart:io';
import 'dart:convert';

class NetworkService {
  static final NetworkService _instance = NetworkService._internal();
  factory NetworkService() => _instance;
  NetworkService._internal();

  static const int udpPort = 8899;
  static const int httpPort = 8080;
  static const Duration broadcastInterval = Duration(seconds: 5);

  final List<String> _discoveredDevices = [];
  RawDatagramSocket? _udpSocket;
  HttpServer? _httpServer;
  Timer? _broadcastTimer;
  Function(String)? _onClipboardReceived;

  // 初始化网络服务
  Future<void> initialize(Function(String) onClipboardReceived) async {
    _onClipboardReceived = onClipboardReceived;
    await _startUdpListener();
    await _startHttpServer();
    _startBroadcast();
  }

  // 启动 UDP 监听器
  Future<void> _startUdpListener() async {
    try {
      _udpSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, udpPort);
      _udpSocket?.listen((event) {
        if (event == RawSocketEvent.read) {
          Datagram? datagram = _udpSocket?.receive();
          if (datagram != null) {
            String message = utf8.decode(datagram.data);
            String senderIp = datagram.address.address;
            if (message == 'LAN_CLIPBOARD_SYNC' && !_discoveredDevices.contains(senderIp)) {
              _discoveredDevices.add(senderIp);
              print('Discovered device: $senderIp');
            }
          }
        }
      });
    } catch (e) {
      print('Error starting UDP listener: $e');
    }
  }

  // 启动 HTTP 服务器
  Future<void> _startHttpServer() async {
    try {
      _httpServer = await HttpServer.bind(InternetAddress.anyIPv4, httpPort);
      _httpServer?.listen((HttpRequest request) async {
        if (request.method == 'POST' && request.uri.path == '/clipboard') {
          String content = await utf8.decoder.bind(request).join();
          if (_onClipboardReceived != null) {
            _onClipboardReceived!(content);
          }
          request.response
            ..statusCode = HttpStatus.ok
            ..write('Clipboard received');
        } else {
          request.response
            ..statusCode = HttpStatus.notFound
            ..write('Not found');
        }
        await request.response.close();
      });
      print('HTTP server started on port $httpPort');
    } catch (e) {
      print('Error starting HTTP server: $e');
    }
  }

  // 开始广播
  void _startBroadcast() {
    _broadcastTimer = Timer.periodic(broadcastInterval, (timer) async {
      await _broadcastPresence();
    });
  }

  // 广播设备存在
  Future<void> _broadcastPresence() async {
    try {
      RawDatagramSocket socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      socket.broadcastEnabled = true;
      List<int> message = utf8.encode('LAN_CLIPBOARD_SYNC');
      socket.send(message, InternetAddress('255.255.255.255'), udpPort);
      socket.close();
    } catch (e) {
      print('Error broadcasting presence: $e');
    }
  }

  // 发送剪贴板内容到所有发现的设备
  Future<void> sendClipboard(String content) async {
    for (String ip in _discoveredDevices) {
      try {
        HttpClient client = HttpClient();
        HttpClientRequest request = await client.post(ip, httpPort, '/clipboard');
        // 明确设置Content-Type为UTF-8
        request.headers.contentType = ContentType('text', 'plain', charset: 'utf-8');
        // 使用UTF-8编码写入内容
        request.add(utf8.encode(content));
        HttpClientResponse response = await request.close();
        await response.drain();
        client.close();
      } catch (e) {
        print('Error sending clipboard to $ip: $e');
        // 从列表中移除无法连接的设备
        _discoveredDevices.remove(ip);
      }
    }
  }

  // 获取已发现的设备列表
  List<String> get discoveredDevices => _discoveredDevices;

  // 停止网络服务
  void dispose() {
    _broadcastTimer?.cancel();
    _udpSocket?.close();
    _httpServer?.close();
  }
}
