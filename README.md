# fff-bira

**fff-bira v4 Nord Edition** 是基于 [Oh My Zsh Bira](https://github.com/ohmyzsh/ohmyzsh/blob/master/themes/bira.zsh-theme) 的多设备类型识别主题。

## 在线安装 / 升级

需要预先安装 Zsh、Oh My Zsh 和 curl，使用目标账户执行（不要随意添加 `sudo`）。

```bash
curl -fsSL https://raw.githubusercontent.com/FAYOO777/fff-bira/main/install.sh | bash -s -- pve
```

最后一个参数用于选择设备类型：

| 参数 | 机器类型 |
|---|---|
| `pve` | PVE 宿主机 |
| `cvm` | 云服务器 |
| `vm` | PVE 内部虚拟机 |
| `phy` | 实体机 |

安装后执行：

```bash
exec zsh
```

首次安装时，建议先下载并检查安装脚本内容，再执行。

## 主题设计

| 元素 | Nord HEX |
|---|---|
| `[PVE]` | `#D08770` 柔橙 |
| `[CVM]` | `#88C0D0` 冰蓝 |
| `[VM]` | `#EBCB8B` 柔黄 |
| `[PHY]` | `#B48EAD` 灰紫 |
| root 用户名、`●` | `#BF616A` 柔红 |
| 普通用户名、`○` | `#A3BE8C` 柔绿 |
| 主机名与路径 | `#D8DEE9` |
| 结构与分隔符 | `#B9BEC7` |
| 横向细线 | `#626772` |
| 右侧日期和时间 | `#9096A0`（`MM-DD HH:MM`） |

预期布局：

```text
╭─[PVE] root@PVE-X99 ~ ─────────────────────── 11-03 10:25
╰─●
```

保留 Bira 的 Git/Hg、Ruby 和虚拟环境信息。非零退出码在右侧出现。窗口变窄时缩短目录，必要时隐藏附加信息或时间，以避免折行。

## 安装行为和回退

- 主题保存为 `${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/fff-bira.zsh-theme`。
- 在当前用户的 `~/.zshrc` 中设置 `ZSH_THEME="fff-bira"` 和 `FFF_BIRA_ROLE="pve"`（依实际类型调整）。
- 修改前备份 `~/.zshrc`，替换已有主题文件前也备份。
- 支持重复执行安装命令升级，也支持从原 `fayoo-bira` 迁移；旧主题文件不会被删除。
- 不安装 Oh My Zsh、不修改主机名、不修改默认登录 Shell。
- 还原时，使用安装输出中的 `~/.zshrc.bak.*` 备份；如需还原主题文件，使用对应 `fff-bira.zsh-theme.bak.*`。

## 许可证

MIT License。本项目基于 Oh My Zsh 原版 Bira 主题，原项目及贡献者同样受 MIT 许可保护，具体请参阅 [Oh My Zsh LICENSE](https://github.com/ohmyzsh/ohmyzsh/blob/master/LICENSE.txt)。
