# 第一阶段验收记录

日期：2026-10-07。平台：Windows 11；独立 Conda 环境 fitness_app_dev。

## 已完成的检查

- 原始 Flutter 工程：默认计数器测试通过，默认 Android 调试 APK 构建通过，然后才增加基础功能。
- Flutter 3.47.6 / Dart 3.13.5 / OpenJDK 17.0.18；flutter doctor 的 Android 工具链检查通过，Android 许可已接受。
- flutter gen-l10n：成功；中英文 ARB 各 83 个业务资源键一致，未缺少翻译。系统控件使用 Flutter 自带中文/英文本地化。
- flutter analyze：No issues found。
- flutter test：10 项通过（7 项界面/计算接口测试，3 项真实 SQLite 文件测试）。
- 测试包含五页导航、中文系统与英文回退、语言保存和恢复、系统语言变化、体重输入校验与首页刷新、保存失败恢复、启动失败重试、窄屏英文 150% 字号、无公式时明确不可用。
- 数据库测试包含关闭并重新打开文件、同日更新/不同日保留、非法值不覆盖、外键约束、仅一个启用计划、日期安排约束、自由文本不翻译。
- 已查看 build/qa 下的中文首页、饮食、日历、设置和英文大字号设置截图；为电脑端 Flutter 测试渲染，未冒充手机截图。测试仅从电脑加载系统字体，APK 不打包 Windows 字体。
- tools/dev.py、tools/setup_env.py 的 Python 语法检查通过。已检查 Widget 固定文字来自 ARB；Android 桌面名称使用 Android 中文/英文资源。

## 最终 APK

- 自定义基础版 flutter build apk --debug 成功；补齐中文繁体地区桌面名称后再次构建成功（22.7 秒）。
- 文件：build/app/outputs/flutter-apk/app-debug.apk；164,198,294 字节，约 156.6 MiB。这是个人验收用调试版，尚未配置正式发布签名。
- aapt2 核对：com.local.fitnotes.fit_notes；版本 0.1.0（1）；minSdk 24（Android 7.0），targetSdk / compileSdk 36；支持 arm64-v8a、armeabi-v7a、x86_64。
- aapt2 核对桌面名称：英文 Fit Notes；zh / zh-CN / zh-HK / zh-TW / zh-Hant 均为健食日记。
- SHA256：0C9AF524C595EC3B1FD56DD638BBDAE6D1EAFFCF853E2A8F0233876B00E68873。

## 尚需手机验收

当前 devices 未发现 Android 手机或模拟器，因此 Android 原生插件集成测试、真实启动、系统杀进程重启、飞行模式、输入键盘与 USB 安装尚未实测。

连接 Android 7.0 或以上手机后，按 README 的 USB 步骤安装。先检查五页、中英文切换和重启保存，再检查体重保存、强行停止后读取和飞行模式使用。可运行隔离测试：

```powershell
python tools/dev.py integration -d 设备ID
```

完整餐食记录、计划编辑、实际打卡、背景和拍照不属于本阶段；当前界面明确说明后续实现。没有导入动作数据或媒体，没有加入减脂公式。
