import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show PopupMenuItem, showMenu;

import 'package:celechron/utils/platform_features.dart';

/// 桌面端多栏布局的窗口宽度阈值（扣掉侧边栏后内容区约 850）
const double desktopMultiColumnMinWidth = 940;

/// 当前是否应使用桌面端多栏布局。[width] 为窗口宽度。
bool useDesktopColumns(double width) =>
    PlatformFeatures.isDesktop && width >= desktopMultiColumnMinWidth;

/// 移动端从底部弹出的面板；桌面端改为居中对话框，避免宽屏下整条横跨底部。
/// 参数与 [showCupertinoModalPopup] 一致，可直接替换。
Future<T?> showAdaptivePopup<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  if (!PlatformFeatures.isDesktop) {
    return showCupertinoModalPopup<T>(
      context: context,
      builder: builder,
      barrierDismissible: barrierDismissible,
    );
  }
  return showCupertinoDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (context) {
      final size = MediaQuery.sizeOf(context);
      return SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 600,
              maxHeight: size.height * 0.88,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: MediaQuery.removePadding(
                context: context,
                removeTop: true,
                removeBottom: true,
                child: builder(context),
              ),
            ),
          ),
        ),
      );
    },
  );
}

/// 桌面端右键菜单的一项
class DesktopMenuAction {
  const DesktopMenuAction(this.label, this.icon, this.onSelected,
      {this.destructive = false});

  final String label;
  final IconData icon;
  final VoidCallback onSelected;
  final bool destructive;
}

/// 在鼠标位置弹出右键菜单，替代移动端的滑动/长按操作
Future<void> showDesktopContextMenu(BuildContext context, Offset globalPosition,
    List<DesktopMenuAction> actions) async {
  final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
  final local = overlay.globalToLocal(globalPosition);
  final selected = await showMenu<int>(
    context: context,
    position: RelativeRect.fromLTRB(local.dx, local.dy,
        overlay.size.width - local.dx, overlay.size.height - local.dy),
    items: [
      for (var i = 0; i < actions.length; i++)
        PopupMenuItem<int>(
          value: i,
          height: 40,
          child: Row(
            children: [
              Icon(actions[i].icon,
                  size: 18,
                  color: actions[i].destructive
                      ? CupertinoColors.systemRed
                      : CupertinoDynamicColor.resolve(
                          CupertinoColors.label, context)),
              const SizedBox(width: 10),
              Text(
                actions[i].label,
                style: TextStyle(
                    fontSize: 14,
                    color: actions[i].destructive
                        ? CupertinoColors.systemRed
                        : CupertinoDynamicColor.resolve(
                            CupertinoColors.label, context)),
              ),
            ],
          ),
        ),
    ],
  );
  if (selected != null) actions[selected].onSelected();
}

/// 桌面端：把横向滚动列表换成按宽度自动分栏的网格，不需要拖动就能看到全部内容；
/// 移动端保持原来的横向列表
class DesktopWrapOrScroll extends StatelessWidget {
  const DesktopWrapOrScroll({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required this.itemWidth,
    required this.itemHeight,
    this.spacing = 8,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;

  /// 移动端条目宽度；桌面端作为最小宽度，剩余空间均分给每栏
  final double itemWidth;
  final double itemHeight;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    if (PlatformFeatures.isDesktop) {
      return LayoutBuilder(builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns =
            ((width + spacing) / (itemWidth + spacing)).floor().clamp(1, 99);
        final cellWidth = (width - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (var i = 0; i < itemCount; i++)
              SizedBox(
                  width: cellWidth,
                  height: itemHeight,
                  child: itemBuilder(context, i)),
          ],
        );
      });
    }
    return SizedBox(
      height: itemHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: itemCount,
        separatorBuilder: (context, index) => SizedBox(width: spacing),
        itemBuilder: (context, index) =>
            SizedBox(width: itemWidth, child: itemBuilder(context, index)),
      ),
    );
  }
}
