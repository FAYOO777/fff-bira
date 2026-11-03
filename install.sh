#!/usr/bin/env bash
# fff-bira v4 installer/updater. Usage: bash install.sh cvm|pve|vm|phy
set -euo pipefail

role="${1:-}"
label="${2:-}"
(( $# <= 2 )) || { printf "用法: bash install.sh [cvm|pve|vm|phy] [标签]\n" >&2; exit 2; }
default_label() { case "$1" in cvm) printf CVM;; pve) printf PVE;; vm) printf VM;; phy) printf PHY;; esac; }
valid_label() {
  local value="$1" char ord i
  [[ -n "$value" && ${#value} -le 24 ]] || return 1
  for (( i=0; i<${#value}; i++ )); do
    char="${value:i:1}"
    case "$char" in
      [a-zA-Z0-9._\ -]) ;;
      *) printf -v ord "%d" "'$char"; (( ord > 127 )) || return 1 ;;
    esac
  done
}
old_role=""
old_label=""
if [[ -f "$HOME/.zshrc" ]]; then
  old_role="$(sed -nE 's/^[[:space:]]*FFF_BIRA_ROLE=["\x27]?([a-z]+)["\x27]?[[:space:]]*$/\1/p' "$HOME/.zshrc" | tail -n1)"
  old_label="$(sed -nE 's/^[[:space:]]*FFF_BIRA_LABEL=["\x27]([^"\x27]*)["\x27][[:space:]]*$/\1/p' "$HOME/.zshrc" | tail -n1)"
fi
if [[ -z "$role" ]]; then
  { exec 3</dev/tty; } 2>/dev/null || { printf "未检测到交互终端，请指定类型参数。\n" >&2; exit 1; }
  printf "\nfff-bira · Nord Edition 配置向导\n类型决定颜色；标签可自定义。\n"
  printf "  1) PVE 宿主机  #D08770\n  2) CVM 云服务器 #88C0D0\n  3) VM 虚拟机 #EBCB8B\n  4) PHY 实体机 #B48EAD\n"
  case "$old_role" in pve) suggestion=1;; cvm) suggestion=2;; vm) suggestion=3;; phy) suggestion=4;; *) suggestion=1;; esac
  while :; do
    printf "请选择类型 [1-4，默认 %s]: " "$suggestion"
    IFS= read -r -u 3 choice || exit 1
    case "${choice:-$suggestion}" in
      1) role=pve; break;; 2) role=cvm; break;; 3) role=vm; break;; 4) role=phy; break;;
      *) printf "请输入 1-4。\n";;
    esac
  done
  default="$(default_label "$role")"
  if [[ "$old_role" == "$role" ]] && valid_label "$old_label"; then default="$old_label"; fi
  while :; do
    printf "输入标签（显示为 [标签]，默认 %s）: " "$default"
    IFS= read -r -u 3 choice || exit 1
    label="${choice:-$default}"
    valid_label "$label" && break
    printf "标签限 1-24 字符，支持文字、数字、空格、点、下划线、连字符。\n"
  done
  exec 3<&-
else
  case "$role" in cvm|pve|vm|phy) ;; *) printf "类型必须为 cvm/pve/vm/phy。\n" >&2; exit 2;; esac
  if [[ -z "$label" ]]; then
    if [[ "$old_role" == "$role" ]] && valid_label "$old_label"; then label="$old_label"; else label="$(default_label "$role")"; fi
  fi
  valid_label "$label" || { printf "无效标签。\n" >&2; exit 2; }
fi

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

awk -v role="$role" -v label="$label" '
  /^[[:space:]]*(export[[:space:]]+)?ZSH_THEME=/ { next }
  /^[[:space:]]*(export[[:space:]]+)?(FAYOO_ROLE|FFF_BIRA_ROLE|FFF_BIRA_LABEL)=/ { next }
  /^[[:space:]]*(source|\.)[[:space:]]+.*oh-my-zsh[.]sh/ {
    print "ZSH_THEME=\"fff-bira\""
    print "FFF_BIRA_ROLE=\"" role "\""
    print "FFF_BIRA_LABEL=\047" label "\047"
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

printf 'fff-bira v4 已安装：%s [%s]\n' "$role" "$label"
printf '配置备份：%s\n' "$rc_backup"
printf '执行 exec zsh 生效（当前终端不会自动切换）。\n'
