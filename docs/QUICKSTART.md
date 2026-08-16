# DSH Remote 极简部署教程（普通用户版）

> 目标：让一台 Windows 电脑变成你自己的 DSH 远程服务器。
> 完整版见 [DEPLOY.md](../DEPLOY.md)。

## 你需要准备

- 一台 Windows 电脑
- Node.js 18+
- cloudflared

## 第一步：安装 DSH

```bash
npm i -g @deepseek-ai/dsh
```

## 第二步：安装 cloudflared

```bash
winget install cloudflare.cloudflared
```

## 第三步：获取本项目文件

下载 GitHub 仓库：

```
https://github.com/hongshuxifan321/dsh-mobile-app
```

把 `server/` 目录复制到电脑上，例如：

```
C:\dsh-server\
```

## 第四步：配置

1. 复制配置文件：
   ```
   C:\dsh-server\tools\dsh-config.example.txt
   ```
   改名为：
   ```
   C:\dsh-server\tools\dsh-config.txt
   ```
2. 编辑 `dsh-config.txt`，填写你自己的：
   - `DOMAIN`（可选，固定域名）
   - `SUBDOMAIN_ID`
   - `DNSHE_KEY`
   - `DNSHE_SECRET`

> 如果不需要固定域名，可以先跳过 DNSHE 配置，直接使用临时隧道。

## 第五步：启动

双击或运行：

```
C:\dsh-server\tools\start-dsh.ps1
```

启动后查看当前手机访问地址：

```
C:\dsh-server\tools\last-phone-url.txt
```

## 第六步：手机连接

- Android：安装 APK，填写你的服务器地址
- iPhone / 鸿蒙 / 其他：打开 PWA，填写你的服务器地址
- 临时测试：浏览器直接打开隧道 URL

## 常见问题

| 问题 | 处理 |
|---|---|
| 启动报 missing config | 检查 `dsh-config.txt` 是否填写完整 |
| 手机连不上 | 确认电脑开机、联网、start-dsh.ps1 在运行 |
| 域名打不开 | 等 DNS 生效，或重启 start-dsh.ps1 |
