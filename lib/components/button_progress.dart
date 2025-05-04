import 'package:flutter/material.dart';


// 正在加载按钮，带有文字的
class ProgressButtonWithText extends StatelessWidget {
  final double size;
  final String text;
  const ProgressButtonWithText({super.key, this.size = 35, this.text = ""});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        width: double.infinity,
        height: size,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              strokeWidth: 4,
            ),
            const SizedBox(width: 5),
            Text(text)
          ],
        ));
  }
}

