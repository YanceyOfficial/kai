# KaiCore Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 建立仓库骨架并实现 KaiCore 数据层 —— SwiftData 模型、枚举、值类型、仓储(去重 / 语言隔离 / 复习日志),全部带 Swift Testing 单测。

**Architecture:** KaiCore 是一个独立的本地 Swift Package(无 UI、无 iOS-only 依赖),因此可以用 `swift test` 在 macOS 命令行直接构建与测试,无需完整 Xcode。后续所有包与 app target 都消费 KaiCore 的模型与仓储。数据模型遵循 CloudKit 兼容约束(属性有默认值 / 可选、无 `@Attribute(.unique)`、代码层去重),以便未来无痛开启同步。

**Tech Stack:** Swift 6.3、Swift Package Manager、SwiftData、Swift Testing(`import Testing`,随工具链自带,无需第三方依赖)。

## Global Constraints

- Swift 工具链:Apple Swift 6.3.x(命令行已具备)。
- 平台下限:`.macOS(.v14)`、`.iOS(.v17)`(SwiftData 要求;KaiCore 声明两者,测试在 macOS 跑)。
- **完整 Xcode 仅后续 Plan(app/UI/扩展/模拟器)需要;本 Plan 只需命令行 Swift。** 若 `swift test` 在纯 Command Line Tools 下报 SwiftData 宏不可用,安装完整 Xcode 后即可解决(见 Task 4 备注)。
- 测试框架统一用 **Swift Testing**(`import Testing` / `@Test` / `#expect`),不用 XCTest。
- 数据模型 **CloudKit 兼容**:每个持久属性都有默认值或为可选;不使用 `@Attribute(.unique)`;去重在代码层做。
- 枚举可查询字段(language / kind / source / state / quizType)以 **raw String/Int** 持久化,并提供强类型计算访问器,保证 `#Predicate` 查询稳定。
- **所有代码注释用英文**;源码/公共声明写 `///` 英文文档注释,风格贴合 Apple SwiftUI/SwiftData 官方示例;测试函数以 `@Test("English description")` 标签自文档,无需额外 `///`。
- **App 内所有用户可见文案(UI 字符串、通知、日志信息)用英文。** 仅设计/计划文档与对话用中文。
- (注:本计划各 Task 代码块中出现的中文注释为历史示例,实现时一律改写为等义英文;Task 1–5 已写的中文注释在收尾前统一英文化。)
- 工作分支:`feature/native-english-mvp`。每个 Task 结束提交一次。

---

### Task 1: KaiCore 包脚手架 + 工具链冒烟测试

先建最小可测的 Swift Package,确认命令行工具链能编译并跑 Swift Testing。这是后续所有工作的地基,必须先绿。

**Files:**
- Create: `Packages/KaiCore/Package.swift`
- Create: `Packages/KaiCore/Sources/KaiCore/KaiCore.swift`
- Test: `Packages/KaiCore/Tests/KaiCoreTests/SmokeTests.swift`

**Interfaces:**
- Consumes: 无。
- Produces: `KaiCore` library product;`enum KaiCoreInfo { static let schemaVersion: Int }`。

- [ ] **Step 1: 写 Package.swift**

```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "KaiCore",
    platforms: [.macOS(.v14), .iOS(.v17)],
    products: [
        .library(name: "KaiCore", targets: ["KaiCore"])
    ],
    targets: [
        .target(name: "KaiCore"),
        .testTarget(name: "KaiCoreTests", dependencies: ["KaiCore"])
    ]
)
```

- [ ] **Step 2: 写最小源文件**

`Packages/KaiCore/Sources/KaiCore/KaiCore.swift`:

```swift
import Foundation

/// KaiCore 包的元信息。schemaVersion 用于未来 SwiftData 迁移标记。
public enum KaiCoreInfo {
    /// 当前数据 schema 版本号。
    public static let schemaVersion = 1
}
```

- [ ] **Step 3: 写冒烟测试**

`Packages/KaiCore/Tests/KaiCoreTests/SmokeTests.swift`:

```swift
import Testing
@testable import KaiCore

@Test("KaiCore schema 版本可读取")
func schemaVersionIsPositive() {
    #expect(KaiCoreInfo.schemaVersion >= 1)
}
```

- [ ] **Step 4: 跑测试确认通过**

Run: `swift test --package-path Packages/KaiCore`
Expected: 编译成功,`schemaVersionIsPositive` PASS。

- [ ] **Step 5: 提交**

```bash
git add Packages/KaiCore
git commit -m "feat(KaiCore): 包脚手架与工具链冒烟测试"
```

---

### Task 2: 枚举与题型适用性

领域枚举全部集中一处;`QuizType.isApplicable(to:)` 封装「短语不出音节类题」这条修复老版 bug 的规则。纯值逻辑,先写测试。

**Files:**
- Create: `Packages/KaiCore/Sources/KaiCore/Enums.swift`
- Test: `Packages/KaiCore/Tests/KaiCoreTests/EnumsTests.swift`

**Interfaces:**
- Consumes: 无。
- Produces:
  - `enum LanguageDomain: String, Codable, CaseIterable, Sendable { case english, japanese }`
  - `enum EntryKind: String, Codable, Sendable { case word, phrase }`
  - `enum EntrySource: String, Codable, Sendable { case manual, single, share, ocr, batch }`
  - `enum LearningState: String, Codable, Sendable { case new, learning, review, relearning }`
  - `enum ExampleSource: String, Codable, Sendable { case plain, literary }`
  - `enum ReviewRating: Int, Codable, CaseIterable, Sendable { case again = 1, hard = 2, good = 3, easy = 4 }`
  - `enum QuizType: String, Codable, CaseIterable, Sendable { case singleChoice, splitCombine, fillInBlank, listeningSpelling, meaningMatch, contextCloze }`
    - `func isApplicable(to kind: EntryKind) -> Bool`

- [ ] **Step 1: 写失败测试**

`EnumsTests.swift`:

```swift
import Testing
@testable import KaiCore

@Test("单词适用全部题型")
func wordAllowsAllQuizTypes() {
    for type in QuizType.allCases {
        #expect(type.isApplicable(to: .word))
    }
}

@Test("短语不出音节拼词与听音拼写")
func phraseExcludesSyllableQuizzes() {
    #expect(!QuizType.splitCombine.isApplicable(to: .phrase))
    #expect(!QuizType.listeningSpelling.isApplicable(to: .phrase))
    #expect(QuizType.singleChoice.isApplicable(to: .phrase))
    #expect(QuizType.meaningMatch.isApplicable(to: .phrase))
    #expect(QuizType.fillInBlank.isApplicable(to: .phrase))
    #expect(QuizType.contextCloze.isApplicable(to: .phrase))
}

@Test("评级 raw 值符合 FSRS 约定")
func ratingRawValues() {
    #expect(ReviewRating.again.rawValue == 1)
    #expect(ReviewRating.easy.rawValue == 4)
}
```

- [ ] **Step 2: 跑测试确认失败**

Run: `swift test --package-path Packages/KaiCore`
Expected: FAIL —— 找不到 `QuizType` 等类型(编译错误)。

- [ ] **Step 3: 写实现**

`Enums.swift`:

```swift
import Foundation

/// 学习语种。中/日双语隔离的核心字段,本期只用 english。
public enum LanguageDomain: String, Codable, CaseIterable, Sendable {
    case english
    case japanese
}

/// 词条类型。区分单词与短语,决定题型适用性(修复老版短语 bug)。
public enum EntryKind: String, Codable, Sendable {
    case word
    case phrase
}

/// 词条来源入口。
public enum EntrySource: String, Codable, Sendable {
    case manual   // 兜底/未知
    case single   // 单个快捷添加
    case share    // 系统分享扩展
    case ocr      // 剪贴板 / 拍照 OCR
    case batch    // 批量粘贴
}

/// FSRS 学习阶段。
public enum LearningState: String, Codable, Sendable {
    case new
    case learning
    case review
    case relearning
}

/// 例句来源风格。
public enum ExampleSource: String, Codable, Sendable {
    case plain     // 普通例句
    case literary  // 名著风短文/语段
}

/// 复习评级,raw 值对齐 FSRS 约定(1=again … 4=easy)。
public enum ReviewRating: Int, Codable, CaseIterable, Sendable {
    case again = 1
    case hard = 2
    case good = 3
    case easy = 4
}

/// 小测验题型。
public enum QuizType: String, Codable, CaseIterable, Sendable {
    case singleChoice       // 单选
    case splitCombine       // 音节碎片拼词(仅单词)
    case fillInBlank        // 例句填空
    case listeningSpelling  // 听音拼写(仅单词)
    case meaningMatch       // 释义匹配
    case contextCloze       // 上下文完形

    /// 该题型是否适用于给定词条类型。
    /// 音节拼词与听音拼写依赖音节切分,只对单词有意义,短语一律排除。
    public func isApplicable(to kind: EntryKind) -> Bool {
        switch self {
        case .splitCombine, .listeningSpelling:
            return kind == .word
        case .singleChoice, .fillInBlank, .meaningMatch, .contextCloze:
            return true
        }
    }
}
```

- [ ] **Step 4: 跑测试确认通过**

Run: `swift test --package-path Packages/KaiCore`
Expected: 全部 PASS。

- [ ] **Step 5: 提交**

```bash
git add Packages/KaiCore
git commit -m "feat(KaiCore): 领域枚举与题型适用性规则"
```

---

### Task 3: 值类型(Example 与 SchedulingState)

可嵌入 SwiftData 模型的 Codable 值类型。`SchedulingState.new` 给出新词的初始 FSRS 状态。

**Files:**
- Create: `Packages/KaiCore/Sources/KaiCore/Example.swift`
- Create: `Packages/KaiCore/Sources/KaiCore/SchedulingState.swift`
- Test: `Packages/KaiCore/Tests/KaiCoreTests/ValueTypesTests.swift`

**Interfaces:**
- Consumes: `LearningState`、`ExampleSource`(Task 2)。
- Produces:
  - `struct Example: Codable, Hashable, Sendable { var sentence: String; var translation: String; var source: ExampleSource }`
  - `struct SchedulingState: Codable, Hashable, Sendable { var stability: Double; var difficulty: Double; var due: Date; var lastReview: Date?; var reps: Int; var lapses: Int; var state: LearningState; static func new(now: Date = .now) -> SchedulingState }`

- [ ] **Step 1: 写失败测试**

`ValueTypesTests.swift`:

```swift
import Foundation
import Testing
@testable import KaiCore

@Test("新词 SchedulingState 初始为 new 且到期即刻")
func newSchedulingDefaults() {
    let now = Date(timeIntervalSince1970: 1_000_000)
    let s = SchedulingState.new(now: now)
    #expect(s.state == .new)
    #expect(s.reps == 0)
    #expect(s.lapses == 0)
    #expect(s.stability == 0)
    #expect(s.difficulty == 0)
    #expect(s.due == now)
    #expect(s.lastReview == nil)
}

@Test("Example 可 Codable 往返")
func exampleCodableRoundTrip() throws {
    let ex = Example(sentence: "He is eccentric.", translation: "他很古怪。", source: .plain)
    let data = try JSONEncoder().encode(ex)
    let decoded = try JSONDecoder().decode(Example.self, from: data)
    #expect(decoded == ex)
}
```

- [ ] **Step 2: 跑测试确认失败**

Run: `swift test --package-path Packages/KaiCore`
Expected: FAIL —— 找不到 `Example` / `SchedulingState`。

- [ ] **Step 3: 写实现**

`Example.swift`:

```swift
import Foundation

/// 一条例句:英文原句 + 中文翻译 + 来源风格。作为 Codable 值类型嵌入词条。
public struct Example: Codable, Hashable, Sendable {
    public var sentence: String
    public var translation: String
    public var source: ExampleSource

    public init(sentence: String, translation: String, source: ExampleSource = .plain) {
        self.sentence = sentence
        self.translation = translation
        self.source = source
    }
}
```

`SchedulingState.swift`:

```swift
import Foundation

/// 词条的 FSRS 调度状态。作为 Codable 值类型嵌入词条。
/// stability/difficulty 的具体演化由 KaiFSRS 包负责(后续 Plan)。
public struct SchedulingState: Codable, Hashable, Sendable {
    /// 记忆稳定度 S(天)。新词为 0。
    public var stability: Double
    /// 记忆难度 D(FSRS 内部量,约 1...10)。新词为 0(待首次评级初始化)。
    public var difficulty: Double
    /// 下次到期时间。
    public var due: Date
    /// 上次复习时间。
    public var lastReview: Date?
    /// 累计复习次数。
    public var reps: Int
    /// 累计遗忘(lapse)次数。
    public var lapses: Int
    /// 学习阶段。
    public var state: LearningState

    public init(
        stability: Double,
        difficulty: Double,
        due: Date,
        lastReview: Date?,
        reps: Int,
        lapses: Int,
        state: LearningState
    ) {
        self.stability = stability
        self.difficulty = difficulty
        self.due = due
        self.lastReview = lastReview
        self.reps = reps
        self.lapses = lapses
        self.state = state
    }

    /// 新词的初始状态:立即到期(可马上学),尚无稳定度/难度。
    public static func new(now: Date = .now) -> SchedulingState {
        SchedulingState(
            stability: 0,
            difficulty: 0,
            due: now,
            lastReview: nil,
            reps: 0,
            lapses: 0,
            state: .new
        )
    }
}
```

- [ ] **Step 4: 跑测试确认通过**

Run: `swift test --package-path Packages/KaiCore`
Expected: 全部 PASS。

- [ ] **Step 5: 提交**

```bash
git add Packages/KaiCore
git commit -m "feat(KaiCore): Example 与 SchedulingState 值类型"
```

---

### Task 4: SwiftData 模型与内存容器

定义 `VocabularyEntry` / `ReviewLog` 两个 `@Model`,并提供内存容器工厂,验证持久化往返。

> **备注(Xcode 依赖)**:本 Task 首次引入 SwiftData `@Model` 宏。若在纯 Command Line Tools 下 `swift test` 报 "SwiftData macro not found / external macro implementation" 之类错误,说明该宏需要完整 Xcode 的工具链插件 —— 安装 Xcode 后执行 `sudo xcode-select -s /Applications/Xcode.app` 再重跑即可。Task 1–3 不受影响。

**Files:**
- Create: `Packages/KaiCore/Sources/KaiCore/VocabularyEntry.swift`
- Create: `Packages/KaiCore/Sources/KaiCore/ReviewLog.swift`
- Create: `Packages/KaiCore/Sources/KaiCore/KaiModelContainer.swift`
- Test: `Packages/KaiCore/Tests/KaiCoreTests/ModelPersistenceTests.swift`

**Interfaces:**
- Consumes: 所有枚举、`Example`、`SchedulingState`。
- Produces:
  - `@Model final class VocabularyEntry`,含 `lemmaKey`(小写归一化,供去重查询)与 `kind/language/source` 强类型计算访问器;`init(lemma:kind:language:...)`。
  - `@Model final class ReviewLog`,含 `rating/quizType` 计算访问器;`init(entryID:rating:quizType:elapsedMs:isCorrect:timestamp:)`。
  - `enum KaiModelContainer { static func inMemory() throws -> ModelContainer; static func onDisk() throws -> ModelContainer }`
  - `let kaiSchemaModels: [any PersistentModel.Type]`(= `[VocabularyEntry.self, ReviewLog.self]`)。

- [ ] **Step 1: 写失败测试**

`ModelPersistenceTests.swift`:

```swift
import Foundation
import SwiftData
import Testing
@testable import KaiCore

@MainActor
@Test("词条可持久化并读回,枚举访问器一致")
func entryPersistsAndReadsBack() throws {
    let container = try KaiModelContainer.inMemory()
    let ctx = container.mainContext

    let entry = VocabularyEntry(
        lemma: "Eccentric",
        kind: .word,
        language: .english,
        explanation: "adj. 古怪的",
        examples: [Example(sentence: "He is eccentric.", translation: "他很古怪。")]
    )
    ctx.insert(entry)
    try ctx.save()

    let fetched = try ctx.fetch(FetchDescriptor<VocabularyEntry>())
    #expect(fetched.count == 1)
    #expect(fetched.first?.lemma == "Eccentric")
    #expect(fetched.first?.lemmaKey == "eccentric")
    #expect(fetched.first?.kind == .word)
    #expect(fetched.first?.language == .english)
    #expect(fetched.first?.scheduling.state == .new)
    #expect(fetched.first?.examples.count == 1)
}

@MainActor
@Test("复习日志可持久化")
func reviewLogPersists() throws {
    let container = try KaiModelContainer.inMemory()
    let ctx = container.mainContext
    let log = ReviewLog(entryID: UUID(), rating: .good, quizType: .singleChoice, elapsedMs: 1200, isCorrect: true)
    ctx.insert(log)
    try ctx.save()

    let fetched = try ctx.fetch(FetchDescriptor<ReviewLog>())
    #expect(fetched.count == 1)
    #expect(fetched.first?.rating == .good)
    #expect(fetched.first?.quizType == .singleChoice)
    #expect(fetched.first?.isCorrect == true)
}
```

- [ ] **Step 2: 跑测试确认失败**

Run: `swift test --package-path Packages/KaiCore`
Expected: FAIL —— 找不到 `VocabularyEntry` / `ReviewLog` / `KaiModelContainer`。

- [ ] **Step 3: 写实现**

`VocabularyEntry.swift`:

```swift
import Foundation
import SwiftData

/// 一个词条(单词或短语)及其 AI 生成内容与 FSRS 调度状态。
/// CloudKit 兼容:所有持久属性有默认值或可选;去重在仓储层做,不用 .unique。
@Model
public final class VocabularyEntry {
    /// 稳定主键。
    public var id: UUID = UUID()
    /// 原文(保留大小写用于展示)。
    public var lemma: String = ""
    /// 归一化小写键,供去重查询(避免在 #Predicate 里做大小写转换)。
    public var lemmaKey: String = ""

    /// kind/language/source 以 raw 持久化,保证谓词查询稳定。
    public var kindRaw: String = EntryKind.word.rawValue
    public var languageRaw: String = LanguageDomain.english.rawValue
    public var sourceRaw: String = EntrySource.manual.rawValue

    public var phonetic: String = ""
    public var syllables: [String] = []
    public var explanation: String = ""
    public var partsOfSpeech: [String] = []
    public var examples: [Example] = []
    public var story: String?
    public var mnemonic: String?
    public var etymology: String?
    public var synonyms: [String] = []
    public var confusables: [String] = []
    public var tags: [String] = []
    public var isMarked: Bool = false
    public var createdAt: Date = Date()
    public var updatedAt: Date = Date()

    /// 内嵌的 FSRS 调度状态。
    public var scheduling: SchedulingState = SchedulingState.new()

    // MARK: 强类型访问器

    public var kind: EntryKind {
        get { EntryKind(rawValue: kindRaw) ?? .word }
        set { kindRaw = newValue.rawValue }
    }
    public var language: LanguageDomain {
        get { LanguageDomain(rawValue: languageRaw) ?? .english }
        set { languageRaw = newValue.rawValue }
    }
    public var source: EntrySource {
        get { EntrySource(rawValue: sourceRaw) ?? .manual }
        set { sourceRaw = newValue.rawValue }
    }

    public init(
        lemma: String,
        kind: EntryKind,
        language: LanguageDomain,
        phonetic: String = "",
        syllables: [String] = [],
        explanation: String = "",
        partsOfSpeech: [String] = [],
        examples: [Example] = [],
        story: String? = nil,
        mnemonic: String? = nil,
        etymology: String? = nil,
        synonyms: [String] = [],
        confusables: [String] = [],
        tags: [String] = [],
        source: EntrySource = .manual,
        isMarked: Bool = false,
        now: Date = .now
    ) {
        self.id = UUID()
        self.lemma = lemma
        self.lemmaKey = lemma.lowercased()
        self.kindRaw = kind.rawValue
        self.languageRaw = language.rawValue
        self.sourceRaw = source.rawValue
        self.phonetic = phonetic
        self.syllables = syllables
        self.explanation = explanation
        self.partsOfSpeech = partsOfSpeech
        self.examples = examples
        self.story = story
        self.mnemonic = mnemonic
        self.etymology = etymology
        self.synonyms = synonyms
        self.confusables = confusables
        self.tags = tags
        self.isMarked = isMarked
        self.createdAt = now
        self.updatedAt = now
        self.scheduling = SchedulingState.new(now: now)
    }
}
```

`ReviewLog.swift`:

```swift
import Foundation
import SwiftData

/// 一次作答记录。既用于 FSRS 参数优化,也用于统计看板。
@Model
public final class ReviewLog {
    public var id: UUID = UUID()
    /// 关联词条的 id(弱引用,避免 CloudKit 关系约束)。
    public var entryID: UUID = UUID()
    public var timestamp: Date = Date()
    public var ratingRaw: Int = ReviewRating.good.rawValue
    public var quizTypeRaw: String = QuizType.singleChoice.rawValue
    public var elapsedMs: Int = 0
    public var isCorrect: Bool = true

    public var rating: ReviewRating {
        get { ReviewRating(rawValue: ratingRaw) ?? .good }
        set { ratingRaw = newValue.rawValue }
    }
    public var quizType: QuizType {
        get { QuizType(rawValue: quizTypeRaw) ?? .singleChoice }
        set { quizTypeRaw = newValue.rawValue }
    }

    public init(
        entryID: UUID,
        rating: ReviewRating,
        quizType: QuizType,
        elapsedMs: Int,
        isCorrect: Bool,
        timestamp: Date = .now
    ) {
        self.id = UUID()
        self.entryID = entryID
        self.ratingRaw = rating.rawValue
        self.quizTypeRaw = quizType.rawValue
        self.elapsedMs = elapsedMs
        self.isCorrect = isCorrect
        self.timestamp = timestamp
    }
}
```

`KaiModelContainer.swift`:

```swift
import Foundation
import SwiftData

/// 组成 Kai schema 的全部持久模型。新增模型时在此登记。
public let kaiSchemaModels: [any PersistentModel.Type] = [
    VocabularyEntry.self,
    ReviewLog.self
]

/// SwiftData 容器工厂。
public enum KaiModelContainer {
    /// 内存容器,供测试使用(不落盘)。
    public static func inMemory() throws -> ModelContainer {
        let schema = Schema(kaiSchemaModels)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [config])
    }

    /// 落盘容器,供 App 使用(本期不开 CloudKit 同步)。
    public static func onDisk() throws -> ModelContainer {
        let schema = Schema(kaiSchemaModels)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        return try ModelContainer(for: schema, configurations: [config])
    }
}
```

- [ ] **Step 4: 跑测试确认通过**

Run: `swift test --package-path Packages/KaiCore`
Expected: 两个持久化测试 PASS。(若报 SwiftData 宏缺失,见本 Task 顶部备注安装 Xcode。)

- [ ] **Step 5: 提交**

```bash
git add Packages/KaiCore
git commit -m "feat(KaiCore): SwiftData 模型与内存容器"
```

---

### Task 5: 仓储 —— 去重插入与语言隔离

`VocabularyRepository` 封装写入去重(同语言同 lemma 只留一条)与按语言隔离查询。这是修「跨语言污染」与「重复录入」的核心。

**Files:**
- Create: `Packages/KaiCore/Sources/KaiCore/VocabularyRepository.swift`
- Test: `Packages/KaiCore/Tests/KaiCoreTests/VocabularyRepositoryTests.swift`

**Interfaces:**
- Consumes: `VocabularyEntry`、`LanguageDomain`、`ModelContext`。
- Produces:
  - `protocol VocabularyRepositoryProtocol`
  - `final class VocabularyRepository: VocabularyRepositoryProtocol`
    - `init(context: ModelContext)`
    - `@discardableResult func insertIfAbsent(_ entry: VocabularyEntry) throws -> Bool`(新插入返回 true,已存在返回 false)
    - `func entry(lemma: String, language: LanguageDomain) throws -> VocabularyEntry?`
    - `func entries(for language: LanguageDomain) throws -> [VocabularyEntry]`
    - `func delete(_ entry: VocabularyEntry) throws`

- [ ] **Step 1: 写失败测试**

`VocabularyRepositoryTests.swift`:

```swift
import Foundation
import SwiftData
import Testing
@testable import KaiCore

@MainActor
private func makeRepo() throws -> (VocabularyRepository, ModelContext) {
    let container = try KaiModelContainer.inMemory()
    let ctx = container.mainContext
    return (VocabularyRepository(context: ctx), ctx)
}

@MainActor
@Test("同语言同 lemma 去重(大小写不敏感)")
func dedupeSameLanguageCaseInsensitive() throws {
    let (repo, _) = try makeRepo()
    let first = try repo.insertIfAbsent(VocabularyEntry(lemma: "Eccentric", kind: .word, language: .english))
    let second = try repo.insertIfAbsent(VocabularyEntry(lemma: "eccentric", kind: .word, language: .english))
    #expect(first == true)
    #expect(second == false)
    #expect(try repo.entries(for: .english).count == 1)
}

@MainActor
@Test("不同语言相同 lemma 允许共存")
func sameLemmaDifferentLanguageAllowed() throws {
    let (repo, _) = try makeRepo()
    _ = try repo.insertIfAbsent(VocabularyEntry(lemma: "kanji", kind: .word, language: .english))
    let jp = try repo.insertIfAbsent(VocabularyEntry(lemma: "kanji", kind: .word, language: .japanese))
    #expect(jp == true)
    #expect(try repo.entries(for: .english).count == 1)
    #expect(try repo.entries(for: .japanese).count == 1)
}

@MainActor
@Test("按语言隔离查询")
func entriesFilteredByLanguage() throws {
    let (repo, _) = try makeRepo()
    _ = try repo.insertIfAbsent(VocabularyEntry(lemma: "apple", kind: .word, language: .english))
    _ = try repo.insertIfAbsent(VocabularyEntry(lemma: "banana", kind: .word, language: .english))
    #expect(try repo.entries(for: .japanese).isEmpty)
    #expect(try repo.entries(for: .english).count == 2)
    #expect(try repo.entry(lemma: "APPLE", language: .english)?.lemma == "apple")
}
```

- [ ] **Step 2: 跑测试确认失败**

Run: `swift test --package-path Packages/KaiCore`
Expected: FAIL —— 找不到 `VocabularyRepository`。

- [ ] **Step 3: 写实现**

`VocabularyRepository.swift`:

```swift
import Foundation
import SwiftData

/// 词条仓储协议。UI/服务层依赖协议而非具体实现,便于替换与测试。
public protocol VocabularyRepositoryProtocol {
    @discardableResult
    func insertIfAbsent(_ entry: VocabularyEntry) throws -> Bool
    func entry(lemma: String, language: LanguageDomain) throws -> VocabularyEntry?
    func entries(for language: LanguageDomain) throws -> [VocabularyEntry]
    func delete(_ entry: VocabularyEntry) throws
}

/// 基于 SwiftData 的词条仓储实现。
public final class VocabularyRepository: VocabularyRepositoryProtocol {
    private let context: ModelContext

    public init(context: ModelContext) {
        self.context = context
    }

    /// 若同语言下不存在相同 lemma(大小写不敏感)则插入并返回 true,否则返回 false。
    @discardableResult
    public func insertIfAbsent(_ entry: VocabularyEntry) throws -> Bool {
        if try entry(lemma: entry.lemma, language: entry.language) != nil {
            return false
        }
        context.insert(entry)
        try context.save()
        return true
    }

    /// 按归一化 lemma + 语言精确查一条。
    public func entry(lemma: String, language: LanguageDomain) throws -> VocabularyEntry? {
        let key = lemma.lowercased()
        let lang = language.rawValue
        var descriptor = FetchDescriptor<VocabularyEntry>(
            predicate: #Predicate { $0.lemmaKey == key && $0.languageRaw == lang }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    /// 按语言隔离取全部词条,按创建时间升序。
    public func entries(for language: LanguageDomain) throws -> [VocabularyEntry] {
        let lang = language.rawValue
        let descriptor = FetchDescriptor<VocabularyEntry>(
            predicate: #Predicate { $0.languageRaw == lang },
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )
        return try context.fetch(descriptor)
    }

    public func delete(_ entry: VocabularyEntry) throws {
        context.delete(entry)
        try context.save()
    }
}
```

> 注意:`entry(lemma:language:)` 与协议方法同名但参数不同,Swift 以标签区分,不冲突。实现内部调用 `try entry(lemma:language:)` 指向本方法。

- [ ] **Step 4: 跑测试确认通过**

Run: `swift test --package-path Packages/KaiCore`
Expected: 三个仓储测试 PASS。

- [ ] **Step 5: 提交**

```bash
git add Packages/KaiCore
git commit -m "feat(KaiCore): 词条仓储(去重+语言隔离)"
```

---

### Task 6: 复习日志写入与到期查询

在仓储上补充 `ReviewLog` 写入与「今日到期词条」查询(为 FSRS/复习闭环铺路)。到期规则:`scheduling.due <= now`。

**Files:**
- Modify: `Packages/KaiCore/Sources/KaiCore/VocabularyRepository.swift`
- Test: `Packages/KaiCore/Tests/KaiCoreTests/DueAndLogTests.swift`

**Interfaces:**
- Consumes: `VocabularyRepository`、`ReviewLog`、`SchedulingState`。
- Produces(新增到协议与实现):
  - `func logReview(_ log: ReviewLog) throws`
  - `func dueEntries(for language: LanguageDomain, asOf now: Date) throws -> [VocabularyEntry]`
  - `func reviewLogs(entryID: UUID) throws -> [ReviewLog]`

- [ ] **Step 1: 写失败测试**

`DueAndLogTests.swift`:

```swift
import Foundation
import SwiftData
import Testing
@testable import KaiCore

@MainActor
@Test("到期词条:due <= now 命中,未来到期不命中,按语言隔离")
func dueEntriesFiltering() throws {
    let container = try KaiModelContainer.inMemory()
    let ctx = container.mainContext
    let repo = VocabularyRepository(context: ctx)
    let now = Date(timeIntervalSince1970: 2_000_000)

    let dueWord = VocabularyEntry(lemma: "due", kind: .word, language: .english)
    dueWord.scheduling.due = now.addingTimeInterval(-60)   // 已到期
    let futureWord = VocabularyEntry(lemma: "future", kind: .word, language: .english)
    futureWord.scheduling.due = now.addingTimeInterval(3600) // 未来
    let jpWord = VocabularyEntry(lemma: "kana", kind: .word, language: .japanese)
    jpWord.scheduling.due = now.addingTimeInterval(-60)

    _ = try repo.insertIfAbsent(dueWord)
    _ = try repo.insertIfAbsent(futureWord)
    _ = try repo.insertIfAbsent(jpWord)

    let due = try repo.dueEntries(for: .english, asOf: now)
    #expect(due.map(\.lemma) == ["due"])
}

@MainActor
@Test("复习日志写入并按词条读回")
func logAndFetchReviewLogs() throws {
    let container = try KaiModelContainer.inMemory()
    let ctx = container.mainContext
    let repo = VocabularyRepository(context: ctx)
    let entryID = UUID()

    try repo.logReview(ReviewLog(entryID: entryID, rating: .again, quizType: .fillInBlank, elapsedMs: 800, isCorrect: false))
    try repo.logReview(ReviewLog(entryID: entryID, rating: .good, quizType: .singleChoice, elapsedMs: 1500, isCorrect: true))
    try repo.logReview(ReviewLog(entryID: UUID(), rating: .easy, quizType: .singleChoice, elapsedMs: 500, isCorrect: true))

    let logs = try repo.reviewLogs(entryID: entryID)
    #expect(logs.count == 2)
}
```

- [ ] **Step 2: 跑测试确认失败**

Run: `swift test --package-path Packages/KaiCore`
Expected: FAIL —— `logReview` / `dueEntries` / `reviewLogs` 未定义。

- [ ] **Step 3: 写实现(在 VocabularyRepository 中追加)**

先在 `VocabularyRepositoryProtocol` 追加三个方法声明:

```swift
    func logReview(_ log: ReviewLog) throws
    func dueEntries(for language: LanguageDomain, asOf now: Date) throws -> [VocabularyEntry]
    func reviewLogs(entryID: UUID) throws -> [ReviewLog]
```

再在 `VocabularyRepository` 类内追加实现:

```swift
    /// 写入一条复习日志。
    public func logReview(_ log: ReviewLog) throws {
        context.insert(log)
        try context.save()
    }

    /// 取指定语言下、到期时间不晚于 now 的词条,按到期时间升序。
    public func dueEntries(for language: LanguageDomain, asOf now: Date) throws -> [VocabularyEntry] {
        let lang = language.rawValue
        let descriptor = FetchDescriptor<VocabularyEntry>(
            predicate: #Predicate { $0.languageRaw == lang && $0.scheduling.due <= now },
            sortBy: [SortDescriptor(\.scheduling.due, order: .forward)]
        )
        return try context.fetch(descriptor)
    }

    /// 取某词条的全部复习日志,按时间升序。
    public func reviewLogs(entryID: UUID) throws -> [ReviewLog] {
        let descriptor = FetchDescriptor<ReviewLog>(
            predicate: #Predicate { $0.entryID == entryID },
            sortBy: [SortDescriptor(\.timestamp, order: .forward)]
        )
        return try context.fetch(descriptor)
    }
```

> 若 `#Predicate` 不支持对内嵌 `scheduling.due` 的比较(SwiftData 对嵌入 Codable 结构的谓词可能受限),回退方案:把 `due: Date` 提升为 `VocabularyEntry` 的顶层持久属性 `dueAt`,由 `scheduling.due` 的 didSet 同步,谓词改用 `$0.dueAt <= now`。实现回退时同步更新 Task 4 的模型定义与本 Task 的谓词。

- [ ] **Step 4: 跑测试确认通过**

Run: `swift test --package-path Packages/KaiCore`
Expected: 两个测试 PASS,且既有测试全绿。

- [ ] **Step 5: 提交**

```bash
git add Packages/KaiCore
git commit -m "feat(KaiCore): 复习日志写入与到期查询"
```

---

## Self-Review

**Spec 覆盖**(对照 `2026-07-01-kai-native-english-mvp-design.md` 第 4 节数据模型):
- LanguageDomain / EntryKind / EntrySource / QuizType / ReviewRating / LearningState / ExampleSource → Task 2 ✅
- Example / SchedulingState → Task 3 ✅
- VocabularyEntry(含全部字段)/ ReviewLog → Task 4 ✅
- 题型按 kind 过滤(修短语 bug)→ Task 2 `isApplicable` ✅
- CloudKit 兼容建模(默认值 / 无 unique / 代码层去重)→ Task 4 + Task 5 ✅
- 语言隔离 → Task 5 ✅
- 复习日志 / 到期查询(喂 FSRS 与统计)→ Task 6 ✅
- 本 Plan **不含**:FSRS 算法本体(Plan 2 KaiFSRS)、AI、UI、录入入口、容器的 App 装配 —— 均属后续 Plan,符合分层分期。

**占位符扫描**:无 TBD/TODO;每个代码步骤含完整可编译代码。Task 6 的「回退方案」是明确的条件性工程指令,非占位。

**类型一致性**:`insertIfAbsent`/`entry(lemma:language:)`/`entries(for:)`/`dueEntries(for:asOf:)`/`logReview`/`reviewLogs(entryID:)` 在协议与实现、测试调用处签名一致;枚举 raw 类型(String/Int)与访问器一致;`SchedulingState.new(now:)` 全程一致。

**风险**:SwiftData `@Model` 宏在纯 Command Line Tools 下可能不可用(Task 4 备注);内嵌结构谓词可能受限(Task 6 回退方案)。两者都有明确应对。
