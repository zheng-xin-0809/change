# Fit Notes：小步实施计划

目标：Android 优先，中文 / English，离线可用；先验证工程，再逐阶段增加功能。

## 页面

底部五个入口：首页、训练计划、饮食管理、日历打卡、设置。
- 首页：当天日期、记录概览、训练和饮食快捷入口。
- 训练计划：已支持多个计划的创建、重命名、切换和删除；后续加入七天重复、训练/休息、当天覆盖。
- 饮食管理：四餐展示，手动记录体重用于验证数据库。餐食营养与照片在后续阶段加入。
- 日历：本阶段月历及说明，后续训练/休息标记和训练部位。
- 设置：系统/中文/English，本地保存；后续背景选择与透明度。

## 数据模型

| 模型 | 关键字段 | 约定 |
|---|---|---|
| Exercise | id, bodyPartId, nameZh, nameEn, instructionsZh/En | 保留上游 ID，中文名称需要人工核对；不打包未获授权媒体 |
| TrainingPlan | id, name, active | name 为用户输入，不翻译；仅一个 active 计划 |
| PlanDay | planId, weekday, kind, timeSlotId, bodyPartIds, exerciseIds | weekday 1–7；kind training/rest；七天按周重复 |
| DayOverride | localDate, kind, timeSlotId, bodyPartIds, exerciseIds | 优先于周模板，不修改周模板；日期 YYYY-MM-DD |
| MealEntry | id, localDate, mealTypeId, foodName, carbsG, proteinG, fatG, note | 四种固定餐次 ID；自由文本不翻译；克数手动填写 |
| WeightEntry | localDate, kilograms | 同一天一条体重记录，可覆盖 |
| CheckIn | localDate, kind, bodyPartIds, completedAt | 独立保存完成快照，修改计划不改历史 |
| Photo | id, mealEntryId, relativePath | 照片复制到应用私有持久目录，记录相对路径 |
| Preferences | localeMode, backgroundRelativePath, opacity | system/zh/en；偏好持久化 |

固定训练时段：after_breakfast、before_lunch、after_dinner、before_dinner。
固定餐次：breakfast、pre_workout、post_workout、other。
训练部位沿用上游类别并规范化 ID，例如 upper_arms、lower_legs；显示名来自 ARB。
日期按手机本地日历日期保存，禁止以 UTC 午夜代替日历日期。

## 实现阶段与验收

1. 环境与基础版本：先 flutter doctor、默认项目构建；再五页、ARB 本地化、SQLite schema 和体重记录、语言保存、计算接口。检查分析、测试、APK 构建。手机验收：五页切换、中英文切换、重启保存语言及体重、飞行模式使用。
2. 训练计划管理（当前小步）：多个计划、名称校验、当前计划切换、删除确认、本地事务和重启恢复。下一小步加入周重复、四时段、休息和当天覆盖，再加入完成快照；审核后仅集成文字动作。验收跨周日期、当天覆盖不影响模板、历史完成不被修改。
3. 饮食与照片：四餐、营养素手工录入、拍照/选择、文件持久化和清理。验收杀进程后照片保留、权限拒绝可恢复、离线记录。
4. 背景与完善：相册背景、透明度、文字对比度、大字号、Android 返回、USB 安装与离线回归。
5. 公式：只在用户提供公式与餐次分配规则后实现 CalculationService；增加有意义的公式边界测试。

## 技术选择

Flutter 稳定版、SDK 自带 ChangeNotifier、flutter_localizations + gen-l10n + ARB、intl；业务数据 sqflite，偏好 shared_preferences，持久文件 path_provider，路径 path。后续拍照优先 image_picker。不引入额外路由框架或自建状态框架。

SQLite 位于 Android 应用私有 databases/fit_notes.db；媒体后续放 getApplicationDocumentsDirectory()/media 下。卸载/清除数据会移除本地内容，尚无导出恢复功能。关闭 Android 自动备份，避免第一版记录被系统自动上传。

所有页面标题、按钮、提示、业务固定名来自 ARB；系统组件由 Flutter 本地化。系统中文（含地区变体）选择中文，其余语言回退 English。用户输入不翻译。

## 本阶段范围

本次完成阶段 1 后停下；阶段 2–5 不提前实现。无营养建议、无减脂公式、无运动媒体下载。
