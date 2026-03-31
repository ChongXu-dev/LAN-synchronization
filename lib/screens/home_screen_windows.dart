import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/history_item.dart';
import '../services/network_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _clipboardController = TextEditingController(
    text: 'Paste or type your content here...',
  );

  // 历史记录数据
  List<Map<String, String>> _historyItems = [
    {
      'content': 'Welcome to Local Clipboard Sharing',
      'timestamp': '2 minutes ago',
    },
    {
      'content': 'Your clipboard history will appear here',
      'timestamp': '1 minute ago',
    },
    {
      'content': 'Click the copy icon to add items to your ...',
      'timestamp': 'Just now',
    },
  ];

  // 剪贴板轮询相关
  Timer? _clipboardPollingTimer;
  String? _lastClipboardHash;

  @override
  void initState() {
    super.initState();
    // 应用启动时读取系统剪贴板
    _readClipboard();
    // 初始化网络服务
    _initializeNetworkService();
    // 启动剪贴板轮询器
    _startClipboardPolling();
    // 启动Android前台服务
    _startForegroundService();
  }

  // 启动剪贴板轮询器
  void _startClipboardPolling() {
    _clipboardPollingTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) async {
      await _checkClipboardChanges();
    });
  }

  // 检查剪贴板变化
  Future<void> _checkClipboardChanges() async {
    ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data != null && data.text != null) {
      String currentText = data.text!;
      String currentHash = currentText.hashCode.toString();
      
      // 如果剪贴板内容发生变化
      if (_lastClipboardHash != currentHash) {
        _lastClipboardHash = currentHash;
        setState(() {
          _clipboardController.text = currentText;
          // 添加到历史记录
          _historyItems.insert(0, {
            'content': currentText,
            'timestamp': 'Just now',
          });
        });
        // 通过网络服务发送到其他设备
        await NetworkService().sendClipboard(currentText);
      }
    }
  }

  // 启动Android前台服务
  Future<void> _startForegroundService() async {
    if (Platform.isAndroid) {
      try {
        const platform = MethodChannel('com.example.lan_clipboard/sync_service');
        await platform.invokeMethod('startService');
      } catch (e) {
        print('Error starting foreground service: $e');
      }
    }
  }

  // 初始化网络服务
  Future<void> _initializeNetworkService() async {
    await NetworkService().initialize((String content) async {
      // 接收到网络剪贴板内容
      // 写入系统剪贴板
      await Clipboard.setData(ClipboardData(text: content));
      setState(() {
        _clipboardController.text = content;
        // 添加到历史记录
        _historyItems.insert(0, {
          'content': content,
          'timestamp': 'Just now',
        });
      });
      // 显示提示
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('从网络接收到剪贴板内容并已复制到系统剪贴板')),
      );
    });
  }

  // 读取系统剪贴板
  Future<void> _readClipboard() async {
    ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data != null && data.text != null) {
      setState(() {
        _clipboardController.text = data.text!;
      });
    }
  }

  // 复制到系统剪贴板
  Future<void> _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    // 显示复制成功提示
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已复制到剪贴板')),
    );
    // 更新当前剪贴板显示
    setState(() {
      _clipboardController.text = text;
    });
    // 通过网络服务发送到其他设备
    await NetworkService().sendClipboard(text);
  }

  // 删除历史记录项
  void _deleteHistoryItem(int index) {
    setState(() {
      _historyItems.removeAt(index);
    });
  }

  @override
  void dispose() {
    // 清理剪贴板轮询器
    _clipboardPollingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('局域网剪贴板共享'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              children: [
                Icon(Icons.check, size: 16, color: Colors.green),
                SizedBox(width: 4),
                Text('Connected', style: TextStyle(color: Colors.green, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 当前剪贴板卡片
            const Text('Current Clipboard', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade200,
                    spreadRadius: 2,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Stack(
                children: [
                  TextField(
                    controller: _clipboardController,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(16),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: FloatingActionButton.small(
                      onPressed: () {
                        // 复制当前剪贴板内容到系统剪贴板
                        _copyToClipboard(_clipboardController.text);
                      },
                      backgroundColor: Colors.purple.shade100,
                      child: const Icon(Icons.copy, color: Colors.purple),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // 历史记录列表
            Text('History (${_historyItems.length})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _historyItems.length,
              itemBuilder: (context, index) {
                final item = _historyItems[index];
                return HistoryItem(
                  content: item['content']!,
                  timestamp: item['timestamp']!,
                  onCopy: () {
                    // 复制历史记录项到系统剪贴板
                    _copyToClipboard(item['content']!);
                  },
                  onDelete: () {
                    // 删除历史记录项
                    _deleteHistoryItem(index);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
