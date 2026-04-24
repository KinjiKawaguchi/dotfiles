# dotfiles

macOS 環境を **Nix (nix-darwin + home-manager + flakes)** で宣言的に管理する。

## 構成

```
dotfiles/
├── flake.nix          # エントリポイント・マルチホスト定義
├── flake.lock         # 依存ロック
├── Makefile           # 日常操作のショートカット
├── nix/
│   ├── darwin.nix     # macOS システム設定 (Homebrew, Touch ID, フォント等)
│   └── home.nix       # ユーザー環境 (CLI パッケージ, シェル, dotfile リンク)
├── .claude/           # Claude Code の設定 (hooks, rules, skills, statusline)
├── nvim/              # Neovim 設定
├── .tmux.conf         # tmux
├── .p10k.zsh          # Powerlevel10k
├── .ssh/config
└── .config/
    ├── gh/config.yml
    └── karabiner/karabiner.json
```

dotfile は `mkOutOfStoreSymlink` で直接リンクされるため、リポジトリを編集すれば **Nix 再ビルドなしで即反映**される。

## 新しい Mac でのセットアップ

### 1. 前提ツールを入れる

```bash
# Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Nix (Determinate Systems)
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

新しいシェルを開き直して `nix --version` が通ることを確認。

### 2. dotfiles を clone

```bash
git clone git@github.com:KinjiKawaguchi/dotfiles ~/dotfiles
cd ~/dotfiles
```

### 3. ホストを登録して適用

```bash
make add-host   # 現マシンの hostname + アーキテクチャを flake.nix に追加
git add flake.nix && git commit -m "feat: add <hostname>"
make switch
```

## 日常の操作 (Makefile)

```
make switch        設定をビルドして適用（通常使うやつ）
make build         ビルドだけ（アクティベートしない）
make check         flake の評価エラーをチェック
make update        flake.lock 更新（nixpkgs 等を最新に）
make gc            7 日以上前の世代とストアをガベコレ
make rollback      一個前の世代に戻す
make generations   システム世代一覧
make add-host      flake.nix に Mac ホストを追加（NAME, SYS を省略すると自動検出）
```

ホストを明示指定する場合:

```bash
make add-host NAME=Kinjis-Intel-Mac SYS=x86_64-darwin
```

## パッケージ管理の方針

| ツール種別 | 管理場所 |
|-----------|---------|
| CLI ツール (bat, fd, ripgrep, lazygit, nvim, tmux 等) | `nix/home.nix` の `home.packages` |
| GUI アプリ (Warp, PyCharm, Wireshark 等) | `nix/darwin.nix` の `homebrew.casks` |
| nixpkgs にない特殊なもの (cabocha, mecab, heroku 等) | `nix/darwin.nix` の `homebrew.brews` |
| フォント | `nix/darwin.nix` の `homebrew.casks` |

`homebrew.onActivation.cleanup = "zap"` により、Brewfile に書いていないパッケージは **自動でアンインストール**される。

## トラブルシュート

### `darwin-rebuild` 時に "system.primaryUser" が要求される

`darwin.nix` の `system.primaryUser = "YourUsername"` を確認。

### `Determinate detected` で落ちる

`darwin.nix` に `nix.enable = false;` が入っているか確認（Determinate Systems のインストーラは Nix 本体を自前で管理するため、nix-darwin 側で二重管理しない）。

### 既存の `.zshrc` が "clobber" で落ちる

`flake.nix` の `home-manager.backupFileExtension = "backup"` が設定されていれば既存ファイルは自動で `.backup` に退避される。

### macOS のユーザー名末尾にスペースが入っている

`dscl . -read /Users/<username> RecordName` で確認。末尾スペースがある場合:

```bash
sudo dscl . -change "/Users/<username> " RecordName "<username> " "<username>"
```

で修正。反映には再ログインが必要。
