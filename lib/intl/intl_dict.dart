import 'package:get/get.dart';

class Messages extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    'zh_CN': {
      'reset_file_by_time': '按时间整理文件',
      'about': '关于',
      'app_name': 'F工具箱',
      'version': '版本',
      'source_dir': '来源文件夹',
      'target_dir': '目标文件夹',
      'source_dir_not_exist': '来源文件夹不存在',
      'target_dir_not_exist': '目标文件夹不存在',
      'all_tasks_completed': '全部执行完毕',
      'use_exif_metadata': '是否使用exif信息',
      'in_progress': '正在执行...',
      'start_execution': '开始执行'

    },
    'en_US': {
      'reset_file_by_time': 'Organize Files by Time',
      'about': 'About',
      'app_name': 'FToolBox',
      'version': 'Version',
      'source_dir': 'Source Directory',
      'target_dir': 'Target Directory',
      'source_dir_not_exist': 'Source directory not exist',
      'target_dir_not_exist': 'Target directory not exist',
      'all_tasks_completed': 'All tasks completed',
      'use_exif_metadata': 'Use EXIF metadata',
      'in_progress': 'In progress...',
      'start_execution': 'Start execution',
    }
  };
}