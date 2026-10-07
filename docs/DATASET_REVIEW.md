# 动作数据集核查

核查日期：2026-10-07。来源：https://github.com/hasaneyldrm/exercises-dataset

## 许可

- LICENSE：MIT 仅覆盖代码、工具、数据结构、说明文本/翻译。复用文字数据需要保留 copyright 与完整许可。
- LICENSE 的 MEDIA EXCEPTION：images/ 与 videos/ 不属于 MIT。版权归 Gym visual；克隆仓库不授予媒体许可，需自行取得许可。
- NOTICE.md：上游获单独书面许可，180×180 分辨率，需保留“© Gym visual — https://gymvisual.com/”。该授权不能自动转授给本 App。
- 本阶段不集成动作数据，不下载或打包图片/GIF。后续优先文字数据，媒体集成必须先核对独立许可。
- 尚未审核 Gym visual 具体条款，也未获得本 App 的媒体授权，因此不声明可使用媒体。

## 数据结构

data/exercises.json 为记录数组（上游目录报告约 17.4 MB），schema 使用 JSON Schema draft 2020-12。
必填字段：id、name、category、body_part、equipment、instructions、instruction_steps、muscle_group、secondary_muscles、target、media_id、image、gif_url、attribution、created_at。
id 为四位数字字符串，不能转为整数丢失前导零。instructions 与 instruction_steps 有 zh、en 等语言键；name 是单个字符串，并无 nameZh/nameEn。因此后续需单独补齐与校对动作中文显示名，不把英文 name 当作已有双语名称。
body_part 枚举：back、cardio、chest、lower arms、lower legs、neck、shoulders、upper arms、upper legs、waist。导入时统一固定 ID，中文/英文显示使用本地化资源。
媒体路径为相对 images/...jpg 或 videos/...gif，不能当作已经获授权的 App 资源。

本次仅检查 LICENSE、NOTICE.md、目录元数据和 schema，尚未导入或逐记录校验完整数据文件。集成时固定 Git 提交、校验 ID 唯一性和语言覆盖率，并保存文本许可证。

参考文件：
- https://github.com/hasaneyldrm/exercises-dataset/blob/main/LICENSE
- https://github.com/hasaneyldrm/exercises-dataset/blob/main/NOTICE.md
- https://github.com/hasaneyldrm/exercises-dataset/blob/main/data/exercises.schema.json

设计参考：https://github.com/emilkowalski/skills/blob/main/skills/apple-design/SKILL.md
采用清晰层级、系统字体、可访问性、及时反馈和克制动效；其 Web 技术示例不直接移植为 Flutter 自建框架。
