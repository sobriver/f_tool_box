import 'package:f_tool_box/page/pic_to_video/pic_to_video_page.dart';
import 'package:f_tool_box/page/pomodoro/pomodoro_page.dart';
import 'package:f_tool_box/page/video_downloader/video_downloader_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'about/about_page.dart';
import 'reset_file_by_time/reset_file_time_page.dart';

const _brandPurple = Color(0xFF5B2DEE);
const _canvasColor = Color(0xFFF1F3F8);

class HomePage extends StatelessWidget {
  HomePage({super.key});

  final NavController controller = Get.put(NavController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _canvasColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1440),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x150F172A),
                      blurRadius: 24,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Row(
                    children: [
                      _Sidebar(controller: controller),
                      const VerticalDivider(width: 1, thickness: 1, color: Color(0xFFE8EAF0)),
                      Expanded(
                        child: Column(
                          children: [
                            _WorkspaceHeader(controller: controller),
                            const Divider(height: 1, color: Color(0xFFE8EAF0)),
                            Expanded(
                              child: Obx(() => controller.pages[controller.selectedIndex.value]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.controller});

  final NavController controller;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 224,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _Brand(),
            const SizedBox(height: 26),
            FilledButton.icon(
              onPressed: () => controller.changePage(0),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('新建整理任务'),
              style: FilledButton.styleFrom(
                backgroundColor: _brandPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
            ),
            const SizedBox(height: 22),
            Obx(
              () => _SidebarItem(
                icon: Icons.folder_copy_outlined,
                label: '文件整理',
                selected: controller.selectedIndex.value == 0,
                onTap: () => controller.changePage(0),
              ),
            ),
            const SizedBox(height: 8),
            const _SectionLabel('媒体工具'),
            Obx(
              () => _VideoMenu(
                controller: controller,
                expanded: controller.videoExpanded.value,
                selectedIndex: controller.selectedIndex.value,
              ),
            ),
            const SizedBox(height: 8),
            Obx(
              () => _SidebarItem(
                icon: Icons.timer_outlined,
                label: '番茄钟',
                selected: controller.selectedIndex.value == 3,
                onTap: () => controller.changePage(3),
              ),
            ),
            const Spacer(),
            const Divider(color: Color(0xFFEFEFF4)),
            const SizedBox(height: 8),
            Obx(
              () => _SidebarItem(
                icon: Icons.info_outline_rounded,
                label: '关于',
                selected: controller.selectedIndex.value == 4,
                onTap: () => controller.changePage(4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(color: Color(0xFF16A6D8), borderRadius: BorderRadius.all(Radius.circular(5))),
          child: SizedBox(
            width: 28,
            height: 28,
            child: Center(child: Text('F', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700))),
          ),
        ),
        SizedBox(width: 9),
        Text('FToolBox', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1E2034))),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
        child: Text(
          label.toUpperCase(),
          style: const TextStyle(fontSize: 10, color: Color(0xFF8C90A0), letterSpacing: 1.1, fontWeight: FontWeight.w600),
        ),
      );
}

class _VideoMenu extends StatelessWidget {
  const _VideoMenu({required this.controller, required this.expanded, required this.selectedIndex});

  final NavController controller;
  final bool expanded;
  final int selectedIndex;

  @override
  Widget build(BuildContext context) {
    final selected = selectedIndex == 1 || selectedIndex == 2;
    return Column(
      children: [
        _SidebarItem(
          icon: Icons.video_library_outlined,
          label: '视频',
          selected: selected,
          trailing: Icon(expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded, size: 20),
          onTap: controller.toggleVideoMenu,
        ),
        if (expanded) ...[
          _SubmenuItem(label: '视频下载', selected: selectedIndex == 1, onTap: () => controller.changePage(1)),
          _SubmenuItem(label: '图片转视频', selected: selectedIndex == 2, onTap: () => controller.changePage(2)),
        ],
      ],
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({required this.icon, required this.label, required this.selected, required this.onTap, this.trailing});

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final color = selected ? _brandPurple : const Color(0xFF4C5163);
    return Material(
      color: selected ? const Color(0xFFF0ECFF) : Colors.transparent,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
          child: Row(
            children: [
              Icon(icon, size: 19, color: color),
              const SizedBox(width: 11),
              Expanded(child: Text(label, style: TextStyle(fontSize: 14, color: color, fontWeight: selected ? FontWeight.w600 : FontWeight.w400))),
              if (trailing != null) IconTheme(data: IconThemeData(color: color), child: trailing!),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubmenuItem extends StatelessWidget {
  const _SubmenuItem({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          margin: const EdgeInsets.only(left: 28, top: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFF0ECFF) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Container(width: 5, height: 5, decoration: BoxDecoration(color: selected ? _brandPurple : const Color(0xFFA5A9B6), shape: BoxShape.circle)),
              const SizedBox(width: 10),
              Text(label, style: TextStyle(fontSize: 13, color: selected ? _brandPurple : const Color(0xFF5D6273), fontWeight: selected ? FontWeight.w600 : FontWeight.w400)),
            ],
          ),
        ),
      ),
    );
  }
}

class _WorkspaceHeader extends StatelessWidget {
  const _WorkspaceHeader({required this.controller});

  final NavController controller;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Row(
          children: [
            const Icon(Icons.space_dashboard_outlined, size: 19, color: Color(0xFF8B90A0)),
            const SizedBox(width: 9),
            const Text('我的工具箱', style: TextStyle(color: Color(0xFF696E7D), fontSize: 13)),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Icon(Icons.chevron_right_rounded, size: 17, color: Color(0xFFB0B4C0)),
            ),
            Obx(() => Text(controller.currentTitle, style: const TextStyle(fontSize: 13, color: Color(0xFF696E7D)))),
          ],
        ),
      ),
    );
  }
}

class NavController extends GetxController {
  final selectedIndex = 0.obs;
  final videoExpanded = true.obs;

  final List<Widget> pages = [
    ResetFileByTimePage(),
    VideoDownloaderPage(),
    PicToVideoPage(),
    PomodoroPage(),
    AboutPage(),
  ];

  String get currentTitle => const ['文件整理', '视频下载', '图片转视频', '番茄钟', '关于'][selectedIndex.value];

  void changePage(int index) {
    selectedIndex.value = index;
    if (index == 1 || index == 2) videoExpanded.value = true;
  }

  void toggleVideoMenu() => videoExpanded.toggle();
}
