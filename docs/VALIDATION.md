# 第一阶段验收记录

日期：2026-10-09。平台：Windows 11；独立 Conda 环境 fitness_app_dev。

## 已完成的检查

- 原始 Flutter 工程：默认计数器测试通过，默认 Android 调试 APK 构建通过，然后才增加基础功能。
- Flutter 3.47.6 / Dart 3.13.5 / OpenJDK 17.0.18；flutter doctor 的 Android 工具链检查通过，Android 许可已接受。
- flutter gen-l10n：成功；中英文 ARB 各 93 个业务资源键一致，未缺少翻译。系统控件使用 Flutter 自带中文/英文本地化。
- flutter analyze：No issues found。
- flutter test：12 项通过（9 项界面/主题/计算接口测试，3 项真实 SQLite 文件测试）。
- 测试包含五页导航、中文系统与英文回退、语言保存和恢复、系统语言变化、体重输入校验与首页刷新、保存失败恢复、启动失败重试、窄屏英文 150% 字号、无公式时明确不可用。
- 数据库测试包含关闭并重新打开文件、同日更新/不同日保留、非法值不覆盖、外键约束、仅一个启用计划、日期安排约束、自由文本不翻译。
- 已查看 build/qa 下的中文首页、饮食、日历、设置和英文大字号设置截图；为电脑端 Flutter 测试渲染，未冒充手机截图。测试仅从电脑加载系统字体，APK 不打包 Windows 字体。
- tools/dev.py、tools/setup_env.py 的 Python 语法检查通过。已检查 Widget 固定文字来自 ARB；Android 桌面名称使用 Android 中文/英文资源。
- 已安装并应用 `apple-design` skill 的可读层级、克制圆角、间距和对比度原则；强调色编辑覆盖十六进制、RGB、非法输入和本地恢复。

## 训练计划管理小步

- 训练计划支持创建、重命名、切换当前计划、取消删除和确认删除。
- 首个计划自动成为当前计划；删除当前计划后最早创建的剩余计划自动接替；删除全部计划后可重新创建。
- 名称会去除首尾空格并限制为 1–60 个 Unicode 字符；计划名称是用户输入，不随语言切换翻译。
- 所有写操作使用 SQLite 事务；失败时不会留下半完成的当前计划切换或删除结果。
- `flutter analyze`：No issues found。
- `flutter test`：17 项全部通过；包含计划 CRUD、重启恢复、级联删除、事务回滚、名称校验、保存失败恢复、中文/英文和 150% 大字号截图。

## 最终 APK

- UI/强调色版本 `flutter build apk --debug` 成功（44.5 秒）。
- 文件：build/app/outputs/flutter-apk/app-debug.apk；183,662,909 字节，约 175.2 MiB。这是个人验收用调试版，尚未配置正式发布签名。
- aapt2 核对：com.local.fitnotes.fit_notes；版本 0.1.0（1）；minSdk 24（Android 7.0），targetSdk / compileSdk 36；支持 arm64-v8a、armeabi-v7a、x86_64。
- aapt2 核对桌面名称：英文 Fit Notes；zh / zh-CN / zh-HK / zh-TW / zh-Hant 均为健食日记。
- SHA256：A918F796873A3332776A531E0156C8D1C59654A11EDE5820B7D5E749CFCFE581。

## 训练计划版本 APK

- `flutter build apk --debug`：成功（96.4 秒）。
- 文件：`build/app/outputs/flutter-apk/app-debug.apk`；183,678,743 字节，约 175.2 MiB。
- SHA256：`FE449572FA0833584F835EAB975A721DCB8E4E1BD6AA2F859257CFA255CF32FE`。

## 尚需手机验收

当前 devices 未发现 Android 手机或模拟器，因此 Android 原生插件集成测试、真实启动、系统杀进程重启、飞行模式、输入键盘与 USB 安装尚未实测。

连接 Android 7.0 或以上手机后，按 README 的 USB 步骤安装。先检查五页、中英文切换和重启保存，再检查体重保存、强行停止后读取和飞行模式使用。可运行隔离测试：

```powershell
python tools/dev.py integration -d 设备ID
```

每周训练安排、单日覆盖、实际打卡、餐食记录、背景和拍照不属于本阶段；当前界面明确说明后续实现。没有导入动作数据或媒体，没有加入减脂公式。
