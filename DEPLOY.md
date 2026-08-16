# 部署你自己的 DSH 手机端（服务端指南）

本指南面向**想要拥有自己的 DSH 手机端**的人：照着做，你就能获得
「手机 App → 固定域名 → 你自己的电脑 → DSH」的完整链路。
费用：0 元（免费域名 + 免费隧道）。预计耗时：30~60 分钟。

---

## 一、前置环境（Windows 电脑）

1. **Node.js 18+**：https://nodejs.org 下载安装；
2. **DSH**：命令行执行 `npm i -g @deepseek-ai/dsh`；
3. **cloudflared**：`winget install cloudflare.cloudflared`（隧道客户端）。

## 二、获取本项目文件

需要两份东西：本仓库的 `app/`（Android App 源码，GitHub Actions 自动构建 APK）
和服务端组件（`server/plugin/` 插件 + `server/tools/` 脚本）。

```
本仓库根目录
├── app/                    # 手机 App 源码
├── server/
│   ├── plugin/             # DSH 插件：认证代理 + /mobile 手机界面
│   └── tools/              # 启动脚本 + 配置模板
└── DEPLOY.md               # 本指南
```

## 三、注册免费域名（DNSHE）

1. 打开 https://www.dnshe.com 注册账号（邮箱即可）；
2. 进入 **Domain Hub**，注册一个子域名，如 `your-domain.de5.net`（后缀选 `.de5.net` 等）；
3. 进入 **API 管理**，创建 API 密钥，得到 `API Key`（`cfsd_` 开头）和 `API Secret`。

## 四、配置

1. 复制 `server/tools/dsh-config.example.txt` 为 `server/tools/dsh-config.txt`，填入：
   - `DOMAIN`：你的子域名（如 `your-domain.de5.net`）
   - `SUBDOMAIN_ID`：DNSHE 控制台里该子域名的 ID
   - `DNSHE_KEY` / `DNSHE_SECRET`：上一步的 API 密钥
2. 配置登录凭证（手机 App 登录时要用，请记好；不要把密码提交到公开仓库），二选一：
   - **默认凭证**：不配置任何东西。插件首次启动自动生成密码并写入
     `~/.dsh/mobile-remote.auth`（用户名固定 `dsh`），用记事本打开该文件查看密码；
   - **自定义凭证（推荐，凭证只存在该文件）**：编辑 `~/.dsh/mobile-remote.auth`，
     写成两行（⚠️该文件不在 git，是凭证唯一明文位置，勿提交）：
     ```
     user=your-name
     password=your-strong-password
     ```
     插件启动时读取；若文件只有一行则视为旧格式纯密码（用户名回落为 `dsh`）。

## 五、安装插件到 DSH

1. 把 `server/plugin/` 目录**整体**复制到电脑某处，如 `C:\dsh-plugin-dev`
   （即 `C:\dsh-plugin-dev\package.json` 必须存在）；
2. 在命令行执行：

   ```
   dsh plugin --profile web add file:C:\dsh-plugin-dev
   ```

3. 首次启动会下载插件依赖；之后启动方式不变：

   ```
   dsh web
   ```

## 六、一键启动（以后每天就这一步）

双击 `server/tools/start-dsh.ps1`。它自动完成：

- 启动 `dsh web`（如未运行）并**自动检查/重打 isLoopback 补丁**（DSH 升级后无需手动）；
- 启动 cloudflared 快速隧道；
- 隧道域名一变，自动通过 DNSHE API 把你的固定域名 `your-domain.de5.net`
  指向最新隧道 → **手机永远访问固定域名，无需改配置**；
- **dsh web 崩溃自愈**：每 ~10 秒巡检一次，崩溃自动重启；
- 当前手机访问地址写入 `tools/last-phone-url.txt`，随时可查；
- **DNSHE 同步用 Invoke-RestMethod**（PS5.1 把含引号的 JSON 传给 curl.exe 会吞引号
  导致 `invalid type`——勿改回 curl 方式）。

> 首次运行时，脚本需要一点时间等隧道就绪；看到
> `PHONE URL: https://your-domain.de5.net/mobile` 即成功。
> **（可选）开机自启 + 守护**：
> - 运行一次 `server/tools/install-autostart.ps1`——下次登录自动启动（隐藏窗口）；
> - 注册计划任务 `DSH-Remote-Watchdog`（每 5 分钟跑 `server/tools/dsh-remote-watchdog.ps1`，
>   start-dsh.ps1 不在则拉起；全杀进程实测 60s 内自动恢复全链路）。
>   两条都做 = 进程被外部杀掉也会自动复活。

## 七、PWA 通用客户端（iPhone / 鸿蒙 / 其他平台）

除了 Android APK，本仓库还提供 PWA 通用客户端：

- 地址：<https://hongshuxifan321.github.io/dsh-mobile-app/pwa/>
- 用户打开后填写自己的 DSH 服务器地址 / 用户名 / 密码即可连接
- 支持裸域名自动发现隧道（如 `your-domain.de5.net`）
- 详细说明见 [`pwa/README.md`](./pwa/README.md)

## 八、Android 手机端

1. 构建 APK（见 `README.md`，GitHub Actions 自动构建）；
2. 手机安装 APK；
3. 打开 App，设置里填：
   - 服务器地址：`your-domain.de5.net`（自动发现模式）或完整地址 `https://xxx.trycloudflare.com/mobile`
   - 用户名 / 密码：你在 `cordis.patch.yml` 里设置的凭证
4. 保存即连。此后打开 App 直接进入 DSH，审批弹窗、模型选择、深色模式全可用。

## 安全须知

- **密码即边界**：插件认证代理是唯一认证（默认凭证见 `~/.dsh/mobile-remote.auth`，
  或 `cordis.patch.yml` 自定义 `user/password`），请设强密码，**不要**提交到公开仓库；
- **`server/tools/dsh-config.txt`** 含 DNSHE API 密钥，已在 `.gitignore` 中排除，勿提交；
- DSH 预览版的远程限制：远程浏览器（隧道域名）下「插件配置卡片」「打开配置文件」按钮
  默认不渲染（官方把远程 settings 降级为进程内模式）。运行一次
  `powershell -ExecutionPolicy Bypass -File server/tools/apply-isloopback-patch.ps1`
  即可解除（重启 `dsh web` 生效；**DSH 升级后需重跑**）；
- App 端仅接受 `https://` 地址（明文 http 会泄露 Basic Auth 密码）；
- 免费隧道带宽有限，打开超大会话会稍慢，属正常现象。

## 故障排查

| 现象 | 处理 |
|---|---|
| 手机提示"连接失败" | 电脑上 `dsh web` 是否在运行？`start-dsh.ps1` 是否打印了 PHONE URL？ |
| 域名打不开 | 等 1~2 分钟 DNS 生效；或重启 `start-dsh.ps1` 强制同步 |
| App 自动发现失败 | 检查 `dsh-config.txt` 的 `DOMAIN` 是否正确；改填完整地址临时使用 |
| 发送消息无响应 | 隧道断开，重启 `start-dsh.ps1`（会自动重连） |
