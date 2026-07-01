# Kai(甲斐)原生版 —— 第一期设计文档

- **日期**:2026-07-01
- **状态**:已确认(brainstorming 阶段产出)
- **范围**:第一期 MVP —— 纯本地英语学习闭环(iPhone)
- **前身**:RN 版 `~/Code/_kai/kai` + NestJS/CMS monorepo `~/Code/_kai/kai-monorepo`

---

## 1. 背景与目标

多年前基于 React Native(Expo)+ 独立 NestJS 后端 + CMS 三件套实现的背单词 App「Kai」,以 Flash Card 形式攻克疑难单词。本次用**苹果原生技术栈重做**,同时作为 iOS 学习过程。核心诉求:

- 用 SwiftUI + Swift Charts 做界面与统计。
- **去掉独立后端与 CMS**,全部内聚到 App:数据用 SwiftData(本地,CloudKit 兼容以便后续同步)。
- 集成 AI:用户在设置里填 Claude / OpenAI 的 Key 即可使用。
- 让 AI 效能最大化(丰富的释义、题型、统计、遗忘推送、每日故事等),把「硬背」变「高效理解」。
- 架构预留中/日双语隔离与多平台(Watch/Mac/TV),但**第一期只做 iPhone + 英语**。
- 多邻国式的好看动画;完善的错误/重试/Toast/日志;测试与注释齐全;遵循 iOS 最佳实践。

### 从老 Kai 继承的领域知识

- 数据模型:`name / phoneticNotation / syllabification[] / explanation(中文) / examples[](英中对照) / quizzes / factor / isMarked / isLearned / sequenceNumber`。
- 记忆机制:朴素的 `factor`(默认 3,答对 −1,答错 +1,`>3` 进「Challenging 疑难词」)。**新版升级为 FSRS。**
- 题型:`SingleChoice`、`SplitCombine`(音节碎片拼词)、`FillInBlank`(老版未完成)。
- AI:OpenAI `gpt-4o` + `ai-sdk` 的 `generateObject`,批量输入单词 → 结构化 word card。
- **已知 bug**:录入的是短语(而非单词)时,音节拼词 / 填空会异常 —— 新版在数据层区分 `word` / `phrase` 并按适用性过滤题型来修复。

---

## 2. 第一期范围

### 做(In scope)

纯本地英语闭环:SwiftData 本地存储、AI 生成词卡、翻转卡 + 多种题型、FSRS 复习调度、四入口录入(批量/单个/系统分享/剪贴板+OCR)、每日故事、艾宾浩斯(FSRS)遗忘推送、Swift Charts 统计看板、AI 增强(助记/词源/联想、AI 辅导/自适应)、多邻国式动画、错误/重试/Toast/日志、测试。

### 不做(Backlog,但架构预留)

- iCloud / CloudKit 跨设备同步(数据模型保持 CloudKit 兼容,但本期不开启同步)。
- 日语学习管线(`LanguageDomain` 字段现在就建好,但无日语 UI/生成流程)。
- 多平台 target(Apple Watch / Mac / Apple TV)。
- 账号 / 登录(全本地,无需)。

---

## 3. 工程结构(本地 SPM 包)

`Kai.xcworkspace` 下按分层拆成多个本地 Swift Package,核心逻辑与 UI 解耦,便于测试与后续多平台复用内核。

| 包 | 职责 | 依赖 |
|---|---|---|
| **KaiCore** | SwiftData 模型、仓储(Repository)、值类型、枚举。纯数据,无 UI。 | — |
| **KaiFSRS** | 纯 Swift 的 FSRS 调度算法。无依赖,纯函数、易测。 | — |
| **KaiAI** | `LLMProvider` 协议 + Claude / OpenAI 实现、prompt 构造、结构化输出解码、重试。 | KaiCore |
| **KaiServices** | Keychain、本地通知、TTS/发音、Vision OCR、日志、Toast。 | KaiCore |
| **KaiUI** | 可复用 SwiftUI 组件与动画(翻转卡、题型控件、图表)。 | KaiCore |
| **Kai**(app target) | 组装、导航、各功能页面。 | 全部 |
| **KaiShareExtension** | 系统分享入库,通过 **App Group** 与主 App 共用 SwiftData 存储。 | KaiCore, KaiAI |

**模式**:现代 SwiftUI 的 **MV + `@Observable`**(不套重 MVVM);`@Model` + `@Query`;依赖用 SwiftUI Environment 注入。每个包职责单一、接口清晰、可独立理解与测试。

---

## 4. 数据模型(SwiftData,CloudKit 兼容)

> CloudKit 兼容要求:所有属性有默认值或可选、无 `@Attribute(.unique)` 硬约束(用代码层去重)、关系可选。本期不开同步,但按此约束建模以便未来无痛开启。

- **`LanguageDomain`** 枚举:`.english` / `.japanese`。所有 entry 带此字段,查询按当前语言隔离。本期只用 `.english`。
- **`VocabularyEntry`**(`@Model`):
  - `id`、`lemma`(词或短语)、`kind`(`.word` / `.phrase`)、`language`
  - `phonetic`、`syllables: [String]`、`explanation`(中文释义)、`partsOfSpeech`
  - `examples: [Example]`、`story: String?`、`mnemonic: String?`、`etymology: String?`
  - `synonyms: [String]`、`confusables: [String]`、`tags: [String]`
  - `source`(`.manual` / `.single` / `.share` / `.ocr` / `.batch`)、`isMarked`(收藏)
  - `createdAt` / `updatedAt`
  - `scheduling: SchedulingState`(内嵌 FSRS 状态)
- **`SchedulingState`**(FSRS 状态,内嵌值类型或 `@Model`):`stability`、`difficulty`、`due`、`lastReview`、`reps`、`lapses`、`state`(`.new`/`.learning`/`.review`/`.relearning`)。`retrievability(now:)` 为计算值。
- **`ReviewLog`**(`@Model`):`entryId`、`timestamp`、`rating`(`.again`/`.hard`/`.good`/`.easy`)、`quizType`、`elapsedMs`、`isCorrect`。既喂 FSRS 参数优化,也喂统计看板。
- **`Example`**:`sentence`、`translation`、`source`(`.plain` / `.literary` 名著风)。
- **`QuizType`** 枚举:`singleChoice`、`splitCombine`、`fillInBlank`、`listeningSpelling`、`meaningMatch`、`contextCloze`。**运行时按 `kind` 过滤**:短语不出 `splitCombine` / `listeningSpelling`。

---

## 5. FSRS 调度(KaiFSRS)

现代间隔重复算法(Anki 现内置),本质是艾宾浩斯遗忘曲线的计算模型,基于「此刻可回忆概率 retrievability」建模。

- **API**:
  - `schedule(card:, rating:, now:) -> SchedulingState`
  - `retrievability(card:, now:) -> Double`
  - `dueEntries(in:, now:) -> [VocabularyEntry]`
- **通知触发点**:某词 `retrievability < 阈值`(默认 `0.9`,可调)→ 触发复习提醒。
- **参数**:FSRS 的 17+ 权重做成可配置常量,后续可用累积的 `ReviewLog` 微调。
- **测试**:数学密集,采用 **TDD**,重点覆盖 —— 已知输入/评级/间隔 → 预期稳定度/难度/到期日;与参考实现对拍。

---

## 6. AI 层(KaiAI)

- **协议**:
  ```
  protocol LLMProvider {
      func generateCards(for lemmas: [String], language: LanguageDomain) async throws -> [GeneratedCard]
      func generateStory(words: [String], language: LanguageDomain) async throws -> String
      func generateQuiz(for entry: VocabularyEntry, type: QuizType) async throws -> GeneratedQuiz
      func explainMistake(entry: VocabularyEntry, userAnswer: String) async throws -> String
  }
  ```
- **实现**:`ClaudeProvider`(Anthropic Messages API,JSON schema / tool-use 结构化输出)、`OpenAIProvider`(JSON schema 结构化输出)。
- **结构化输出**:JSON schema → `Codable` 解码;带超时、指数退避重试、可取消(`Task` cancellation)。
- **Prompt**:内建 **word / phrase 分支**(短语跳过音节类题型);例句支持 `.plain` 与 `.literary`(名著风短文/语段)。
- **配置**:API Key 存 **Keychain**(系统级加密,优于明文 `UserDefaults`);provider + 型号在设置页切换,默认最新 Claude。故事/辅导可选流式输出。

---

## 7. 录入体验(统一 `EntryIngestionService`)

四入口共用同一条管线:**解析 → 去重(`lemma`+`language`)→ 语言路由 → AI 生成 → 预览 → 落库**。失败项单独标记可重试,不阻塞整批。

1. **批量粘贴**:换行/逗号分隔的一批词 → AI 批量生成 → 预览列表(可删改)→ 确认入库。
2. **单个快捷添加**:醒目 `+`(后续可挂快捷指令/键盘入口)→ 单词 → 实时生成 → 预览 → 存。
3. **系统分享 Extension**:任意 App 选中单词 → 分享给 Kai → 写入 App Group 共享库。
4. **剪贴板 / 拍照 OCR**:打开 App 时剪贴板是单词则提示加入;拍照/截图用 **Vision** OCR 识别选词入库。

---

## 8. 学习 / 复习闭环

- **Home**:今日到期(FSRS)、新词、疑难词;多邻国式卡片/路径布局。
- **翻转卡**:单词 ↔ 释义,3D flip 动画 + 触感反馈,发音按钮(TTS / 词典音频)。
- **Quiz Session**:混合当前词**适用**的题型;结果映射 FSRS 评级(答对+速度 → good/easy,答错 → again;或显式 Again/Hard/Good/Easy)。答错抖动动画。
- **每日故事**:AI 用「今日全部复习词」编一段短文串起来,点词可回卡。
- **AI 辅导**:答错后点「为什么错」→ AI 讲解 + 易混词对比;按错误模式自适应出题。

---

## 9. 统计看板(Swift Charts)

Streak 连续天数 · GitHub 式复习热力图 · 掌握度分布(new/learning/review/掌握)· 保持率曲线(平均 retrievability over time)· 词汇量增长 · **预测毕业日期**(FSRS 外推)· 最难/易混词 TOP · 各题型正确率 · 一天中表现时段 · **AI 周报**(LLM 把数据总结成人话 + 建议)。

---

## 10. 通知(纯本地,无服务端)

依 FSRS 到期时间排本地通知;每日复习提醒;**免打扰时段**;「N 个词即将遗忘」。用 Background App Refresh 定期重排到期通知。

---

## 11. 设计语言 / 动画

多邻国风:圆润、鲜明配色、弹簧动画、触感、streak 撒花、吉祥物(甲斐/Kai)。翻转/滑动/答错抖动/进度填充,优先纯 SwiftUI + Canvas(必要时 Lottie)。深浅色适配。

---

## 12. 错误 / 重试 / Toast / 日志

- 统一 `KaiError` 类型化错误;AI/网络带重试策略(指数退避、超时、可取消)。
- KaiUI 全局 **Toast** 覆盖层反馈。
- `os.Logger` 结构化日志 + 可导出文件日志(便于排查)。本期不接 Sentry(隐私 + 本地优先),留可插拔位。

---

## 13. 测试策略

用 **Swift Testing** 框架:

- **KaiFSRS**:数学,TDD 重覆盖(与参考实现对拍)。
- **KaiCore**:仓储 CRUD、去重、语言隔离。
- **KaiAI**:结构化输出解码、prompt 构造、重试(mock provider,不打真实网络)。
- **EntryIngestionService**:四入口去重与失败重试。
- **UI**:关键流(翻转卡、Quiz、录入预览)轻量交互测试。

---

## 14. 多平台预留

核心逻辑(KaiCore / KaiFSRS / KaiAI / KaiServices)平台无关;KaiUI 大部分可复用。后续加 Watch(快速复习)、Mac(原生或 Catalyst)、TV target,只需新增薄 UI 层复用内核。

---

## 15. 未决 / 后续在实现计划中细化

- FSRS 具体版本(v4 / v5)与默认权重取值。
- Claude / OpenAI 结构化输出的具体机制(tool-use vs JSON schema)与目标型号。
- 吉祥物美术资源(可先用占位)。
- Duolingo 式动画是否引入 Lottie 或纯 SwiftUI 实现。
