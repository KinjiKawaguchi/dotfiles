---
name: self-review-loop
description: |
  変更内容をセルフコードレビューし、指摘に基づいて修正、再レビューを指摘が0件になるまで繰り返す。
  コードスメル検出（Fowlerのリファクタリングカタログ準拠）を軸に、差分だけでなく周辺コードも俯瞰して改善提案を行う。
  明確な問題は自動修正し、トレードオフがある指摘はユーザーに相談してから進める。
  「セルフレビューして」「コードレビューして直して」「レビューループ回して」「品質チェックして修正まで」
  「コードスメルを検出して直して」「リファクタリングして」「レビューして直して」
  「変更をチェックして」「コード見て改善して」などの文脈で使用する。
  コードを書き終えた後の仕上げ工程として、またPR作成前の品質担保として使う。
user-invocable: true
allowed-tools: Read, Edit, Write, Glob, Grep, Bash(git diff:*), Bash(git log:*), Bash(git show:*), Bash(git merge-base:*), Bash(git rev-parse:*), Bash(git branch:*), Bash(git remote:*), Agent
---

# Self Review Loop

変更内容をセルフレビューし、修正し、再レビューする。指摘が0件になるまで繰り返す。

## Phase 0: 準備

### ベースブランチの特定

以下の優先順で判断する:

1. PRコンテキストがあれば、そのベースブランチを使う
2. `git remote show origin` でデフォルトブランチを確認する
3. リポジトリの慣習（main / develop 等）から判断する

`git merge-base <base> HEAD` で分岐点を確定する。

### 変更の全体像を掴む

1. `git log <merge-base>..HEAD --oneline` でコミット履歴を確認し、変更の意図を理解する
2. `git diff <base>...HEAD --stat` で変更ファイル一覧を取得する
3. `git diff <base>...HEAD` で差分を読み、何を実現しようとしている変更かを把握する

この理解が以降のレビューの土台になる。変更の意図に沿わない「改善」は提案しない。

## Phase 1: レビュー

変更されたファイルと、その周辺コード（呼び出し元、呼び出し先、同モジュール内の関連コード）を読む。

### レビュー観点

#### 主軸: コードスメル検出

以下の優先度順に検出する。各スメルの検出ヒューリスティクスとリファクタリング技法は `references/smells-taxonomy.md` を参照。

1. **Bloaters** — 肥大化: Long Method, Large Class, Primitive Obsession, Long Parameter List, Data Clumps
2. **Change Preventers** — 変更耐性の低さ: Divergent Change, Shotgun Surgery, Parallel Inheritance Hierarchies
3. **Couplers** — 不適切な結合: Feature Envy, Inappropriate Intimacy, Message Chains, Middle Man, Incomplete Library Class
4. **OO Abusers** — OO設計違反: Switch Statements, Temporary Field, Refused Bequest, Alternative Classes with Different Interfaces
5. **Dispensables** — 不要なコード: Duplicate Code, Dead Code, Lazy Class, Data Class, Speculative Generality, Comments (Excessive)

コードスメルの検出は文脈を考慮する。DTOのData ClassやステートマシンのLong Methodなど、設計意図として妥当なものは指摘しない。taxonomyの各スメルに記載された「文脈判断」を参照すること。

#### 追加観点

- **正確性**: ロジックバグ、off-by-one、未処理のエラーパス、境界条件の抜け
- **セキュリティ**: インジェクション、認証・認可の漏れ、シークレットのハードコード
- **命名**: 意図が読み取れない名前、省略しすぎた名前、booleanが `is/has/should/can` で始まっていない

### 俯瞰レビュー

差分の外にも目を向け、今回の変更と合わせて改善すべき箇所がないか確認する。着眼点:

- **変更の前提を疑う**: 変更先のインターフェースや型定義に問題があれば、差分内のコードをいくら直しても根本解決にならない
- **波及先の一貫性**: 変更したクラスやモジュールの利用側で、同じパターンの問題が残っていないか
- **抽象化の過不足**: 今回の変更で同じ構造が3箇所になったなら、共通化の検討タイミング。逆に、1箇所しか使わない抽象化が増えていたら過剰

ただし、変更と無関係な改善欲は抑える。「今回の変更に起因する、または今回の変更と一緒に直すのが自然な範囲」に留める。

## Phase 2: 報告と修正

### 修正の判断基準

**自動修正する** — 修正方針が一意に定まる明確な問題:

- Dead Code削除、未使用importの除去
- 明らかなDuplicate Code（同一ロジックの重複）の統合
- Long Methodのうち、セクション境界が明確なもののExtract Method
- ロジックバグ（off-by-one、条件の反転など）
- セキュリティ上の明確な問題（インジェクション、シークレットの露出）
- 命名の明らかな改善（typo、意味が通らない名前）

**ユーザーに相談する** — トレードオフがある、または判断が分かれるもの:

- 複数の妥当なリファクタリング方針がある（Extract Classの分割軸が複数ある等）
- 修正すると変更範囲が大きく広がる（Shotgun Surgeryの解消、インターフェース変更など）
- パフォーマンスと可読性のトレードオフ
- 設計判断に関わるもの（責務の分割方針、抽象化レベル、依存方向）
- 俯瞰レビューで見つけた差分外の改善提案

### 報告フォーマット

各ラウンドの結果を以下の形式で報告する。

```
## Self Review — Round N

### 自動修正した項目

| # | カテゴリ | 問題 | 場所 | 修正内容 |
|---|---------|------|------|---------|
| 1 | Bloaters | Long Method | src/foo.py:42 | `_validate_input()` を抽出 |
| 2 | Dispensables | Dead Code | src/bar.py:15 | 未使用の `old_handler()` を削除 |

### 相談事項

#### 1. Shotgun Surgery — UserServiceの変更波及
- **場所**: src/user/service.py, src/auth/handler.py, src/admin/controller.py
- **現状**: UserServiceのインターフェース変更が3ファイルに波及している
- **選択肢**:
  - A: Facadeを導入して呼び出し側を1箇所に集約する → 変更は大きいが根本解決
  - B: 現状のまま個別に修正する → 変更は小さいがスメルは残る
- **推奨**: A。今後も同じ波及パターンが繰り返される可能性が高い

（ユーザーの判断を待つ）

### 指摘なし（該当する場合のみ）
指摘事項はありません。レビューループを終了します。
```

### 相談事項のフロー

1. 自動修正を先に実施し、相談事項と合わせて報告する
2. 相談事項がある場合、ユーザーの回答を待つ
3. ユーザーの判断に基づいて修正を実施する
4. Phase 1に戻り、再レビューする

相談事項がなく自動修正のみの場合は、報告後そのまま再レビューに進む。

## Phase 3: 再レビュー

修正後、Phase 1に戻って再レビューする。特に以下を重点的に確認する:

- 前ラウンドの修正が新たなスメルを生んでいないか（Extract Methodで新たなFeature Envy等）
- 自動修正した箇所の正確性（ロジックが変わっていないか）
- 相談事項の修正が意図通りか

指摘が0件になったら終了を宣言する。

## 原則

- **1ラウンドの修正は小さく保つ**: 一度に大きく変えると修正自体がバグを生むリスクがある。明確な問題を着実に潰していく。
- **変更の意図を尊重する**: 実装者の意図を理解した上でレビューする。「自分ならこう書く」ではなく「この意図を実現するならこう書くほうが良い」という視点。
- **過検出より見逃しを防ぐ**: 微妙なケースは指摘しないよりは相談事項として挙げるほうが良い。判断はユーザーに委ねる。
