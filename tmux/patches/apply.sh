#!/usr/bin/env bash
#
# tmux-agent-sidebar にローカルパッチを当てて再ビルドする。
#
# TPM の更新（prefix + U）はプラグインを upstream の状態に戻すため、
# 更新のたびにこのスクリプトを実行する。適用済みなら何もしない。
#
# upstream が同等の修正を取り込んだら（issue #112 / PR #118）、
# パッチは当たらなくなるのでこのディレクトリごと削除してよい。

set -euo pipefail

PLUGIN_DIR="${TMUX_AGENT_SIDEBAR_DIR:-$HOME/.tmux/plugins/tmux-agent-sidebar}"
PATCH_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ ! -d "$PLUGIN_DIR" ]]; then
    echo "プラグインが見つからない: $PLUGIN_DIR" >&2
    exit 1
fi

cd "$PLUGIN_DIR"

applied=0
skipped=0

for patch in "$PATCH_DIR"/*.patch; do
    name="$(basename "$patch")"

    if git apply --reverse --check "$patch" 2>/dev/null; then
        echo "適用済み: $name"
        skipped=$((skipped + 1))
        continue
    fi

    if ! git apply --check "$patch" 2>/dev/null; then
        echo "適用できない: $name" >&2
        echo "  upstream が同じ修正を取り込んだか、対象コードが変わった可能性がある。" >&2
        exit 1
    fi

    git apply "$patch"
    echo "適用: $name"
    applied=$((applied + 1))
done

if [[ $applied -eq 0 ]]; then
    echo "変更なし（$skipped 件が適用済み）。ビルドをスキップする。"
    exit 0
fi

cargo build --release

# 実行中のインスタンスがバイナリを掴んでいるので、上書きではなく置き換える。
# 既存プロセスは削除前の inode を保持したまま動き続ける。
rm -f bin/tmux-agent-sidebar
cp target/release/tmux-agent-sidebar bin/tmux-agent-sidebar

echo
echo "ビルドと差し替えが完了した。反映するには実行中のサイドバーを終了する:"
echo "  pkill -f \"$PLUGIN_DIR/bin/tmux-agent-sidebar\""
echo "その後、各ウィンドウで prefix + e を押して開き直す。"
