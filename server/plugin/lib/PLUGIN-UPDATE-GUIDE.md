# dsh-mobile-remote 插件 · 手机端适配「更新后重对齐指南」

> 用途：每当 **dsh（`@deepseek-ai/dsh`）或 mobile-remote 插件更新**后，手机端适配可能
> 失效/丢失。把本文件 + 更新后的 dsh 源码路径交给 AI，让它按本指南核对并修复。
> 适用 dsh：2026-08 的 `dsh-client-ui-layout / -sidebar / -conversation / -session-log-export`。

---

## 1. 这是什么

本插件的移动端适配 = **两个文件的注入层改动**，不触碰 dsh 主程序：

| 文件 | 作用 | 改动来源 |
|------|------|---------|
| `server/plugin/lib/mobile-inject.css` | 手机视口（`@media (max-width:640px)`）下重构官方 UI 布局 | 手写规则 |
| `server/plugin/lib/proxy.js` | 向页面 `</head>` 注入 CSS + 一小段 JS（52px 工具列开关按钮） | 手写函数 |

**三处必须保持一致**（更新/重装后重新对齐）：
1. 仓库源：`D:\My-Projects\dsh-mobile-app\server\plugin\lib\`
2. pnpm 源：`D:\dsh-plugin-env\plugin\lib\`
3. 安装目录：`C:\Users\yousa\.dsh\profiles\web\node_modules\dsh-plugin-mobile-remote\lib\`

---

## 2. 所有改动画点 + 依赖的 dsh 语义 class

> 原则：CSS 选择器都用 `[class$="_xxx"]`（按 class 语义后缀匹配，抗 CSS Modules 哈希变化）。
> 更新后**逐个核对这些语义后缀在官方源码里是否仍存在**。下表 = 唯一可靠依据。

| # | 功能（CSS 段） | 依赖的 dsh class（语义后缀） | 出处包（官方 .module.css 前缀） |
|---|---|---|---|
| 1 | **52px 工具列独立收起/展开开关**（3c2） | `_frame`、`_sidebarCol`、`_centerCol`、`_detailsCol`；内部 `_root`、`_collapsed` | `dsh-client-ui-layout`（pI_x6G_）、`dsh-client-ui-sidebar`（hHd-Xa_） |
| 2 | 顶栏去掉安全区留白（8） | `_topbar`、`_headerRow`、`_conversationHeader` ⚠️旧命名，可能已失效 | 新一代由 `_header`（wSkVaW_）承担 |
| 3 | 隐藏 Session log 按钮（8b） | `_sessionLogButton` | `dsh-session-log-export`（nL4_yW_） |
| 4 | 隐藏会话描述文本（8b） | `_label` ⚠️**泛化匹配**，见风险#1 | 多处 |
| 5 | 隐藏当前会话名字（8c） | `_crumbCurrent`（面包屑最后一项，disabled） | `dsh-client-ui-conversation`（wSkVaW_） |
| 6 | 顶栏视图标签 tab 精简（8d） | `_tabs`、`_tab`、`_tabActive` | `dsh-client-ui-conversation`（wSkVaW_） |
| 7 | 顶栏底部横线加粗（8e） | `_header`（含 `_tabs` 的那个） | `dsh-client-ui-conversation` |
| 8 | 对话底部输入框压缩（4d） | `_composerSeat`、`_row`、`_tools`、`_modes`、`_trailing`、`_primary`、`_card`、`_composerStack` | `dsh-client-ui-conversation`（wSkVaW_/uV2eYG_） |
| — | 注：输入统计条横向滚动规则**已删除**（会误裁权限菜单 `_root`） | 不要恢复 `[class$="_composerSeat"] [class$="_root"] { overflow-… }` | — |

**proxy.js 注入的东西**（重装插件后重新确认存在即可，不易受 dsh 升级影响）：
- `<script data-dsh-rail-toggle>`：动态加 `.dsh-rail-toggle` 按钮，切 `body.dsh-rail-visible` 类
- 按钮定位由 CSS `.dsh-rail-toggle`（fixed 左上角；露出态左移 `60px`）决定

---

## 3. 关键机制（剪漏必踩的坑）—— 必须保留的 3 条核心逻辑

1. **CSS Grid 自动放置陷阱（最重要）**：`frame` 是 3 列 grid，子项按 DOM 顺序自动放置
   `sidebarCol→centerCol→detailsCol`。**一旦 `_sidebarCol` 脱离 grid（fixed/absolute 或
   display:none），centerCol(对话页)会被塞进 0 宽轨道、detailsCol(详情面板)被塞进满宽轨道
   → 对话页消失 + 白底"点击消息流中的工具行查看详情"全屏覆盖**。
   正确做法（3c2 当前实现）：
   - frame 轨道恒覆盖 `grid-template-columns: 0 minmax(0,1fr) 0`
   - `_sidebarCol` **永远保持 grid 子项**：`position:relative + width:52px + z-index:60`
   - 收起用 `visibility:hidden`（仍在 grid 占位，自动放置不乱）；露出 `visibility:visible`
   - ❌ 禁止改回：fixed / absolute / transform / display:none 控制侧边栏显隐

2. **280px 抽屉（鱼按钮）**：由 3c 规则 `[class$="_sidebarCol"]:has([class$="_root"]:not([class$="_collapsed"]))`
   接管为 fixed 悬浮 280px，并有 `body:has(...) [class$="_centerCol"] { grid-column: 1/-1 }`
   ——依赖 `_root`/`_collapsed` 类语义，更新后确认仍存在。

3. **权限菜单不被裁**：官方权限选择器（PermissionSelect）菜单无 `_menu` 类，
   用的是 primitives `Menu`；其包裹 `_root` 在 `_composerSeat` 内。**不要再给
   `_composerSeat` 内的 `_root` 加任何 overflow 裁剪**（历史 bug 根因）。

---

## 4. 风险清单（升级后重点排查）

| 风险 | 说明 | 对策 |
|------|------|------|
| #1 `_label` 泛化 | `[class$="_label"] { display:none }` 是裸后缀全局匹配，dsh 若新增其它 `_label` 会被误隐藏 | 升级后如发现"有元素不见了"，改收窄为 `[class$="_headerActions"] [class$="_label"]` |
| #2 顶栏旧命名失效 | `_topbar/_headerRow/_conversationHeader` 可能已不再由官方输出 | 顶栏规则改挂在 `_header`（wSkVaW_header）上 |
| #3 frame 轨道覆盖 | `grid-template-columns` 强制 0，官方拖动手柄调宽会失效 | 手机端可接受；仅提醒 |
| #4 统计条无横向滚动 | 因权限菜单已删除该规则 | 有意取舍，别恢复 |

---

## 5. 更新后怎么核对这些 class（给 AI/你自己的步骤）

**方法 A（源码 grep，最准）**：在 dsh 安装目录搜语义后缀是否仍存在
```
搜索目录：C:\Users\yousa\AppData\Roaming\npm\node_modules\@deepseek-ai\dsh\node_modules\@deepseek-ai\
搜：dsh-client-ui-layout / -sidebar / -conversation / -session-log-export 的 client.js
关键字：sidebarCol、collapsed、frame、crumbCurrent、sessionLogButton、composerSeat、tabs
（这些词若在编译后 client.js 里还能 grep 到 = 选择器仍会命中）
```

**方法 B（浏览器 DevTools）**：手机端打开页面 → 检查实际元素 class，看语义后缀是否还在。

---

## 6. 更新后「恢复/重对齐」清单

1. **若插件重装覆盖了安装目录**（优化消失）：从仓库重新复制两份文件到三处 →
   ```
   Copy-Item 仓库\mobile-inject.css  pnpm源\   -Force
   Copy-Item 仓库\proxy.js          pnpm源\   -Force
   Copy-Item 仓库\mobile-inject.css 安装目录\ -Force
   Copy-Item 仓库\proxy.js         安装目录\ -Force
   ```
   然后由用户自行重启 dsh web。

2. **若 dsh 升级导致 class 失效**（规则静默不生效）：
   - 用第 5 节方法查新 class → 把 mobile-inject.css 里失效的选择器改成新语义后缀
   - 重点：第 2 节表 #1（_frame/_sidebarCol）、#5（_crumbCurrent）、#6（_tabs）、#8（_composerSeat）

3. **手动验证**（手机刷新后逐项确认）：
   - 顶栏无安全区留白、无会话名、无 Session log、tab 紧凑、横线 3px
   - 输入框矮且工具全在；发送按钮 44px
   - 左侧 52px 工具列：默认收起(左上角小钮) → 点开悬浮列(页面不动、不白屏) → 再点收起
   - 点权限选择器：Workspace/Full access/Read only 三个选项完整可见

---

## 7. 给 AI 的调用口令（直接贴下面这段即可）

> 请按 D:\My-Projects\dsh-mobile-app\server\plugin\lib\PLUGIN-UPDATE-GUIDE.md 第 2、3 节的
> 语义 class 清单和 3 条核心机制，核对 dsh 更新后的源码
> （C:\Users\yousa\AppData\Roaming\npm\node_modules\@deepseek-ai\dsh\node_modules\@deepseek-ai\ 下
> dsh-client-ui-layout/-sidebar/-conversation/-session-log-export 的 client.js），
> 检查 mobile-inject.css 中每个 `[class$="_xxx"]` 选择器是否仍能命中；失效的改成新版语义后缀；
> 且务必保留：①侧边栏用 relative+visibility 悬浮（防 grid 自动放置白屏）②`_frame` 轨道恒 0
> ③不给 `_composerSeat` 内 `_root` 加 overflow 裁剪。不要改 proxy.js 的注入逻辑。改完把
> 结果同步到 pnpm 源( D:\dsh-plugin-env\plugin\lib )和安装目录( C:\Users\yousa\.dsh\profiles\web\
> node_modules\dsh-plugin-mobile-remote\lib )，保持一致；不要运行任何重启脚本，由用户自行重启。

---

## 8. 本指南自身也可能过期

若 dsh 未来把 `dsh-client-ui-*` 拆包/改名，第 2 节的"出处包"会变。更新指南时同步核对一次即可。
