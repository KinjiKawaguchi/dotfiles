# dotfiles

macOS 環境を **Nix (nix-darwin + home-manager + flakes)** で宣言的に管理する。Git 設定は OS 別ファイル分割で macOS / Linux 両対応（[Git 設定の OS 別分割](#git-設定の-os-別分割)）。Nix を入れられない共用 Linux マシン等では手動 symlink で同じ dotfile を流用できる（[Nix を使えない環境](#nix-を使えない環境共用-linux-等)）。

## 構成

```
dotfiles/
├── flake.nix          # エントリポイント・マルチホスト定義 (mkDarwin)
├── flake.lock         # 依存ロック
├── Makefile           # 日常操作のショートカット
├── nix/
│   ├── darwin.nix     # macOS システム設定 (Homebrew, Dock, Finder, Touch ID 等)
│   └── home.nix       # ユーザー環境 (CLI パッケージ, シェル, dotfile リンク)
├── .claude/           # Claude Code の設定 (hooks, rules, skills, statusline)
├── nvim/              # Neovim 設定
├── .tmux.conf         # tmux
├── .p10k.zsh          # Powerlevel10k
├── .gitconfig         # Git 共通設定 (user/lfs/gpg/commit.gpgsign 等)
├── .gitconfig.macos   # Git: macOS 固有 (1Password ssh-sign, brew gh)
├── .gitconfig.linux   # Git: Linux 固有 (~/.ssh/id_rsa.pub, PATH 上の gh)
├── .ssh/config
└── .config/
    ├── git/allowed_signers   # SSH 署名検証用 (OS 共通)
    ├── gh/config.yml
    └── karabiner/karabiner.json
```

dotfile は `mkOutOfStoreSymlink` で直接リンクされるため、リポジトリを編集すれば **Nix 再ビルドなしで即反映**される。

## 新しい Mac でのセットアップ

### 1. 前提ツールを入れる

```bash
# Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# brew を現在の shell に通す（Homebrew インストーラが表示する指示と同じ内容）
eval "$(/opt/homebrew/bin/brew shellenv)"

# Nix (Determinate Systems)
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

新しいシェルを開き直して `nix --version` と `brew --version` の両方が通ることを確認。

### 2. dotfiles を clone

```bash
git clone git@github.com:KinjiKawaguchi/dotfiles ~/dotfiles
cd ~/dotfiles
```

### 3. ホストを登録して適用

```bash
make add-host   # hostname, アーキテクチャ, ユーザー名を自動検出して flake.nix に追加
git add flake.nix && git commit -m "feat: add $(scutil --get LocalHostName)"
make switch     # 初回は Homebrew の全パッケージ DL で 10〜20 分かかる
```

初回の Homebrew が長い場合は Nix 部分だけ先に適用できる:

```bash
make switch-fast   # Homebrew スキップ
make brew-only     # 後から Homebrew だけ同期
```

### 4. Apple ID でサインインして Mac App Store アプリを取得

`homebrew.masApps` で宣言した App Store アプリは、Apple ID でサインイン済みかつ過去に「入手」済みであれば `make switch` 時に自動インストールされる。

## 日常の操作 (Makefile)

```
make switch        設定をビルドして適用（Homebrew 含む）
make switch-fast   Homebrew をスキップして適用
make build         ビルドだけ（アクティベートしない）
make brew-only     Homebrew だけ同期
make check         flake の評価エラーをチェック
make update        flake.lock 更新（nixpkgs 等を最新に）
make gc            7 日以上前の世代とストアをガベコレ
make rollback      一個前の世代に戻す
make generations   システム世代一覧
make add-host      flake.nix に Mac ホストを追加（NAME, SYS, USER を省略すると自動検出）
```

ホストを明示指定する場合:

```bash
make add-host NAME=My-MacBook SYS=x86_64-darwin USER=myuser
```

## 管理方針

| 対象 | 管理場所 |
|------|---------|
| CLI ツール (bat, fd, ripgrep, nvim, tmux, uv, node 等) | `nix/home.nix` の `home.packages` |
| GUI アプリ (Arc, Chrome, Slack, Discord, VS Code 等) | `nix/darwin.nix` の `homebrew.casks` |
| Mac App Store アプリ (LINE, Xcode, Magnet 等) | `nix/darwin.nix` の `homebrew.masApps` |
| nixpkgs にない CLI (envoy, mysql) | `nix/darwin.nix` の `homebrew.brews` |
| macOS 設定 (Dock, Finder, キーリピート, ダークモード等) | `nix/darwin.nix` の `system.defaults` |
| シェル設定 | `nix/home.nix` の `programs.zsh` |
| Git 設定 | `.gitconfig` + `.gitconfig.{macos,linux}` (OS 別) + `.config/git/allowed_signers` を `nix/home.nix` の `home.file` で symlink |
| dotfile シンボリンク (.claude, .tmux.conf, nvim 等) | `nix/home.nix` の `home.file` |
| プロジェクト固有ツール (gradle, dart, postgres 等) | プロジェクトの `flake.nix` + direnv |
| Setapp アプリ | Setapp クライアント（宣言的管理不可） |
| 自己更新系 (Google Cloud SDK 等) | 公式インストーラ（Nix 管理外） |

`homebrew.onActivation.cleanup = "zap"` により、宣言から外したパッケージは `make switch` 時に**自動アンインストール**される。

## Git 設定の OS 別分割

macOS と Linux で `signingkey`、`gpg.ssh.program`、`gh` のフルパスが異なるため、共通部分と OS 固有部分をファイル分割する:

```
.gitconfig             共通設定 (user, lfs, gpg.format, allowedSignersFile, commit.gpgsign 等)
.gitconfig.macos       macOS 固有 (1Password の op-ssh-sign パス, /opt/homebrew/bin/gh)
.gitconfig.linux       Linux 固有 (~/.ssh/id_rsa.pub を signingkey, PATH 上の gh)
.config/git/allowed_signers   SSH 署名検証用の信頼鍵リスト (両 OS 共通)
~/.gitconfig.local     ホスト固有 override (個別マシンで signingkey 等を上書き; リポジトリ外)
```

`.gitconfig` は末尾で `[include] path = ~/.gitconfig.os` と `~/.gitconfig.local` を取り込む。`~/.gitconfig.os` は各マシンが OS に応じて `.gitconfig.macos` か `.gitconfig.linux` への symlink として張る。

macOS では nix-darwin / home-manager が `~/.gitconfig.os` を `.gitconfig.macos` に向けて自動配置する（`nix/home.nix` の `home.file."~/.gitconfig.os".source`）。Linux では手動で symlink する（[Nix を使えない環境](#nix-を使えない環境共用-linux-等)を参照）。

## Nix を使えない環境（共用 Linux 等）

root 権限が無い・他ユーザーへの影響を避けたい等の理由で Nix を入れられない UNIX マシンでは、**dotfile を手動 symlink** することで同じ宣言を流用する。

```bash
# 共通 dotfile
ln -sf "$PWD/.tmux.conf"             ~/.tmux.conf
ln -sf "$PWD/.p10k.zsh"              ~/.p10k.zsh           # zsh + p10k を使うなら
ln -sf "$PWD/nvim"                   ~/.config/nvim
ln -sf "$PWD/.claude/CLAUDE.md"      ~/.claude/CLAUDE.md
ln -sf "$PWD/.claude/settings.json"  ~/.claude/settings.json
ln -sf "$PWD/.claude/statusline.sh"  ~/.claude/statusline.sh
ln -sf "$PWD/.claude/hooks"          ~/.claude/hooks
ln -sf "$PWD/.claude/rules"          ~/.claude/rules
ln -sf "$PWD/.claude/skills"         ~/.claude/skills
ln -sf "$PWD/.config/gh/config.yml"  ~/.config/gh/config.yml

# Git (OS 別分割)
ln -sf "$PWD/.gitconfig"                       ~/.gitconfig
ln -sf "$PWD/.gitconfig.linux"                 ~/.gitconfig.os    # macOS なら .gitconfig.macos
ln -sf "$PWD/.config/git/allowed_signers"      ~/.config/git/allowed_signers
```

ホスト固有の signingkey 等が要る場合は `~/.gitconfig.local` を実体ファイルで作成（リポジトリ外）:

```ini
[user]
	signingkey = ssh-rsa AAAA... your-host-key
```

### 注意

- `make switch` は `nix-darwin#darwin-rebuild` を呼ぶため macOS 専用。Linux では使わない。
- `~/.gitconfig.local` はホスト固有なので **リポジトリにコミットしない**。
- `.zshrc` は現状 macOS 固有要素を含む単一ファイル。Linux で動作させるには各自実体ファイルで書くか、OS 検知付きの版に置き換える（TODO）。

## マルチホスト

`flake.nix` の `mkDarwin` で hostname, system, username をホストごとに定義:

```nix
darwinConfigurations = {
  "My-MacBook" = mkDarwin { hostname = "My-MacBook"; system = "aarch64-darwin"; username = "myuser"; };
};
```

`make add-host` で現マシンの情報を自動検出して追加できる。

## トラブルシュート

### Homebrew bundle で Permission denied

`/opt/homebrew` の所有者が現ユーザーと違う場合:

```bash
sudo chown -R $(whoami):admin /opt/homebrew
```

### brew が見つからない（初回セットアップ）

Homebrew インストール直後は PATH が通っていない:

```bash
eval "$(/opt/homebrew/bin/brew shellenv)"
```

### `Determinate detected` で落ちる

`darwin.nix` に `nix.enable = false;` が入っているか確認（Determinate Systems のインストーラは Nix 本体を自前で管理するため、nix-darwin 側で二重管理しない）。

### 既存の `.zshrc` が "clobber" で落ちる

`flake.nix` の `home-manager.backupFileExtension = "backup"` が設定されていれば既存ファ���ルは `.backup` に自動退避される。既に `.zshrc.backup` が存在する場合はリネームしてから再実行。

### user has unexpected uid

`darwin.nix` の `system.primaryUser` が `username` パラメータから設定されているか確認。uid はハードコードせず macOS に任せる設計。
