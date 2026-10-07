<p align="center">
  <b>Madeira（中文说明）— 把 PC 游戏带到你的 iPhone。</b>
</p>

# Madeira 是什么

Madeira 在 **iPhone（未越狱 / 巨魔 / 越狱均可）** 上运行 Windows PC 游戏，游戏无需修改，跑在一个 iOS App 里。

> [!NOTE]
> Madeira 是活跃研究项目，兼容性和性能因游戏而异。

## 工作原理

| 层 | 作用 |
|---|---|
| **FEX-Emu** | 运行时把游戏的 x86 / x86-64 代码翻译成 ARM64 |
| **Wine** 11.4 | 提供 Windows。为 ARM64EC 构建，Wine 自身原生运行，只有游戏代码被翻译。32 位游戏走 WoW64 |
| **DXMT** | 用 Apple Metal 绘制 Direct3D 9、10 和 11 |
| **madeira-d3d12** | 自研 Direct3D 12 实现，运行时用 Apple Metal Shader Converter 转换 DXIL 着色器 |

## 本 Fork 的改动（iPhone 6s / A9 / iOS 15 支持 + 中文 + CI）

1. **iPhone 6s（A9）与 iOS 15 支持**
   - 所有构建目标（Xcode、FEX、Wine、DXMT、GnuTLS、FFmpeg）的最低系统从 iOS 17/18/26 降到 **15.0**
   - JIT 内存页大小改为**运行时查询**（A9 及更早设备是 4KB 页，A12+ 是 16KB 页）
   - Metal 着色语言版本从 metal3.1（需 iOS 17）降到 **metal2.3**（iOS 15）
   - iOS 16/17 专属的 SwiftUI API（NavigationStack、ContentUnavailableView、ShareLink、onChange 新签名、@Observable 等）全部降级兼容，同一二进制同时跑在新老系统上

2. **原生 JIT（巨魔 / 越狱环境，默认优先）**
   - **越狱**（palera1n 等）：内核允许匿名 RWX 映射，JIT 池直接创建，**无需调试器**，启动更快
   - **巨魔（TrollStore）**：利用 allow-jit entitlement，MAP_JIT 直接可用（A9 等无 W^X 切换的设备）
   - 探测顺序：运行时试 RWX → 试 MAP_JIT → 都不行再走 StikDebug / 内置 StikJIT 调试器流程（新 iOS 侧载用户）
   - JIT 池大小按设备内存自适应：2GB（iPhone 6s）64MB、3-5GB 128MB、6GB+ 256MB

3. **汉化**
   - App 界面（游戏库、设置、JIT、Steam、启动页等 13 个文件 134 处）已改为简体中文
   - Info.plist 权限描述已汉化

4. **GitHub Actions 编译**
   - `.github/workflows/build.yml`：macOS runner 上完整构建 IPA
   - Job 1 构建 LLVM for iOS（DXMT 着色器编译器依赖）并缓存——首次慢，之后秒过
   - Job 2 构建全部组件（GnuTLS、FFmpeg、FEX、Wine、DXMT、D3D12 运行时、Madeira Dock）+ App，ldid 注入 entitlements，打包无签名 IPA
   - 推送到 main 或手动触发即自动构建，IPA 在 Actions 的 Artifacts 下载
   - 巨魔可直接安装无签名 IPA；SideStore 用户用自己的 Apple ID 重签

## 安装

1. 从 [Releases](https://github.com/ssx-computer/Madeira/actions) 或本 Fork 的 Actions 构建 Artifacts 下载 IPA
2. 侧载（SideStore / AltStore / TrollStore / Sideloadly）——**巨魔环境直接装**
3. 打开 Madeira 启用 JIT（巨魔/越狱下自动原生 JIT，无需 StikDebug）
4. 设置里 **JIT** 和 **内存** 显示绿色勾 → **准备就绪**

## 从源码构建

```sh
git clone --recurse-submodules https://github.com/ssx-computer/Madeira.git
```

构建说明见 [`docs/BUILDING.md`](docs/BUILDING.md)（英文）。

## 硬件与兼容性提示（iPhone 6s / A9）

- A9 是双核 2GB 内存设备：能启动的游戏会明显少于新 iPhone，部分游戏需要降低画质
- D3D12 路径依赖 Apple Metal Shader Converter 运行库（对 iOS 26 构建），在 iOS 15 上可能无法加载——D3D9/D3D11 路径（DXMT）不受影响
- 32 位游戏（WoW64）组件为可选项，Actions 构建默认不含

---

原项目：[willfaust/Madeira](https://github.com/willfaust/Madeira)（GPL-3.0-or-later with Madeira Converter Exception）。本 Fork 遵循相同许可证。
