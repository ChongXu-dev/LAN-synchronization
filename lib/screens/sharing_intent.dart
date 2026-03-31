// 分享功能的统一接口
abstract class SharingIntent {
  static Future<String?> getInitialText() async => null;
  static Stream<String> getTextStream() => Stream.empty();
}
