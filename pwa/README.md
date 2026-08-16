# DSH Remote PWA（通用客户端）

这是一个**零后端、零成本**的 PWA：
- 用户打开固定网址
- 填写自己的 DSH 服务器地址 / 用户名 / 密码
- 连接自己的 DSH

## 部署到 GitHub Pages

1. 把本仓库推到 GitHub
2. 仓库 `Settings -> Pages`
3. Source 选择：
   - `Deploy from a branch`
   - Branch: `main`
   - Folder: `/`（或 `/pwa` 如果只发布 PWA）
4. 保存后访问：
   ```
   https://<你的用户名>.github.io/<仓库名>/pwa/
   ```
   例如：
   ```
   https://hongshuxifan321.github.io/dsh-mobile-app/pwa/
   ```

> ✅ 已启用 GitHub Pages，当前可直接访问：
> https://hongshuxifan321.github.io/dsh-mobile-app/pwa/

## 使用

1. 打开 PWA 地址
2. 点“设置”
3. 填：
   - 服务器地址：`https://你的DSH地址/mobile`
   - 用户名 / 密码
4. 保存并连接
5. 如果浏览器弹出登录框，输入用户名/密码即可

## 说明

- 密码仅保存在当前页面内存中，关闭页面后不会持久化，更安全
- 首次连接通过弹窗完成 Basic Auth，浏览器会缓存该域名的登录凭证
- 之后 iframe 内可直接加载 DSH 界面
