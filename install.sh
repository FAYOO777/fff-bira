#!/usr/bin/env bash
# fff-bira v4 installer/updater. Usage: bash install.sh cvm|pve|vm|phy
set -euo pipefail

role="${1:-}"
case "$role" in
  cvm|pve|vm|phy) ;;
  *) printf '用法: bash install.sh {cvm|pve|vm|phy}\n' >&2; exit 2 ;;
esac

omz="${ZSH:-$HOME/.oh-my-zsh}"
rc="$HOME/.zshrc"
custom="${ZSH_CUSTOM:-$omz/custom}"
theme_dir="$custom/themes"
theme="$theme_dir/fff-bira.zsh-theme"
base_url="${FFF_BIRA_BASE_URL:-https://raw.githubusercontent.com/FAYOO777/fff-bira/main}"

if [[ ! -f "$omz/themes/bira.zsh-theme" || ! -f "$rc" ]]; then
  printf '未找到 Oh My Zsh 的 bira 主题或 ~/.zshrc，请先安装 Oh My Zsh。\n' >&2
  exit 1
fi
if ! command -v zsh >/dev/null 2>&1; then
  printf '未找到 zsh，无法检查主题语法。\n' >&2
  exit 1
fi
if ! command -v curl >/dev/null 2>&1 && ! command -v wget >/dev/null 2>&1; then
  printf '请先安装 curl 或 wget。\n' >&2
  exit 1
fi

mkdir -p "$theme_dir"
tmp_theme="$(mktemp "$theme_dir/.fff-bira.XXXXXXXX")"
tmp_rc="$(mktemp "$HOME/.zshrc.fff-bira.XXXXXXXX")"
trap 'rm -f "$tmp_theme" "$tmp_rc"' EXIT

if command -v curl >/dev/null 2>&1; then
  curl --fail --silent --show-error --location --connect-timeout 10 --max-time 45 \
    "$base_url/fff-bira.zsh-theme" -o "$tmp_theme"
else
  wget -q -T 45 -O "$tmp_theme" "$base_url/fff-bira.zsh-theme"
fi
if ! zsh -n "$tmp_theme"; then
  printf '下载的主题未通过 zsh 语法检查，原有文件未修改。\n' >&2
  exit 1
fi

awk -v role="$role" '
  /^[[:space:]]*(export[[:space:]]+)?ZSH_THEME=/ { next }
  /^[[:space:]]*(export[[:space:]]+)?(FAYOO_ROLE|FFF_BIRA_ROLE)=/ { next }
  /^[[:space:]]*(source|\.)[[:space:]]+.*oh-my-zsh[.]sh/ {
    print "ZSH_THEME=\"fff-bira\""
    print "FFF_BIRA_ROLE=\"" role "\""
    found=1
  }
  { print }
  END { if (!found) exit 3 }
' "$rc" > "$tmp_rc" || {
  printf '未找到 ~/.zshrc 中加载 oh-my-zsh.sh 的语句，原配置未修改。\n' >&2
  exit 1
}
chmod --reference="$rc" "$tmp_rc"

stamp="$(date +%Y%m%d-%H%M%S)-$$"
rc_backup="$rc.bak.$stamp"
cp -p "$rc" "$rc_backup"
if [[ -e "$theme" ]]; then
  cp -p "$theme" "$theme.bak.$stamp"
fi
chmod 644 "$tmp_theme"
mv -f "$tmp_theme" "$theme"
if ! mv -f "$tmp_rc" "$rc"; then
  cp -p "$rc_backup" "$rc"
  printf '配置写入失败，已恢复 ~/.zshrc，请检查主题文件。\n' >&2
  exit 1
fi

printf 'fff-bira v4 已安装：%s\n' "$role"
printf '配置备份：%s\n' "$rc_backup"
printf '执行 exec zsh 生效（当前终端不会自动切换）。\n'
