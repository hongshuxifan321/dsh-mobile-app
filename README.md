# DSH Remote —— Android 手机端壳应用

DeepSeek Harness 的手机客户端：全屏 WebView 加载你自己电脑上 DSH 的 `/mobile` 界面。
**通用客户端**：任何人下载后，填自己的服务器地址和账号密码即可连接自己的 DSH，
不经过浏览器、不输入域名、密码自动携带。

> 服务器端需要部署 [dsh-plugin-mobile-remote](https://github.com/hongshuxifan321/dsh-mobile-app)（含 `/mobile` 界面 + 认证代理 + 隧道脚本），见 [DEPLOY.md](./DEPLOY.md)。

## PWA 通用客户端（iPhone / 鸿蒙 / 其他平台）

除了 Android APK，本仓库还提供一个 **PWA 通用客户端**，适用于 iPhone、鸿蒙等无法直接安装 APK 的平台。

- PWA 地址：<https://hongshuxifan321.github.io/dsh-mobile-app/pwa/>
- 用户打开后填写自己的 DSH 服务器地址 / 用户名 / 密码即可连接
- 支持裸域名自动发现隧道（如 `your-domain.de5.net`）
- 支持深色 / 浅色切换
- 密码仅保存在当前页面内存中，不持久化
- 详细说明见 [`pwa/README.md`](./pwa/README.md)


## 原理

```
DSH Remote (Android WebView)
   │  (自动携带 Basic Auth 凭证)
   ▼
https://<你的固定域名>/mobile   ← 你电脑上的 mobile-remote 认证代理
   │
   ▼
127.0.0.1:3080  DSH web
```

- 支持两种地址：**固定域名**（如 `your-domain.de5.net`，App 自动通过 DNS 发现当前隧道）或
  **完整地址**（如 `https://xxx.trycloudflare.com/mobile`）
- WebView 原生支持 WebSocket → 审批弹窗、实时事件在手机端完全可用
- 账号密码保存在手机本地设置，只填一次；**密码经 Android Keystore（系统安全硬件）加密存储**，
  旧版明文密码首次启动自动迁移，升级无感

## 构建（GitHub Actions 在线构建，本机零安装）

1. Fork 本仓库（或自行推送一份），打开 **Actions** 页 → 手动运行 `Build APK` 工作流
   （约 3~5 分钟），构建完成后在该次运行的 **Summary** 页下载 **dsh-mobile-apk** 工件里的
   `app-release.apk`。
2. APK 传到手机安装（允许"安装未知来源应用"）。
3. （可选）`workflow_dispatch` 构建会自动发布到 Releases 页，方便分发。

## 使用

1. 手机上打开 App → 首次启动自动弹出设置；
2. **服务器地址**填你自己的固定域名（如 `your-domain.de5.net`，自动发现模式），或完整地址
   `https://xxx.trycloudflare.com/mobile`（**仅支持 https**，明文 http 会泄露密码）；
   **用户名 / 密码**：你部署 mobile-remote 插件时配置的凭证——默认用户名为 `dsh`，
   密码在服务器上 `~/.dsh/mobile-remote.auth`（自动生成）；也可在 `cordis.patch.yml`
   的 `web-runtime` config 下显式配置 `user` / `password` 自定义（见 DEPLOY.md）；
3. 保存即连接，之后打开 App 直接进入 DSH 聊天界面。
4. 服务器未启动时 App 会显示"连接失败"——先在服务器电脑上运行
   `server/tools/start-dsh.ps1`。

## 注意

- 连接走 HTTPS 隧道；请勿把你的服务器密码提交到公开仓库；
- **签名**：Fork 自行构建的 APK 每次构建签名不同（CI 每次生成新 keystore），
  **升级需先卸载旧版**（会清除本地保存的地址/凭证，重装后重填一次）；
  本仓库 Actions 手动运行（workflow_dispatch）会自动发布到 Releases，请以 Release 版为准；
- DSH 预览版的远程限制：远程浏览器（隧道域名）下「插件配置卡片」「打开配置文件」按钮
  默认不渲染（官方把远程 settings 降级为进程内模式）。`server/tools/start-dsh.ps1`
  已内置自动检查/重打补丁（幂等，DSH 升级后只需重启脚本）；手动解除可运行
  `server/tools/apply-isloopback-patch.ps1`（重启 `dsh web` 生效）。

## 本地构建（可选）

装 Android Studio 后直接 Open 本目录即可构建；或命令行：

```bash
gradle assembleDebug   # 输出 app/build/outputs/apk/debug/app-debug.apk
```

## 文档导航

| 文档 | 内容 |
|---|---|
| [README.md](./README.md) | 项目总览 |
| [DEPLOY.md](./DEPLOY.md) | 完整部署指南 |
| [docs/QUICKSTART.md](./docs/QUICKSTART.md) | 极简部署教程 |
| [docs/PWA-INSTALL.md](./docs/PWA-INSTALL.md) | 把 PWA 添加到主屏幕 |
| [docs/BOUNDARIES.md](./docs/BOUNDARIES.md) | 使用边界与拓展方向 |
| [CHANGELOG.md](./CHANGELOG.md) | 更新日志 |
| [LICENSE](./LICENSE) | MIT 许可证 |

## 使用边界与拓展

当前版本的局限、拓展方向、开发者说明，见：

- [docs/BOUNDARIES.md](./docs/BOUNDARIES.md)
