# DJI Mic Mini for Vibe Coding

**本项目必须配合 macOS 版豆包输入法使用。** 用 DJI Mic Mini 发射器的连接键控制豆包语音录入，语音识别和文字输入由豆包输入法完成。

## 使用前必设：豆包免按模式 + 右侧 Option（⌥）

> **请先在豆包输入法中，把语音输入设为“免按模式”（无需一直按住），并将该模式的快捷键设为“右侧 Option（⌥）”。这是当前版本正常工作的必要设置。**

1. 安装并启用 macOS 版豆包输入法，打开其语音输入设置。
2. 选择 **免按模式**：按一次开始，再按一次结束，无需长按。
3. 将该模式的快捷键设为 **右侧 Option（⌥）**，也就是键盘空格键右边的 Option 键。
4. 先在输入框里手动单击右侧 Option，确认豆包开始录入；再单击一次，确认录入结束。

本工具默认模拟的是 **右侧 Option**，不会自动修改豆包的设置。如果豆包仍使用 Fn、左侧 Option 或长按录入模式，请先按上面的步骤修改，否则麦克风按钮无法按预期控制开始和停止。

## 麦克风按钮操作

- 单击连接键：开始录入。
- 再单击连接键：停止录入。
- 停止后固定等待 1 秒：模拟按下 Enter。

Enter 在聊天工具里通常表示发送，在其他软件里可能表示换行或确认，具体由当前软件决定。这里的“停止”会结束本次录入，并不是暂停后继续同一段录音。

这是独立的 Swift 菜单栏工具，不基于 Handy，不安装 Whisper，也不自行录音或转写。语音识别由已安装的豆包输入法完成。本项目与 DJI、豆包没有官方关联。

## 使用条件

- macOS 13 或更高版本；目前只在 Apple Silicon、macOS 26.6 上实测。
- 已安装豆包输入法，将语音输入设为“免按模式”，快捷键设为“右侧 Option”。目前实测豆包输入法 1.0.2。
- 发射器通过接收器连接电脑，系统选择接收器为输入设备。
- 接收器 USB 标识为 VendorID `0x2ca3`、ProductID `0x4011`，连接键会上报 Consumer Volume Increment。
- 安装 Xcode Command Line Tools（`xcode-select --install`），用于编译 Swift。

只通过蓝牙连接发射器的方式未能提供所需按钮事件，不在支持范围内。不同型号、固件的按钮行为需要实际验证。

## 安装

先打开终端，下载源码并进入项目目录：

```sh
git clone https://github.com/sumai-1998/DJI-mic-mini-for-Vibe-Coding.git
cd DJI-mic-mini-for-Vibe-Coding
./scripts/install.sh
```

也可以在 [GitHub 仓库](https://github.com/sumai-1998/DJI-mic-mini-for-Vibe-Coding) 点击 **Code → Download ZIP**，解压后在终端进入解压目录，再执行 `./scripts/install.sh`。首次安装编译工具可运行 `xcode-select --install`，按系统提示完成后再安装本项目。

项目名称是 DJI Mic Mini for Vibe Coding；安装后的 App 和辅助功能权限列表名称仍为 **DJI Doubao Controller**。

脚本编译并验证 App，安装到 `~/Applications/DJI Doubao Controller.app`，设置当前用户登录启动。旧实验版的重映射辅助脚本会被移除。

在“系统设置 → 隐私与安全性 → 辅助功能”中允许 **DJI Doubao Controller**。菜单栏显示 `Mic·就绪` 后可使用。无需管理员权限。

本地构建使用临时签名。更新程序后，macOS 可能要求重新授权。如果开关已开启但仍显示待授权，可先关闭 App，执行以下命令，再打开 App 并重新授权：

```sh
tccutil reset Accessibility local.dji-doubao-controller
open "$HOME/Applications/DJI Doubao Controller.app"
```

辅助功能授权必须由用户在系统设置中完成。

## 使用与边界

将光标放在输入框，单击发射器连接键开始说话，再单击停止。停止后 1 秒会发送 Enter；程序不会等待或判断豆包是否已经完成转写，因此转写慢时可能先发送 Enter。

为了减少误发送，等待期间切换到其他应用、点击鼠标、手动按 Enter/Esc，或者重新开始录入，会撤销上一次待发送的 Enter。同一应用内只靠键盘切换输入框不一定能检测到。

菜单栏提供“重置录音状态”，用于外部操作豆包导致状态不同步的情况。该操作只重置本工具，不直接控制豆包的录音状态。

不包含电源键取消、双击/三击取消或降噪状态监听功能。退出 App 后，连接键恢复为右 Option 的基本映射，此时没有自动 Enter。接收器重新插入后，运行中的 App 最多约 15 秒重新应用映射。

## 构建与检查

```sh
./scripts/build.sh
```

产物位于 `build/DJI Doubao Controller.app`。构建时运行状态机自测，覆盖开始/停止、发送资格、切换应用、新录入撤销旧发送和重置。自测不会模拟真实硬件，也不能代替豆包与输入框的实际验证。

脚本生成当前 Mac 架构的 App，未制作通用二进制，也未进行 Apple 公证。源码是推荐的分享方式。

## 实现

`Sources/main.swift` 使用 `hidutil` 对指定 VID/PID 的接收器做映射，把音量增加事件映射为 F18，再用 macOS 事件监听将其转换为右 Option。第二次单击后调度一次 Enter。注入事件带有标记，避免被自身重复处理。

App 运行时会占用 F18；相同 VID/PID 设备的现有按键映射会被覆盖。卸载脚本清空这些设备的映射。

运行日志及状态保存于 `~/.local/share/dji-doubao-controller/`，仅包含操作事件，不记录语音、转写文字或剪贴板。本工具本身不发起网络请求；豆包的处理方式由豆包决定。这些运行文件不进入源码包。

## 卸载

```sh
./scripts/uninstall.sh
```

移除 App、登录启动项及设备映射。诊断日志保留在上面的用户目录，可自行删除。

## 项目文件

- `Sources/main.swift`：控制逻辑、菜单栏、状态机及自测。
- `Info.plist`：App 信息。
- `scripts/build.sh`：构建、自测和临时签名。
- `scripts/install.sh`：安装并设置登录启动。
- `scripts/uninstall.sh`：卸载。

## 发布

项目地址：https://github.com/sumai-1998/DJI-mic-mini-for-Vibe-Coding

项目采用 [MIT 许可证](LICENSE)。欢迎通过 Issue 反馈问题，或提交 Pull Request。不要提交 `build/`、`dist/` 或运行日志。
