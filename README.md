# 健食日记 / Fit Notes

Android 优先的离线 Flutter App。目前已完成基础版和训练计划管理小步。

已实现：五个基础页面；默认跟随系统语言；设置切换中文 / English 并保存；手动记录今日体重、同日修改和首页显示；SQLite 数据结构；可在设置中用 RGB 滑块或六位十六进制代码修改强调色并本地保存；创建、重命名、切换和删除多个训练计划并本地保存；独立计算服务接口（尚无公式）。

本次 UI 按 [apple-design skill](https://github.com/emilkowalski/skills/tree/main/skills/apple-design) 的层级、间距、可读性和及时反馈原则调整，强调色会根据对比度选择按钮文字颜色。

后续阶段：训练计划的每周训练/休息安排、单日修改和打卡；动作文字库、餐食营养与拍照、背景设置。页面中的阶段提示会明确说明尚未开放的功能。

- [页面结构、数据模型和实施顺序](docs/PLAN.md)
- [动作数据与媒体许可证核查](docs/DATASET_REVIEW.md)
- [本阶段检查结果与待验收项目](docs/VALIDATION.md)

## 环境

独立 Conda 环境：`fitness_app_dev`，未修改 base 或其他已有环境。

| 组件 | 本次版本 / 位置 |
|---|---|
| Python | 3.12，Conda 环境内 |
| OpenJDK | 17，Conda 环境内 |
| Flutter / Dart | 3.47.6 / 3.13.5，环境的 tools/flutter |
| Android SDK | API 36 / 35、Build Tools 36.0.0、NDK 28.2.13676358、CMake 3.22.1，环境的 tools/android-sdk |
| Dart 包缓存 / Gradle 缓存 | 环境的 tools/pub-cache、tools/gradle-cache |

Flutter、Dart、Android SDK 不通过 pip 安装。项目使用的 Flutter 依赖写在 pubspec.yaml，解析版本写在 pubspec.lock。

进入项目（PowerShell / Anaconda Prompt）：

```powershell
cd C:\Users\25738\Desktop\change
conda activate fitness_app_dev
python tools/dev.py doctor
python tools/dev.py devices
```

如果当前 PowerShell 未初始化 Conda，可直接使用：

```powershell
conda run --no-capture-output -n fitness_app_dev python tools/dev.py doctor
```

工具入口只为子进程设置 SDK 路径与缓存，不修改全局 PATH。无须 Visual Studio；它只用于 Windows 桌面开发。

在其他机器重建环境：`conda env create -f environment.yml`，再在该环境运行 `python tools/setup_env.py` 和 `python tools/dev.py deps`。SDK 安装器下载官方安装包并核对官方校验值。首次下载需要联网，App 使用本地记录时无需联网。

## 检查与编译

```powershell
python tools/dev.py deps
python tools/dev.py check
python tools/dev.py build
```

`check` 执行本地化生成、静态分析、测试。测试覆盖本地数据库文件重新打开、体重更新、训练计划事务和恢复、数据约束、语言选择、保存失败、大字号和计算接口未配置。`build` 输出调试 APK：`build/app/outputs/flutter-apk/app-debug.apk`。这是个人开发验收版，尚未配置正式发布签名。

## USB 手机运行与安装

需要 Android 7.0（API 24）或以上。

1. 手机打开“开发者选项”和“USB 调试”；使用支持数据传输的 USB 线连接电脑。首次连接在手机确认调试授权。部分品牌还需打开“通过 USB 安装”。
2. 运行 `python tools/dev.py devices`，确认出现 Android 设备。若显示 unauthorized，解锁手机并接受授权；若没有设备，检查 USB 模式、数据线和手机厂商驱动。
3. 运行 `python tools/dev.py run -d 设备ID`，首次会编译、安装并启动。电脑终端按 `q` 退出调试，App 仍保留在手机上。
4. 已编译 APK 也可通过 `python tools/dev.py install -s 设备ID` 安装，再从手机桌面打开“健食日记”。该安装命令只安装当前调试 APK，不重编译。

无需额外安装 Android Studio。若希望用模拟器，可以后续安装 Android Studio 的 Device Manager、开启硬件虚拟化、创建 API 24 以上虚拟机，启动后同样通过 devices/run 验收。本次没有可用 Android 设备或已配置的模拟器。

## 当前版本：你在手机上检查

1. 首次启动应按手机系统语言显示；中文（含地区变体）→ 中文，其余语言 → English。
2. 逐一进入首页、计划、饮食、日历、设置。检查文字可读、导航可点、日历可选日期。
3. 进入“计划”，创建“力量训练”和“周末计划”两个计划。确认首个自动成为当前计划，第二个可设为当前计划；重命名、取消删除和确认删除都正常，删除当前计划后剩余计划自动成为当前计划。
4. 设置选择 English，五页标题和固定名称应随之切换；切回中文。关闭并重新打开 App，确认语言、当前计划和计划名称保留。选择“跟随系统”后修改系统语言并返回 App，确认自动跟随。
5. 设置页向下滚动到“强调色”，输入 `#FF0000` 或拖动 RGB 滑块，点击保存后检查按钮和选中状态颜色变化；重新打开 App 后颜色仍保留。饮食页记录今日体重，例如 65.5。首页应显示该体重；再次保存 65.2 应更新今天。负数、空白或非数字应提示错误。
6. 强行停止 App 再打开，确认语言、计划和体重都保留。打开飞行模式，再记录一次体重，确认能保存。增大系统字体，检查五页和输入弹窗。
7. 从其他页按 Android 返回键应回到首页，从首页返回按系统行为退出。

手机插件验收测试（可选，使用独立测试数据，不改动正式记录）：`python tools/dev.py integration -d 设备ID`。这个测试不会代替手动强行停止/重启与飞行模式验收。

## 本地数据

- 业务数据：Android App 私有 databases/fit_notes.db；schema version 1。训练计划名称和当前计划状态写入 `training_plans`，计划删除使用 SQLite 外键级联清理未来的每周安排。
- 语言偏好：SharedPreferencesAsync，Android 默认使用 DataStore；不与文字显示名混存。
- 强调色偏好：SharedPreferencesAsync，以六位大写十六进制代码保存；RGB 与显示颜色由固定 `AccentColor` ID 值转换。
- 文件基础目录：path_provider 的 App 私有 documents/media。当前版本不请求相册或摄像头权限，也尚未存照片。后续会复制所选/所拍照片到该目录，数据库只记录相对路径，避免临时文件过期。
- 已关闭 Android 自动备份，第一版不提供云同步或导出恢复。卸载 / 清除应用数据会删除内容；同签名覆盖安装通常保留记录。

应用固定文字使用 Flutter gen-l10n 的 ARB 资源。动作、部位、餐次和训练时段使用固定 ID，显示名称独立本地化；用户输入不自动翻译。公式接口位于 lib/services/calculation_service.dart，未配置服务只返回不可用并抛出明确异常，不生成任何营养目标。

每完成一阶段先验收，再继续下一阶段。本阶段手机体验确认后，下一步实现每周训练安排、单日修改和日历打卡。
