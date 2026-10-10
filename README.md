# Celechron

<div style="text-align: center; ">

<img src="./banner.png" style="width: 80%;">

服务于浙大学生的时间管理器

日程一览 · 课表查看 · DDL 助手 · 成绩查询

</div>

---

## 关于这个分支：Windows 桌面版（非官方）

这个仓库是 [Celechron](https://github.com/Celechron/Celechron) 的非官方分支，在原版基础上加了一套**为鼠标和大屏设计的 Windows 桌面界面**。登录与数据抓取完全沿用原版，只重写了界面。桌面版的问题请在本仓库提 Issue，不要打扰原作者。

- **下载**：见 [Releases](../../releases)，解压后运行 `Celechron.exe`（Windows 10/11 64 位）
- **总览**：下一节课、今天的时间轴、近期作业、明天安排，侧栏显示即将到来的考试
- **课表**：周视图 / 月视图 / 课时统计（总课时、各课程进度、每周节数），可切换学期
- **成绩、考试、学在浙大作业、任务 DDL**，深色模式，`Ctrl+1~6` 切页、`F5` 刷新
- 另外修复了课表因教务网限频（921）而变空的问题：请求串行、退避重试，失败时保留上次的课表

### 从源码编译

需要 Flutter 3.x 与 Visual Studio 2022（「使用 C++ 的桌面开发」，并额外勾选 **C++ ATL** 组件，否则 `flutter_secure_storage` 编译失败）。

```bash
flutter pub get
flutter build windows --release -t lib/main_desktop.dart
```

产物在 `build/windows/x64/runner/Release/`。桌面界面的代码在 `lib/desktop/`，设计说明见 `lib/desktop/DESIGN.md`；`flutter test test_desktop/layout_probe_test.dart` 可离屏检查各页面布局。
