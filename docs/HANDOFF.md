# MorningBrief 开发交接

更新时间：2026-07-11（Asia/Shanghai）

## 当前状态

- 默认分支：`master`
- 当前提交：`297293c fix: reload stocks after reverted settings`
- 远程：`origin` → `git@github.com:DDDyyhhh/MorningBrief.git`
- 已完成：Task 1–8（项目外壳、核心基础设施、首页/设置、日程、天气、综合新闻、股票）
- 下一项：Task 9，科技 / AI 新闻模块

`master` 已包含 Task 1–8 的全部实现。不要在 `master` 上直接开发新功能；请为 Task 9 创建独立分支和工作树。

## 最新验证

在 `master` 上于 2026-07-11 完成：

- `flutter test`：124 项通过
- `flutter analyze`：`No issues found!`

尚未验证：Android 真机/模拟器运行，以及真实 OpenWeatherMap、Alpha Vantage 和 RSS 服务的发布前 smoke test。测试不得调用真实外部接口，API Key 不得提交。

## Task 8（股票）已交付内容

- Alpha Vantage `GLOBAL_QUOTE` 行情获取，多代码顺序请求、部分成功保留成功行情。
- 处理空行情、所有请求失败、`Note` / `Information` 限频响应。
- 15 分钟缓存；网络失败时回退到过期缓存并显示离线状态。
- 缺少 API Key 时显示设置引导；缓存读写或坏缓存不会使模块崩溃。
- 首页与设置接线完成：模块禁用时不加载，启用或配置变化时恰好重新加载一次。
- 卡片标题为“股票财经”；中国市场习惯：涨红（`AppColors.profitRed`）、跌绿（`AppColors.lossGreen`）。

不要擅自修改默认股票代码 `600036.SHH`、`000001.SHZ`。

## Task 9 目标

按 `docs/superpowers/plans/2026-07-07-morningbrief.md` 中的“Task 9: Tech/AI News Module”执行：

- 新增 `lib/modules/tech_news/` 下的 service、provider 与 card。
- 复用现有 `NewsService` 的 RSS 解析能力、`NewsArticle`、缓存基础设施与 `AppConstants.techNewsFeeds`。
- 使用独立于综合新闻的缓存 key，卡片标题为“科技 AI 新闻”。
- 更新 `lib/main.dart` 与 `lib/shared/screens/home_screen.dart`，并为 service/provider/card 与启动集成补齐确定性测试。

开发前先阅读 `AGENTS.md` 和完整的 Task 9 计划；遵循 TDD，禁止测试访问真实网络。新模块的初始加载不能阻塞 `runApp`，并要覆盖模块禁用、同会话重新启用、配置变化与离线缓存回退等生命周期行为。

## 关键文件

- `AGENTS.md`：项目约定和验证命令
- `docs/superpowers/plans/2026-07-07-morningbrief.md`：完整实现计划
- `lib/main.dart`：依赖注入与启动生命周期
- `lib/shared/screens/home_screen.dart`：模块路由
- `lib/modules/news/`：可复用 RSS 与新闻模块参考实现
- `lib/modules/stocks/`：最新完成模块的参考实现

## 工作流

1. 从最新 `master` 创建 Task 9 专用分支和隔离工作树。
2. 在新工作树运行 `flutter test` 与 `flutter analyze`，确认干净基线。
3. 先写失败测试，再实现最小代码；每个阶段运行相关测试。
4. 完成后运行完整测试、静态分析与 `git diff --check`，再进行规格与代码质量审查。

旧 `.worktrees/morningbrief-sdd/HANDOFF.md` 是 Task 8 开始前的临时文件，内容已被本文件取代，可随旧工作树一并删除。
