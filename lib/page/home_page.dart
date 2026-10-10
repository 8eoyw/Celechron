import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart' show Icons;
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'package:celechron/page/scholar/scholar_controller.dart';
import 'package:celechron/page/scholar/scholar_view.dart';
import 'package:celechron/page/flow/flow_view.dart';
import 'package:celechron/page/task/task_view.dart';
import 'package:celechron/page/calendar/calendar_view.dart';
import 'package:celechron/page/option/option_view.dart';

import 'package:celechron/utils/platform_features.dart';
import 'package:celechron/worker/fuse.dart';

const _tabs = <(IconData, String)>[
  (CupertinoIcons.time, '接下来'),
  (CupertinoIcons.calendar, '日程'),
  (CupertinoIcons.check_mark, '任务'),
  (Icons.school_rounded, '学业'),
  (CupertinoIcons.settings, '设置'),
];

/// 桌面端窗口宽度达到此值时改用侧边栏导航
const double _sidebarMinWidth = 640;

/// 桌面端内容区最大宽度，宽屏下居中，避免卡片被拉得过宽
const double _desktopContentMaxWidth = 1100;

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});

  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _indexNum = 0;
  final PageController _pageController = PageController();

  // 只构建一次，保持各页 widget 身份稳定，切页时不会重跑各页构造器里的 Get.put
  late final List<Widget> _pages = [
    _KeepAlivePage(child: FlowPage()),
    _KeepAlivePage(child: CalendarPage()),
    _KeepAlivePage(child: TaskPage()),
    _KeepAlivePage(child: ScholarPage()),
    _KeepAlivePage(child: OptionPage()),
  ];

  @override
  void initState() {
    super.initState();
    if (PlatformFeatures.isDesktop) {
      HardwareKeyboard.instance.addHandler(_handleTabShortcut);
    }
    initFuse();
  }

  @override
  void dispose() {
    if (PlatformFeatures.isDesktop) {
      HardwareKeyboard.instance.removeHandler(_handleTabShortcut);
    }
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tabBar = CupertinoTabBar(
      iconSize: 26,
      backgroundColor: CupertinoDynamicColor.resolve(
              CupertinoColors.secondarySystemBackground, context)
          .withValues(alpha: 0.5),
      items: [
        for (final (icon, label) in _tabs)
          BottomNavigationBarItem(icon: Icon(icon), label: label),
      ],
      currentIndex: _indexNum,
      // 点按瞬时切换（iOS 原生习惯）。jumpToPage 会同步触发 onPageChanged，
      // _indexNum 只在 onPageChanged 里更新，这里不再 setState
      onTap: _selectTab,
    );
    final isDesktop = PlatformFeatures.isDesktop;

    final ScrollBehavior scrollBehavior = ScrollConfiguration.of(context);
    // HeroMode 关闭：原先嵌套 CupertinoTabView 导航器会屏蔽标签页内的 Hero
    // 飞行动画（如学业页成绩卡片），这里显式关闭以保持原有行为
    Widget content = HeroMode(
      enabled: false,
      child: PageView(
        controller: _pageController,
        // 桌面端不允许鼠标拖动切页：会与页内横向列表的拖动、文本选择冲突，
        // 切页交给侧边栏/标签栏与 Ctrl+数字键
        physics: isDesktop ? const NeverScrollableScrollPhysics() : null,
        onPageChanged: (index) {
          if (index != _indexNum) {
            setState(() {
              _indexNum = index;
            });
          }
        },
        // 允许鼠标拖动切页（与原 GestureDetector 行为一致），只作用于本 PageView，
        // 不影响页面内部列表；scrollbars 必须关掉，否则桌面端会叠一条横向滚动条
        scrollBehavior: scrollBehavior.copyWith(
          scrollbars: false,
          dragDevices: {
            ...scrollBehavior.dragDevices,
            PointerDeviceKind.mouse,
          },
        ),
        children: _pages,
      ),
    );

    // 以下复刻 CupertinoTabScaffold（resizeToAvoidBottomInset: true）的布局逻辑：
    // 键盘高度转为内容 Padding 并从子 MediaQuery 移除；本应用标签栏为半透明
    // （alpha 0.5），栏高只注入 MediaQuery.padding，内容延伸到栏后方由各页
    // SafeArea 自行避让
    if (isDesktop && MediaQuery.sizeOf(context).width >= _sidebarMinWidth) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: CupertinoTheme.of(context).scaffoldBackgroundColor,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _DesktopSidebar(currentIndex: _indexNum, onSelect: _selectTab),
            Container(
              width: 0.5,
              color: CupertinoDynamicColor.resolve(
                  CupertinoColors.separator, context),
            ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints:
                      const BoxConstraints(maxWidth: _desktopContentMaxWidth),
                  child: content,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final MediaQueryData existingMediaQuery = MediaQuery.of(context);
    MediaQueryData newMediaQuery =
        existingMediaQuery.removeViewInsets(removeBottom: true);
    final EdgeInsets contentPadding =
        EdgeInsets.only(bottom: existingMediaQuery.viewInsets.bottom);

    // 键盘完全盖住标签栏时不再为栏高留白
    if (tabBar.preferredSize.height > existingMediaQuery.viewInsets.bottom) {
      final double bottomPadding =
          tabBar.preferredSize.height + existingMediaQuery.padding.bottom;
      newMediaQuery = newMediaQuery.copyWith(
        padding: newMediaQuery.padding.copyWith(bottom: bottomPadding),
      );
    }

    final scaffold = DecoratedBox(
      decoration: BoxDecoration(
        color: CupertinoTheme.of(context).scaffoldBackgroundColor,
      ),
      child: Stack(
        children: [
          // 内容在下层，半透明标签栏的 BackdropFilter 才有内容可模糊
          MediaQuery(
            data: newMediaQuery,
            child: Padding(padding: contentPadding, child: content),
          ),
          // 标签栏放在修改后的 MediaQuery 之外，读原始 viewPadding 计算安全区
          MediaQuery.withNoTextScaling(
            child: Align(alignment: Alignment.bottomCenter, child: tabBar),
          ),
        ],
      ),
    );
    return scaffold;
  }

  void _selectTab(int index) => _pageController.jumpToPage(index);

  static const _tabDigits = [
    LogicalKeyboardKey.digit1,
    LogicalKeyboardKey.digit2,
    LogicalKeyboardKey.digit3,
    LogicalKeyboardKey.digit4,
    LogicalKeyboardKey.digit5,
  ];

  /// 桌面端快捷键：Ctrl+1~5 切换标签页、F5 刷新。挂在 HardwareKeyboard 上而非
  /// Shortcuts 组件，不依赖当前焦点位置（启动后焦点不一定在页面树内）
  bool _handleTabShortcut(KeyEvent event) {
    // F5 刷新学业数据（替代移动端的下拉刷新）；进行中的刷新会被复用
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.f5 &&
        mounted &&
        Get.isRegistered<ScholarController>()) {
      Get.find<ScholarController>().fetchData();
      return true;
    }
    if (event is! KeyDownEvent ||
        !HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isAltPressed ||
        HardwareKeyboard.instance.isShiftPressed) {
      return false;
    }
    final index = _tabDigits.indexOf(event.logicalKey);
    if (index < 0 || !mounted) return false;
    _selectTab(index);
    return true;
  }

  Future<void> initFuse() async {
    await Future.delayed(const Duration(seconds: 1));
    var fuse = Get.find<Rx<Fuse>>(tag: 'fuse');
    var response =
        await fuse.value.checkUpdate().whenComplete(() => fuse.refresh());
    if (response != null) {
      if (!mounted) return;
      showCupertinoDialog(
          context: context,
          builder: (context) {
            return CupertinoAlertDialog(
              title: const Text('更新可用'),
              content: Text(response),
              actions: [
                CupertinoDialogAction(
                  child: const Text('忽略'),
                  onPressed: () async {
                    Navigator.of(context).pop();
                  },
                ),
                CupertinoDialogAction(
                  child: const Text('访问网站'),
                  onPressed: () async {
                    await launchUrlString(
                      'https://celechron.top',
                      mode: LaunchMode.externalApplication,
                    );
                  },
                ),
              ],
            );
          });
    }
  }
}

// 离屏页面保活：保留滚动位置等临时状态，等价于原先 CupertinoTabScaffold
// 对已构建标签页的常驻行为
class _KeepAlivePage extends StatefulWidget {
  const _KeepAlivePage({required this.child});

  final Widget child;

  @override
  State<_KeepAlivePage> createState() => _KeepAlivePageState();
}

class _KeepAlivePageState extends State<_KeepAlivePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

/// 桌面端侧边栏导航，替代移动端的底部标签栏
class _DesktopSidebar extends StatelessWidget {
  const _DesktopSidebar({required this.currentIndex, required this.onSelect});

  final int currentIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 84,
      color: CupertinoDynamicColor.resolve(
          CupertinoColors.secondarySystemBackground, context),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        // 选项撑满侧边栏宽度，选中底色才不会只包住图标显得又窄又扁
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < _tabs.length; i++)
            _SidebarItem(
              icon: _tabs[i].$1,
              label: _tabs[i].$2,
              selected: i == currentIndex,
              semanticLabel: '${_tabs[i].$2}，Ctrl+${i + 1}',
              onTap: () => onSelect(i),
            ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatefulWidget {
  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.semanticLabel,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final activeColor = CupertinoTheme.of(context).primaryColor;
    final inactiveColor =
        CupertinoDynamicColor.resolve(CupertinoColors.secondaryLabel, context);
    final color = widget.selected ? activeColor : inactiveColor;
    final background = widget.selected
        ? activeColor.withValues(alpha: 0.12)
        : _hovered
            ? CupertinoDynamicColor.resolve(CupertinoColors.systemFill, context)
            : const Color(0x00000000);

    return Semantics(
      button: true,
      selected: widget.selected,
      label: widget.semanticLabel,
      excludeSemantics: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            padding: const EdgeInsets.symmetric(vertical: 13),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(widget.icon, size: 24, color: color),
                const SizedBox(height: 4),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight:
                        widget.selected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
