# 更新日志

## [2026-08-16] 当前版本

### 新增
- PWA 通用客户端
  - 支持 iPhone / 鸿蒙 / 其他平台
  - 支持裸域名自动发现隧道
  - 支持深色 / 浅色切换
  - 密码仅保存在页面内存中
- 使用边界与拓展说明 `docs/BOUNDARIES.md`
- PWA 添加到主屏幕教程 `docs/PWA-INSTALL.md`
- 极简部署教程 `docs/QUICKSTART.md`

### 改进
- Android 图标改为黑白风格（黑底 + 白气泡 + DSH 黑鲸鱼）
- Android 顶部栏 / 状态栏黑白化
- 设置弹窗隐私脱敏，不再预填私人信息
- 公开仓库示例域名脱敏
- CI 每次构建成功自动发布 GitHub Release
- Release APK 使用带版本号文件名，避免下载缓存旧图标

### 移除
- 原生 iOS / 鸿蒙工程（改为 PWA 跨平台方案）
- 旧的 HANDOFF / AGENT-START 文档（内容合并入 MAINTENANCE.md）

### 修复
- PWA 填裸域名 404 问题（自动发现隧道）
- PWA Service Worker 旧缓存问题（导航优先网络）
- PWA 泄露真实固定域名问题
- 鸿蒙 ohpm 依赖不可用问题（已移除相关工程）
