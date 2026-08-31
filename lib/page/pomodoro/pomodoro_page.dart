
import 'package:flutter/material.dart';

class PomodoroPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("番茄钟"),),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 100,
                child: TextField(
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: '50',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text("分钟"),
            ],
          ),



        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: SizedBox(
          height: 48,
          width: 150,
          child: ElevatedButton.icon(
            icon: Icon(Icons.start),
            label: Text("开始启动"),
            onPressed: () {},
          ),
        ),),
      ),
    );
  }

}