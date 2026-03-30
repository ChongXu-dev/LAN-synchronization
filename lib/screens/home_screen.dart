import 'package:flutter/material.dart';
import '../widgets/history_item.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _clipboardController = TextEditingController(
    text: 'Paste or type your content here...',
  );

  // 模拟历史记录数据
  final List<Map<String, String>> _historyItems = [
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
                        // TODO: 执行复制到系统剪贴板的逻辑
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
                    // TODO: 执行复制到系统剪贴板的逻辑
                  },
                  onDelete: () {
                    // TODO: 执行删除历史记录的逻辑
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
