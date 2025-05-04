import 'package:get/get.dart';

enum Status {
  // 处理中
  busy,
  // 处理成功
  done,
  // 处理失败
  error,
  // 无数据
  empty
  ;
}

// 基础logic
abstract class BaseController extends GetxController {

  final status = Status.done.obs;

  bool isBusy() {
    return status.value == Status.busy;
  }
  bool isEmpty() {
    return status.value == Status.empty;
  }

  bool isError() {
    return status.value == Status.error;
  }

  void setBusy(){
    status.value = Status.busy;
  }
  void setDone(){
    status.value = Status.done;
  }
  void setError(){
    status.value = Status.error;
  }
  void setEmpty(){
    status.value = Status.empty;
  }
}