class TimeUtils {
  static String formatMilliseconds(int totalMilliseconds) {
    // 1. 创建 Duration 对象
    Duration duration = Duration(milliseconds: totalMilliseconds);

    // 2. 提取各个部分
    // inHours 会返回总小时数，而 remainder 会计算剩下的不足 1 小时的部分
    int hours = duration.inHours;
    int minutes = duration.inMinutes.remainder(60);
    int seconds = duration.inSeconds.remainder(60);
    int milliseconds = duration.inMilliseconds.remainder(1000);

    // 3. 拼接字符串
    List<String> parts = [];

    if (hours > 0) parts.add('$hours小时');
    if (minutes > 0) parts.add('$minutes分');
    if (seconds > 0) parts.add('$seconds秒');
    if (milliseconds > 0) parts.add('$milliseconds毫秒');

    // 如果输入是 0，返回 0毫秒
    return parts.isEmpty ? '0毫秒' : parts.join('');
  }
}