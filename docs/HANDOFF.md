# MorningBrief 开发交接

更新时间：2026-07-11（Asia/Shanghai）

## 当前状态

- 默认分支：`master`
- 当前工作分支：`codex/task9-tech-ai-news`
- 当前提交：`e5fc4bb feat: add tech AI news module`
- 远程：`origin` → `git@github.com:DDDyyhhh/MorningBrief.git`
- 已完成：Task 1–9（项目外壳、核心基础设施、首页/设置、日程、天气、综合新闻、股票、科技 / AI 新闻）
- 下一项：Task 10，刷新编排、收尾优化、文档与 Android 构建

`master` 当前已包含 Task 1–8。Task 9 已在独立工作树的 `codex/task9-tech-ai-news` 分支提交，尚未合并回 `master`；不要在 `master` 上直接开发新功能。

## 最新验证

在 `codex/task9-tech-ai-news` 上于 2026-07-11 完成：

- `flutter test`：141 项通过
- `flutter analyze`：`No issues found!`
- `git diff --check`：通过

尚未验证：Android 真机/模拟器运行，以及真实 OpenWeatherMap、Alpha Vantage 和 RSS 服务的发布前 smoke test。测试不得调用真实外部接口，API Key 不得提交。

## Task 8（股票）已交付内容

- Alpha Vantage `GLOBAL_QUOTE` 行情获取，多代码顺序请求、部分成功保留成功行情。
- 处理空行情、所有请求失败、`Note` / `Information` 限频响应。
- 15 分钟缓存；网络失败时回退到过期缓存并显示离线状态。
- 缺少 API Key 时显示设置引导；缓存读写或坏缓存不会使模块崩溃。
- 首页与设置接线完成：模块禁用时不加载，启用或配置变化时恰好重新加载一次。
- 卡片标题为“股票财经”；中国市场习惯：涨红（`AppColors.profitRed`）、跌绿（`AppColors.lossGreen`）。

不要擅自修改默认股票代码 `600036.SHH`、`000001.SHZ`。

## Task 9（科技 / AI 新闻）已交付内容

- 新增 `lib/modules/tech_news/` 的 service、provider、card，以及对应的 service/provider/card 测试。
- `TechNewsService` 复用 `NewsService` 的 RSS 解析，默认使用 `AppConstants.techNewsFeeds`；不访问真实网络的测试已覆盖其委托行为。
- `TechNewsProvider` 使用独立缓存 key `AppConstants.cacheTechNews` 和 1 小时 TTL；覆盖成功、空结果、损坏/不可读缓存、缓存写入失败、离线回退和网络错误。
- 卡片标题为“科技 AI 新闻”，显示最多五条资讯，并覆盖加载、空、错误重试与离线状态。
- `main.dart` 与首页已接线；模块禁用时不请求，启用后恰好启动一次异步加载，且不会阻塞 `runApp`。
- 代码质量/规格审查完成；已补齐审查发现的卡片加载和错误重试测试。与综合新闻模块存在刻意的结构对齐，后续若两者继续演进，可考虑抽取共享的文章状态和展示逻辑。

## 关键文件

- `AGENTS.md`：项目约定和验证命令
- `docs/superpowers/plans/2026-07-07-morningbrief.md`：完整实现计划
- `lib/main.dart`：依赖注入与启动生命周期
- `lib/shared/screens/home_screen.dart`：模块路由
- `lib/modules/news/`：可复用 RSS 与新闻模块参考实现
- `lib/modules/stocks/`：最新完成模块的参考实现

## 工作流

1. 以 `codex/task9-tech-ai-news` 的 `e5fc4bb` 为基础继续 Task 10；在合并 Task 9 前不要从 `master` 开始 Task 10。
2. 在工作树运行 `flutter test` 与 `flutter analyze`，确认干净基线。
3. 先写失败测试，再实现最小代码；每个阶段运行相关测试。
4. 完成后运行完整测试、静态分析与 `git diff --check`，再进行规格与代码质量审查。

旧 `.worktrees/morningbrief-sdd/HANDOFF.md` 是 Task 8 开始前的临时文件，内容已被本文件取代，可随旧工作树一并删除。
