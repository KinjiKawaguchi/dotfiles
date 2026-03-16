# Gitワークフロー

## コミット

- Conventional Commitsに従う: `feat:`, `fix:`, `refactor:`, `docs:`, `test:`, `chore:`
- メッセージは変更の目的（why）を1〜2文で簡潔に記述する。
- 1コミット = 1つの論理的な変更。大きな変更は意味のある単位で分割する。

## ブランチ

- `feat/xxx`, `fix/xxx`, `refactor/xxx` の命名規則に従う。
- main/masterへの直接pushは避ける。

## プルリクエスト

- タイトルは70文字以内。
- 本文に変更の概要（Summary）とテスト計画（Test plan）を含める。
- 関連するissueがあればリンクする。

## コミット前チェック

- シークレット（APIキー、トークン等）が含まれていないことを確認する。
- `.env`, `credentials.json` 等のファイルをコミットしない。
