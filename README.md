# DJI Mic Mini for Vibe Coding

**大疆 DJI Mic Mini + 接收器，让你不用键盘就能完成 Vibe Coding 中的语音输入与发送。**

**DJI Mic Mini + its receiver: dictate and send prompts for Vibe Coding without touching your keyboard.**

- **按一下连接键：开始语音录入。** / **Press the linking button once to start dictation.**
- **再按一下连接键：停止本次录入。** / **Press it again to stop dictation.**
- **停止后固定等待 1 秒：自动按下 Enter。** / **Automatically press Enter 1 second after stopping.**

硬件只需 DJI Mic Mini 发射器及其接收器，无需额外遥控器。完成首次配置后，将光标放到输入框，即可用麦克风按钮控制录入和发送。

The only microphone hardware you need is a DJI Mic Mini transmitter and its receiver—no extra remote. After initial setup, focus a text field and use the microphone button to dictate and send.

> **必须配合 macOS 版豆包输入法使用：语音输入设为“免按模式”，快捷键设为“右侧 Option（⌥）”。** 本项目负责按键控制，豆包输入法负责语音识别和文字输入。
>
> **Requires Doubao Input Method for macOS: set voice input to “免按模式” (press-to-toggle mode) and bind it to Right Option (⌥).** This app handles button control; Doubao handles speech recognition and text input.

Enter 在聊天或编程工具里可能表示发送、换行或确认，由当前软件决定。“停止”会结束本次录入，并非暂停后继续同一段录音。免键盘指录入与发送这三个操作，不代表软件安装、授权或所有编程操作都无需键盘。

Enter may send, insert a newline, or confirm an action depending on the focused app. Stopping ends the current dictation; it does not pause a resumable recording. Keyboard-free operation refers to starting, stopping, and sending dictation, not initial setup or every coding task.

## 1. 先配置豆包 / Configure Doubao first

1. 安装并启用 **macOS 版豆包输入法**，打开语音输入设置。  
   Install and enable **Doubao Input Method for macOS**, then open its voice-input settings.
2. 选择 **“免按模式”**：按一次开始，再按一次结束，无需一直按住。  
   Choose **“免按模式”**: press once to start and again to stop, without holding the key.
3. 将该模式的快捷键设为 **右侧 Option（⌥）**，即空格键右边的 Option 键。  
   Assign **Right Option (⌥)**, the Option key to the right of the space bar.
4. 在输入框中手动按一次右侧 Option，确认开始录入；再按一次，确认结束。  
   Test it in a text field: press Right Option once to start dictation and again to stop.

**本工具默认模拟右侧 Option，不会自动修改豆包设置。** 如果仍设置为 Fn、左侧 Option 或长按录入模式，请先修改，否则麦克风按钮无法按预期控制录入。

**This app simulates Right Option and does not change Doubao's settings automatically.** Fn, Left Option, or a hold-to-talk configuration will not match the expected start/stop behavior.

## 2. 使用条件 / Requirements

- **macOS 13+**；目前仅在 Apple Silicon、macOS 26.6、豆包输入法 1.0.2 上实测。  
  **macOS 13+**; tested only on Apple Silicon with macOS 26.6 and Doubao Input Method 1.0.2.
- 发射器通过 **USB 接收器**连接 Mac，在系统声音设置中选接收器为输入设备。  
  Connect the transmitter through its **USB receiver** and select the receiver as the Mac's audio input.
- 接收器 VID/PID 为 `0x2ca3:0x4011`，连接键上报 Consumer Volume Increment 事件。其他型号或固件需实测。  
  The receiver must use VID/PID `0x2ca3:0x4011` and emit Consumer Volume Increment for the linking button. Other hardware or firmware needs verification.
- 安装 **Xcode Command Line Tools** 以编译 Swift。  
  Install **Xcode Command Line Tools** to compile Swift.

仅通过蓝牙连接发射器未能提供所需按钮事件，不在支持范围内。

A Bluetooth-only connection has not provided the required button events and is not supported.

## 3. 安装 / Installation

打开终端。如果尚未安装编译工具，先运行以下命令并完成系统安装提示：

Open Terminal. If the command-line developer tools are not installed, run this and finish the system installation prompt first:

```sh
xcode-select --install
```

下载并安装项目 / Clone and install:

```sh
git clone https://github.com/sumai-1998/DJI-Mic-Mini-for-Vibe-Coding.git
cd DJI-Mic-Mini-for-Vibe-Coding
./scripts/install.sh
```

也可在 [GitHub](https://github.com/sumai-1998/DJI-Mic-Mini-for-Vibe-Coding) 选择 **Code → Download ZIP**，解压，在终端进入解压目录，执行 `./scripts/install.sh`。

Alternatively, choose **Code → Download ZIP** on [GitHub](https://github.com/sumai-1998/DJI-Mic-Mini-for-Vibe-Coding), extract it, open Terminal in the extracted directory, and run `./scripts/install.sh`.

安装脚本编译、自测并临时签名 App，安装到 `~/Applications/DJI Doubao Controller.app`，设置当前用户登录时启动。会移除本项目旧实验版的重映射辅助脚本，无需管理员权限。

The installer builds, self-tests, and ad-hoc signs the app, installs it at `~/Applications/DJI Doubao Controller.app`, and enables launch at login for the current user. It also removes legacy remapping helpers from earlier prototypes. Administrator privileges are not required.

### 辅助功能授权 / Accessibility permission

在 **系统设置 → 隐私与安全性 → 辅助功能** 中允许 **DJI Doubao Controller**。安装后的 App 名称沿用 DJI Doubao Controller。菜单栏显示 `Mic·就绪` 后即可使用。

Enable **DJI Doubao Controller** in **System Settings → Privacy & Security → Accessibility**. The installed app retains this name. It is ready when the menu bar shows `Mic·就绪` (ready).

更新本地临时签名的 App 后，macOS 可能要求重新授权。如果开关已开启却仍显示 `Mic·待授权`，先退出 App，运行下列命令，再到系统设置中重新授权：

Updating an ad-hoc signed build may require permission again. If the toggle is enabled but the app still shows `Mic·待授权` (permission required), quit the app, run the following commands, then grant permission again in System Settings:

```sh
tccutil reset Accessibility local.dji-doubao-controller
open "$HOME/Applications/DJI Doubao Controller.app"
```

辅助功能权限必须由用户在系统设置中授予。

Accessibility permission must be granted by the user in System Settings.

## 4. 日常使用与限制 / Usage and limitations

将光标放在聊天或编程工具的输入框，单击发射器连接键开始说话，再单击停止；固定 1 秒后会按下 Enter。

Focus a text field in your chat or coding app. Press the transmitter's linking button to start speaking, press again to stop, and Enter will be pressed 1 second later.

- **固定延迟，不检测转写是否完成。** 豆包转写慢时，Enter 可能先发送。  
  **The delay is fixed; transcription completion is not detected.** Enter may arrive before Doubao finishes processing.
- 等待发送期间，切换到其他应用、点击鼠标、手动按 Enter/Esc 或重新开始录入，会撤销上一次待发送的 Enter。同一应用内用键盘切换输入框不一定能检测到。  
  Switching apps, clicking the mouse, manually pressing Enter/Esc, or starting a new dictation cancels the pending Enter. Keyboard-only focus changes within the same app may not be detected.
- 外部操作豆包导致状态不同步时，可从菜单栏选择 **“重置录音状态”**。它只重置本工具，不直接停止豆包录音。  
  If external actions in Doubao cause a state mismatch, choose **“重置录音状态”** (reset recording state) from the menu. This resets the controller only; it does not directly stop Doubao.
- 不包含电源键取消、双击/三击取消或降噪状态监听。  
  Power-button cancellation, double/triple-click cancellation, and noise-cancellation monitoring are not included.
- 退出 App 后，连接键恢复为右 Option 的基本映射，没有自动 Enter。接收器重新插入后，运行中的 App 最多约 15 秒重新应用映射。  
  Quitting restores basic Right Option mapping without automatic Enter. While running, the app reapplies mapping within approximately 15 seconds after reconnecting the receiver.

## 5. 构建与验证 / Build and verification

```sh
./scripts/build.sh
```

产物位于 `build/DJI Doubao Controller.app`。构建时的状态机自测覆盖开始/停止、发送资格、切换应用、新录入撤销旧发送和重置；不会模拟真实麦克风或豆包。

The app is generated at `build/DJI Doubao Controller.app`. State-machine self-tests cover start/stop, send eligibility, app changes, new dictation invalidating a pending send, and reset. They do not simulate microphone hardware or Doubao.

构建脚本生成当前 Mac 架构的 App，并非通用二进制；未进行 Apple 公证，推荐分享源码后本地构建。

The build targets the current Mac's architecture, not a universal binary. It is not notarized by Apple; building from source is the recommended distribution method.

## 6. 实现与隐私 / Implementation and privacy

独立 Swift 菜单栏工具，不基于 Handy、不安装 Whisper，也不自行录音或转写。`hidutil` 将指定接收器的音量增加事件映射为 F18，再用 macOS 事件监听转换为右 Option。第二次单击后调度一次 Enter。注入事件带有标记，避免自身重复处理。

This is a standalone Swift menu-bar app. It is not based on Handy, does not install Whisper, and does not record or transcribe audio. `hidutil` maps the receiver's volume-increment event to F18; a macOS event tap converts it to Right Option. The second press schedules Enter. Injected events are tagged to avoid self-processing.

运行期间占用 F18，并覆盖相同 VID/PID 设备的按键映射。卸载脚本会清空这些设备的映射。

The app reserves F18 while running and replaces mappings for devices with the matching VID/PID. Uninstallation clears those mappings.

日志和状态保存在 `~/.local/share/dji-doubao-controller/`，仅记录操作事件，不记录语音、转写文字或剪贴板。本工具不发起网络请求；豆包的数据处理方式由豆包决定。日志不纳入 Git 或源码包。

Logs and status are stored at `~/.local/share/dji-doubao-controller/`. They contain operational events only—not audio, dictated text, or clipboard contents. This app makes no network requests; Doubao controls its own data processing. Logs are excluded from Git and source archives.

## 7. 卸载 / Uninstallation

```sh
./scripts/uninstall.sh
```

移除 App、登录启动项和设备映射；诊断日志保留在上述用户目录，可自行删除。

Removes the app, login launch agent, and device mappings. Diagnostic logs remain in the user directory above and can be removed manually.

## 项目结构 / Project structure

| 文件 / File | 用途 / Purpose |
| --- | --- |
| `Sources/main.swift` | 控制逻辑、菜单栏、状态机、自测 / Controller, menu bar, state machine, self-tests |
| `Info.plist` | App 信息 / App metadata |
| `scripts/build.sh` | 构建、自测、临时签名 / Build, self-test, ad-hoc signing |
| `scripts/install.sh` | 安装与登录启动 / Installation and launch at login |
| `scripts/uninstall.sh` | 卸载 / Uninstallation |

## 许可证与贡献 / License and contributions

采用 [MIT 许可证](LICENSE)。欢迎提交 Issue 或 Pull Request。不要提交 `build/`、`dist/` 或运行日志。本项目与 DJI、豆包没有官方关联。

Released under the [MIT License](LICENSE). Issues and pull requests are welcome. Do not commit `build/`, `dist/`, or runtime logs. This project is not affiliated with DJI or Doubao.
