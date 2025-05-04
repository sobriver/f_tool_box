import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';

var logger = Logger();

Future logInit() async {
  var dir = await getApplicationCacheDirectory();
  print('app log dir=====$dir');
  List<LogOutput> outputs = [
    ConsoleOutput(),
    AdvancedFileOutput(
      path: dir.path,
      maxFileSizeKB: 20 * 1024,
      maxRotatedFilesCount: 10
  )];
  logger = Logger(printer: CustomLogfmtPrinter(), output: MultiOutput(outputs), level: Level.info);
}


class CustomLogfmtPrinter extends LogPrinter {
  @override
  List<String> log(LogEvent event) {
    var time = DateTime.now().toIso8601String();
    var level = event.level.toString().split('.').last;
    var message = event.message;
    var result = ['$time level=$level message="$message"'];
    if (event.stackTrace != null) {
      result.add("StackTrace:\n${event.stackTrace}");
    }
    return result;
  }
}