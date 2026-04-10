# Code Smells Taxonomy

Martin Fowlerのリファクタリングカタログ（SourceMaking整理版）に基づく22のコードスメル分類。

## 目次

1. [Bloaters](#bloaters) — 肥大化（5種）
2. [Change Preventers](#change-preventers) — 変更耐性の低さ（3種）
3. [Couplers](#couplers) — 不適切な結合（5種）
4. [Object-Orientation Abusers](#oo-abusers) — OO設計違反（4種）
5. [Dispensables](#dispensables) — 不要なコード（6種）
6. [言語別の注意点](#言語別の注意点)

---

## Bloaters

サイズや複雑さが膨らみすぎたコード。最も目につきやすく、他のスメルの温床になる。

### Long Method

- **検出基準**: 15行超、ネスト3段以上、セクション間にコメント区切りがある、複数の抽象度が混在
- **具体的なシグナル**: 「このメソッドは〜して、それから〜して、最後に〜する」と説明できる場合、各ステップがExtract Method候補
- **リファクタリング**: Extract Method, Replace Temp with Query, Decompose Conditional, Replace Method with Method Object
- **文脈判断**: ステートマシンの遷移テーブル、パイプライン処理の直線的な連鎖は分割すると逆に追いづらくなる。分岐やループが少なく上から下に読める長い関数は許容されることがある

### Large Class

- **検出基準**: 200行超、10メソッド超、フィールドが10個超、クラス名に「And」「Manager」「Handler」が含まれる
- **具体的なシグナル**: クラスの一部のメソッドだけが一部のフィールドを使い、残りのメソッドは残りのフィールドを使う（責務が分離可能）
- **リファクタリング**: Extract Class, Extract Subclass, Extract Interface
- **文脈判断**: Facadeとして意図的に集約している場合や、フレームワークが1クラスに多くのメソッドを要求する場合は許容

### Primitive Obsession

- **検出基準**: 文字列やintでドメイン概念を表現している（金額、メールアドレス、電話番号、座標、期間など）
- **具体的なシグナル**: 同じバリデーションロジックが複数箇所に散在（emailのformat check等）、マジックナンバーが条件分岐に登場
- **リファクタリング**: Replace Data Value with Object, Replace Type Code with Class/Subclasses, Introduce Parameter Object
- **文脈判断**: ローカルスコープ内の一時変数、設定ファイルから読んだ値をそのまま渡すだけの場合は問題ない

### Long Parameter List

- **検出基準**: 引数が4つ以上、同じ引数セットが複数の関数に渡される
- **具体的なシグナル**: 引数の半数以上が同じオブジェクトから取り出されたもの（Preserve Whole Object候補）、引数のうち一部が常に一緒に渡される（Data Clumps候補）
- **リファクタリング**: Introduce Parameter Object, Preserve Whole Object, Replace Parameter with Method Call
- **文脈判断**: テスト用のファクトリ関数、純粋関数で明示性が重要な場合は許容

### Data Clumps

- **検出基準**: 同じ変数グループ（3つ以上）が3箇所以上に出現
- **具体的なシグナル**: `(x, y, z)` の組み合わせ、`(start_date, end_date)`、`(host, port, protocol)` など
- **リファクタリング**: Extract Class, Introduce Parameter Object
- **判定テスト**: グループから1つ変数を取り除いたとき、残りが意味をなさなくなるなら、それはData Clump

---

## Change Preventers

1つの変更が予想外の波及を起こす、または変更自体が困難になるスメル。

### Divergent Change

- **検出基準**: 1つのクラスが無関係な複数の理由で頻繁に変更される
- **具体的なシグナル**: git logで同じファイルが異なる目的のコミットに繰り返し登場する。「UIを変えるときもDBスキーマを変えるときもこのクラスを触る」
- **リファクタリング**: Extract Class（変更理由ごとに分離）
- **Shotgun Surgeryとの違い**: Divergent Change = 1クラスに複数の変更理由が集中。Shotgun Surgery = 1つの変更理由が複数クラスに分散

### Shotgun Surgery

- **検出基準**: 1つの論理的な変更が多数のファイルに波及する
- **具体的なシグナル**: 「この機能を変えるとき、毎回5ファイル以上触る」。同じ概念（定数名、フォーマット、プロトコル）が複数ファイルにハードコードされている
- **リファクタリング**: Move Method, Move Field, Inline Class（散らばった責務を1箇所に集約）
- **文脈判断**: Clean Architectureのレイヤー構造では、ある程度の波及は設計上の意図。波及が「レイヤーを跨ぐ方向」なのか「同一レイヤー内で横に広がる方向」なのかで判断が変わる

### Parallel Inheritance Hierarchies

- **検出基準**: あるクラスにサブクラスを追加すると、別の階層にも対応するサブクラスが必要になる
- **具体的なシグナル**: 2つの階層のクラス名に同じプレフィックスが現れる（`OrderProcessor` / `OrderValidator`、`FileExporter` / `FileFormatter` 等）
- **リファクタリング**: Move Method, Move Fieldで片方の階層を解消、またはCompositionに置き換え

---

## Couplers

クラス間の過剰な結合。変更の波及、テストの困難さにつながる。

### Feature Envy

- **検出基準**: メソッドが自クラスのデータより他クラスのデータを多く参照している
- **具体的なシグナル**: メソッド内で他オブジェクトのgetter呼び出しが支配的。`other.getA()` + `other.getB()` を使って計算し、自クラスのフィールドはほぼ使わない
- **リファクタリング**: Move Method（そのメソッドをデータを持つクラスに移動）, Extract Method + Move Method
- **文脈判断**: Strategy, Visitor, Commandパターンは意図的にデータとロジックを分離している

### Inappropriate Intimacy

- **検出基準**: 2つのクラスが互いの内部実装に過度に依存している
- **具体的なシグナル**: 双方向の参照、privateメンバへのリフレクションアクセス、friend宣言の多用、内部データ構造の直接操作
- **リファクタリング**: Move Method, Move Field, Change Bidirectional Association to Unidirectional, Extract Class（共通部分を第3のクラスに抽出）

### Message Chains

- **検出基準**: `a.getB().getC().getD()` のような3段以上のメソッド呼び出し連鎖
- **具体的なシグナル**: 途中のオブジェクトは最終目的のオブジェクトにたどり着くための経由地でしかない
- **リファクタリング**: Hide Delegate, Extract Method + Move Method
- **文脈判断**: Fluent API、Builderパターン、StreamやLINQのチェーンは意図的な設計であり問題ない。判定基準は「途中の型を知る必要があるか」

### Middle Man

- **検出基準**: クラスのメソッドの大半が、そのまま別クラスのメソッドに委譲しているだけ
- **具体的なシグナル**: メソッドの中身が `return this.delegate.sameMethod(args)` だけのものが半数以上
- **リファクタリング**: Remove Middle Man（呼び出し元に直接使わせる）, Inline Method
- **文脈判断**: 将来の拡張ポイントとして意図的に置いている場合は許容。ただし実際に拡張される見込みがなければSpeculative Generality

### Incomplete Library Class

- **検出基準**: ライブラリやフレームワークの機能不足を補うためのユーティリティが外部に増殖している
- **具体的なシグナル**: `XxxUtils`, `XxxHelper` クラスが特定のライブラリ型を引数に取る関数を大量に持っている
- **リファクタリング**: Introduce Foreign Method（少数の場合）, Introduce Local Extension（多数の場合）
- **文脈判断**: ライブラリの設計ミスに起因するため、スメルを完全に除去できないこともある。ユーティリティを1箇所に集約するだけでも改善

---

## OO Abusers

オブジェクト指向の原則に反するパターン。関数型やマルチパラダイム言語では一部が当てはまらない。

### Switch Statements

- **検出基準**: 型コードや列挙値に基づくswitch/if-elseチェーンが複数箇所に出現する
- **具体的なシグナル**: 同じ条件分岐（`if type == "A" ... elif type == "B" ...`）がコードベースの複数メソッドに現れる。新しい型を追加するとき、すべての分岐箇所を探して更新する必要がある
- **リファクタリング**: Replace Conditional with Polymorphism, Replace Type Code with Subclasses/State/Strategy
- **文脈判断**: 1箇所だけのパターンマッチ、外部データのデシリアライズ時のディスパッチ、関数型スタイルのパターンマッチングは許容

### Temporary Field

- **検出基準**: 特定のメソッド呼び出し時にしかセットされないフィールドがある
- **具体的なシグナル**: フィールドのNone/nullチェックが散在、「このフィールドはprocess()を呼んだ後しか使えない」というような暗黙の前提
- **リファクタリング**: Extract Class（一時フィールドとそれを使うメソッドを専用クラスに抽出）, Introduce Null Object, Replace Method with Method Object

### Refused Bequest

- **検出基準**: サブクラスが親クラスのメソッドや属性の大半を使わない、または意味を変えてオーバーライドしている
- **具体的なシグナル**: サブクラスで `raise NotImplementedError` や空実装のオーバーライドが多い。リスコフの置換原則に違反している
- **リファクタリング**: Replace Inheritance with Delegation, Extract Superclass（本当に共通な部分だけを親に残す）

### Alternative Classes with Different Interfaces

- **検出基準**: 同じ振る舞いを持つクラスが異なるメソッド名やシグネチャで実装されている
- **具体的なシグナル**: `UserValidator.validate(user)` と `AccountChecker.check(account)` が本質的に同じことをしている。呼び出し側でアダプタやif分岐が必要になっている
- **リファクタリング**: Rename Method（統一）, Extract Superclass/Interface, Move Method

---

## Dispensables

存在しないほうがコードが良くなるもの。除去のリスクが低く、クイックウィンになりやすい。

### Duplicate Code

- **検出基準**: 2箇所以上で3行以上の類似ロジックが存在する
- **具体的なシグナル**: コピペの痕跡（変数名だけ違う同じ構造）、一方を修正したとき他方も修正が必要になる
- **リファクタリング**: Extract Method（同一クラス内）, Extract Class / Pull Up Method（異なるクラス間）, Form Template Method（似た構造で一部だけ異なる場合）

### Dead Code

- **検出基準**: 到達不能コード、未使用の変数・関数・import・クラス
- **具体的なシグナル**: IDEの警告、コメントアウトされたコードブロック、`if False:` ガード
- **リファクタリング**: 削除する。変更履歴はGitにある
- **注意**: リフレクション、動的ディスパッチ、シリアライゼーション、テストフィクスチャから使われていないか確認

### Lazy Class

- **検出基準**: クラスの存在意義が薄い。メソッドが1-2個、または他クラスとほぼ同じ
- **具体的なシグナル**: リファクタリングでメソッドを移動した結果、ほとんど空になったクラス。「このクラス、消しても誰も困らないのでは」
- **リファクタリング**: Inline Class, Collapse Hierarchy

### Data Class

- **検出基準**: フィールドとアクセサしか持たず、振る舞い（ビジネスロジック）がない
- **具体的なシグナル**: このクラスのデータを使った計算や判定が、他のクラスに散在している（Feature Envyと併発しやすい）
- **リファクタリング**: Move Method（散在するロジックをこのクラスに集める）, Encapsulate Field / Encapsulate Collection
- **文脈判断**: DTO、イベントペイロード、設定値オブジェクト、ORMのエンティティ（一部フレームワーク）は意図的にData Classであり問題ない

### Speculative Generality

- **検出基準**: 「将来使うかもしれない」で作られた抽象化、パラメータ、フック
- **具体的なシグナル**: 実装が1つしかないインターフェース（テスト用モック以外で）、使われていないコールバック引数、「Extension Point」とコメントされた未使用の拡張点
- **リファクタリング**: Collapse Hierarchy, Inline Class, Remove Parameter
- **文脈判断**: フレームワークやライブラリの公開APIでは拡張性を先に用意するのが正当な場合がある

### Comments (Excessive)

- **検出基準**: コードの不明確さをコメントで補っている
- **具体的なシグナル**: メソッド内の各セクションにコメント見出しがある（Extract Method候補）、変数名の意味をコメントで説明している（Rename候補）、条件式の意味をコメントで説明している（Decompose Conditional候補）
- **リファクタリング**: Extract Method, Rename Method/Variable, Decompose Conditional（コード自体を自己説明的にする）
- **文脈判断**: WHY（なぜこの実装を選んだか）を説明するコメントは有用であり、スメルではない。WHAT（何をしているか）を説明するコメントはコードの改善余地を示唆する

---

## 言語別の注意点

### Python

- 巨大な `.py` ファイル（1000行超のモジュール） → Large Class相当。モジュール自体が「クラス」として振る舞う
- ミュータブルなデフォルト引数 → バグの温床、Temporary Field的な問題を引き起こす
- 広すぎる `except Exception` / bare `except` → エラーの握りつぶし
- `**kwargs` の多用でシグネチャが不明確 → Long Parameter Listの隠蔽

### TypeScript / JavaScript

- コールバックチェーン / Promise chain → Message Chains相当
- prop drilling（何層もの中間コンポーネントにpropsを通す）→ Data Clumps相当
- `any` 型の多用 → Primitive Obsession相当。型安全性を放棄している
- 巨大なReactコンポーネント（UIロジック + データ取得 + 状態管理の混在）→ Large Class相当
- `useEffect` の依存配列が巨大 → Divergent Change的な責務の混在

### Go

- 長い関数 → Goではエラーハンドリングの冗長さから起きやすい。ロジック部分だけで判断する
- 戻り値が4つ以上 → Long Parameter List相当
- パッケージレベルの循環的な結合
- `interface{}` / `any` の多用 → Primitive Obsession相当

### Rust

- `.unwrap()` チェーンの多用 → パニックリスク。`?` 演算子やパターンマッチへの置き換えを検討
- 過度に複雑なトレイト階層 → Parallel Inheritance Hierarchies相当
- ライフタイム注釈が過剰に伝播 → 所有権設計の見直しが必要かもしれない
