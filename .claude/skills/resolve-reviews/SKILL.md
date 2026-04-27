---
name: resolve-reviews
description: >
  GitHub PRのレビューコメントを取得し、各指摘の妥当性を判断して修正・resolveする。
  PRレビュー対応、レビュー指摘の解決、レビューコメントへの対応、コードレビューの処理、
  review resolve、PR feedback対応など、レビュー対応に関するあらゆる文脈で使用する。
  ユーザーが「レビュー対応して」「PRのコメント見て」「指摘を直して」などと言った場合にトリガーする。
user-invocable: true
---

# Resolve Reviews

GitHub PRのレビューコメントを取得し、妥当性を評価した上で修正またはユーザーへの相談を行う。

## ワークフロー

### 1. PR特定とレビュー取得

PR番号の指定がなければ現在のブランチに紐づくPRを対象とする。

```bash
# 現ブランチのPR取得
gh pr view --json number,title,body,url

# レビューコメント取得（inline comments）
gh api repos/{owner}/{repo}/pulls/{number}/comments --paginate

# スレッド情報 (resolve 状態 + thread ID) は GraphQL で取得する
gh api graphql -f query='
{
  repository(owner: "{owner}", name: "{repo}") {
    pullRequest(number: {number}) {
      reviewThreads(first: 100) {
        nodes {
          id
          isResolved
          path
          line
          comments(first: 1) {
            nodes { databaseId body }
          }
        }
      }
    }
  }
}'
```

**注意**: REST API (`/pulls/{n}/comments`) だけだと thread の resolve 状態と thread ID が取れない。GraphQL の `reviewThreads` を必ず併用する。既に resolve 済みの thread を再処理しないこと。

### 2. コメントの分類

取得した各コメントを以下のカテゴリに分類する:

| カテゴリ | 説明 | 対応方針 |
|---------|------|---------|
| **修正必須** | コードの正確性、セキュリティ、パフォーマンスに関する妥当な指摘 | 修正する |
| **改善提案** | より良い書き方やリファクタリングの提案 | 妥当性を評価して判断 |
| **設計に関わる指摘** | アーキテクチャや設計方針に影響する指摘 | ユーザーに相談 |
| **質問・確認** | コードの意図や背景を聞いているもの | 回答案を提示 |
| **コメント・感想** | 対応不要な感想やメモ | スキップ（必要ならresolveのみ） |
| **的外れな指摘** | コードを誤読している、または文脈を理解していない指摘 | ユーザーに報告し、反論案を提示 |

### 3. 妥当性の評価

各指摘について以下の観点で妥当性を判断する:

- **技術的正確性**: 指摘の内容が技術的に正しいか
- **コンテキスト理解**: レビュアーが変更の意図や背景を正しく理解しているか
- **プロジェクト規約との整合**: CLAUDE.md、development-rulebook、既存のコーディング規約に照らして妥当か
- **設計意図との整合**: PR descriptionやコミット履歴から読み取れる当初の設計意図と矛盾しないか
- **スコープの適切さ**: このPRの範囲で対応すべき内容か、別issueにすべきか
- **コスト対効果**: 修正の手間に対して得られる改善が見合うか

### 4. 対応の実行

#### 自動で修正してよいもの
- タイポ、命名の修正
- import順序、フォーマットの修正
- 明らかなバグ修正（レビュアーの指摘が正しく、修正方法が一意に定まる場合）
- 規約違反の修正（lint的な指摘）
- 軽微なリファクタリング（変数名変更、不要コードの削除など）

#### ユーザーに相談すべきもの
- 設計方針の変更を伴う修正
- 複数の対応方法があり、トレードオフがあるもの
- 当初の設計意図と矛盾する指摘
- 大きなスコープの変更を伴う提案
- 自分の判断に確信が持てないもの

### 5. GitHub thread の resolve (必須ステップ、忘れない)

**修正を push しただけでは thread は resolve されない。** GraphQL mutation で
明示的に resolve する。対応分類ごとの作法:

| 分類 | 作法 |
|------|------|
| 自動修正した | reply で `Fixed in {sha}` と残してから resolve |
| 対応不要と判断 (スコープ外 / 設計意図) | 理由を reply してから resolve |
| 指摘が的外れ | 誤読していると判断した根拠を reply してから resolve |
| 純粋な情報コメント (`📝 Info` 等) | silent resolve (reply なし) でよい |
| 質問 | 回答を reply してから resolve (質問が未解決のまま resolve しない) |

```bash
# reply (thread にコメント追加)
gh api graphql -f query='
mutation($threadId: ID!, $body: String!) {
  addPullRequestReviewThreadReply(input: {
    pullRequestReviewThreadId: $threadId, body: $body
  }) { comment { id } }
}' -F threadId="PRRT_..." -F body="Fixed in abc1234"

# resolve
gh api graphql -f query='
mutation($threadId: ID!) {
  resolveReviewThread(input: {threadId: $threadId}) {
    thread { id isResolved }
  }
}' -F threadId="PRRT_..."
```

**バッチ処理のコツ**: 10 件超える場合は Python で dict mapping (`thread_id →
reply_text | None`) を作り、`subprocess.run(["gh", "api", "graphql", ...])` で
ループする。reply と resolve を 2 本の mutation で順次呼ぶ。

**確認**: 処理後に再度 `reviewThreads` クエリで `isResolved` の数を数えて
「resolved: N/N」を user に報告する。残 open が 0 であることを保証する。

### 6. 報告

対応完了後、以下の形式でサマリを報告する:

```
## レビュー対応サマリ

### 自動修正済み
- [コメントURL] 指摘内容の要約 → 修正内容

### 相談事項
- [コメントURL] 指摘内容の要約
  - レビュアーの意図: ...
  - 当初の設計意図: ...
  - 選択肢と推奨: ...

### 対応不要と判断
- [コメントURL] 理由の簡潔な説明

### 回答案（質問への返答）
- [コメントURL] 質問内容 → 回答案
```

## 重要な原則

- **resolve まで完遂する**: 修正の push で終わらせない。GitHub thread の resolve
  (reply + `resolveReviewThread` mutation) までが本 skill の scope。push 後に
  「resolve は?」と user に尋ねられる状態は避ける。
- **ホウレンソウを怠らない**: 判断に迷ったら相談する。自動修正した場合も必ずサマリで報告する。
- **レビュアーを尊重する**: 的外れに見える指摘でも、まず「なぜそう指摘したのか」を考える。ただし、明らかに誤読している場合は率直にそう報告する。
- **設計の一貫性を守る**: レビュー指摘に従うことで設計がちぐはぐになるなら、安易に従わず相談する。部分最適より全体最適を優先する。
- **スコープを意識する**: 「正しいが今やるべきではない」指摘は、issueを切ることを提案する。resolve する際は reply で scope 境界を明示する (例: 別 PR 参照)。
