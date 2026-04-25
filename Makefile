NIX  := /nix/var/nix/profiles/default/bin/nix
FLAG := --flake $(PWD)

.PHONY: help switch build check update gc rollback generations

help: ## このヘルプを表示
	@awk 'BEGIN{FS=":.*##"} /^[a-zA-Z_-]+:.*##/ {printf "  \033[36m%-14s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

switch: ## 設定をビルドして適用（通常使うやつ）
	sudo $(NIX) run nix-darwin#darwin-rebuild -- switch $(FLAG)

build: ## ビルドだけ（アクティベートしない）
	$(NIX) run nix-darwin#darwin-rebuild -- build $(FLAG)

check: ## flake の評価エラーをチェック
	$(NIX) flake check $(FLAG)

update: ## flake.lock 更新（nixpkgs 等を最新に）
	$(NIX) flake update

gc: ## 7 日以上前の世代とストアをガベコレ
	sudo /nix/var/nix/profiles/default/bin/nix-collect-garbage --delete-older-than 7d
	/nix/var/nix/profiles/default/bin/nix-collect-garbage --delete-older-than 7d

rollback: ## 一個前の世代に戻す
	sudo /run/current-system/sw/bin/darwin-rebuild --rollback

generations: ## システム世代一覧
	sudo /nix/var/nix/profiles/default/bin/nix-env --list-generations --profile /nix/var/nix/profiles/system

# 使い方:
#   make add-host                                              (全自動検出)
#   make add-host NAME=foo SYS=x86_64-darwin USER=myuser
add-host: ## flake.nix に Mac ホストを追加（NAME, SYS, USER を省略すると自動検出）
	@host="$${NAME:-$$(scutil --get LocalHostName 2>/dev/null || hostname -s)}"; \
	arch="$$(uname -m)"; \
	case "$$arch" in arm64) defsys=aarch64-darwin ;; x86_64) defsys=x86_64-darwin ;; *) defsys=unknown ;; esac; \
	sys="$${SYS:-$$defsys}"; \
	user="$${USER:-$$(id -un)}"; \
	if grep -q "\"$$host\" = mkDarwin" flake.nix; then \
	  echo "host '$$host' is already in flake.nix"; \
	  exit 0; \
	fi; \
	if [ "$$sys" = "unknown" ]; then echo "system unknown, pass SYS=x86_64-darwin or aarch64-darwin"; exit 1; fi; \
	line="      \"$$host\" = mkDarwin { hostname = \"$$host\"; system = \"$$sys\"; username = \"$$user\"; };"; \
	awk -v L="$$line" '/# NIX_HOSTS_END/ { print L } { print }' flake.nix > flake.nix.tmp && mv flake.nix.tmp flake.nix; \
	echo "added '$$host' ($$sys, user=$$user) to flake.nix"; \
	echo "next: git add flake.nix && git commit, then run 'make switch' on the machine"
