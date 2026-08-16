# DSH Remote — HarmonyOS 客户端（工程骨架）

> 使用 DevEco Studio 6.1.1 打开本目录构建。
> 当前是基础骨架，使用 ArkWeb 加载 DSH 网页。

## 环境要求

- DevEco Studio 6.1.1 Release 或更新
- HarmonyOS SDK（首次启动 DevEco 会自动安装）
- 华为账号（用于自动签名）

## 操作步骤

1. 打开 DevEco Studio
   - 菜单：`File -> Open`
   - 如果 DevEco 因路径含中文/空格无法打开，请打开这个纯 ASCII 工作副本：
     ```
     C:\dsh-remote-harmonyos
     ```
   - 注意：`C:\dsh-remote-harmonyos` 是独立副本，不是快捷方式；在 DevEco 里改完后可复制回本目录。
   - 或者选择原始目录：
     ```
     C:\Users\<用户名>\Desktop\协作项目\DSH remote\app-android\harmonyos
     ```

2. 等待工程同步完成
   - DevEco 会自动下载/同步依赖
   - 如果提示 SDK 版本不匹配，按提示安装对应 HarmonyOS SDK

3. 配置签名（自动签名）
   - 菜单：`File -> Project Structure -> Signing Configs`
   - 勾选 `Automatically generate signature`
   - 登录华为账号
   - DevEco 会自动生成调试证书和 Profile

4. 修改服务器地址
   - 打开：
     ```
     entry/src/main/ets/pages/Index.ets
     ```
   - 修改 `url` 字段为你的实际地址，例如：
     ```ts
     @State url: string = 'https://your-domain.de5.net/mobile';
     ```

5. 构建
   - 菜单：`Build -> Build Hap(s) / APP(s) -> Build Hap(s)`
   - 产物一般在：
     ```
     entry/build/default/outputs/default/entry-default-unsigned.hap
     ```
     或签名后的：
     ```
     entry/build/default/outputs/default/entry-default-signed.hap
     ```

6. 运行到真机（可选）
   - 手机开启“开发者模式”和“USB 调试”
   - USB 连接电脑
   - DevEco 点击 Run，选择你的设备

## 后续待完善

- 设置页（服务器地址 / 用户名 / 密码）
- 凭证安全存储
- Basic Auth / Cookie 处理
- 返回键与导航
- 黑白主题图标
