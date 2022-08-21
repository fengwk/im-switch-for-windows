# im-switch-for-windows

编写这个脚本的初衷是为了解决vim（nvim）在windows平台下的中英文输入法自动切换问题，当然它也可以解决更多与输入法相关的问题。

该脚本使用autohotkey2编写，并已编译为可执行的命令行程序：

- `im-switch-x32.exe` - 可以在32位平台上运行。
- `im-switch-x64.exe` - 可以在64位平台上运行。

# Usage

克隆当前仓库即可使用工具:

```powershell
# for you
git clone https://github.com/fengwk/im-switch-for-windows.git

# for me
git clone git@github.com:fengwk/im-switch-for-windows.git
```

可以通过命令行方便地获得帮助：

```powershell
>im-switch-x64.exe h
Usage: im-switch-x64.exe [parameters]
no parameters - show current state
en - show current state and set en
zh - show current state and set zh
h or help - show help
```

为了在vim脚本中实现自动中英文切换能力，该命令行工具具备以下能力：

- 检查当前微软拼音输入法状态：可以使用`im-switch-x64.exe`完成，输出`en`表示当前为英文，输出`zh`表示当前为中文。
- 切换当前微软拼音输入法到指定状态：
    - `im-switch-x64.exe en` - 切换到英文输入法。
    - `im-switch-x64.exe zh` - 切换到中文输入法。

如果你也希望使用这个工具来帮助nvim自动切换中英文输入，可以参考下面的脚本：

```lua
-- 自动切换输入法

-- 自动切换fcitx5输入法
function auto_switch_fcitx5(mode)
  if mode == "in" then -- 进入插入模式
    local file, err = io.open("/tmp/nvim-im-state", "r")
    if err == nil then -- err == nil 说明文件存在
      local state = file:read() -- 读取状态值
      if state == "2" then -- 2说明退出前是active的，应该被重置
        os.execute("fcitx5-remote -o")
      end
      file:close()
    end
  else
    -- 退出插入模式时将将当前状态记录下来，并切回不活跃
    os.execute("fcitx5-remote > /tmp/nvim-im-state")
    os.execute("fcitx5-remote -c")
  end
end

-- 自动切换微软拼音输入法
function auto_switch_micro_pinyin(mode)
  if mode == "in" then -- 进入插入模式
    local file, err = io.open(os.getenv("TMP") .. "\\nvim-im-state", "r")
    if err == nil then -- err == nil 说明文件存在
      local state = file:read() -- 读取状态值
      if state == "zh" then -- zh说明退出前是中文的，应该被重置
        os.execute("im-switch-x64.exe zh > " .. os.getenv("TMP") .. "\\null")
      end
      file:close()
    end
  else
    -- 退出插入模式时将将当前状态记录下来，并切回英文
    os.execute("im-switch-x64.exe en > " .. os.getenv("TMP") .. "\\nvim-im-state")
  end
end

-- wsl版本，使用cmd.exe会对性能有一定的影响
-- cmd.exe参考：https://www.cnblogs.com/baby123/p/11459316.html
function auto_switch_micro_pinyin_wsl(mode)
  if mode == "in" then -- 进入插入模式
    local file, err = io.open(os.getenv("TMP") .. "\\nvim-im-state", "r")
    if err == nil then -- err == nil 说明文件存在
      local state = file:read() -- 读取状态值
      if state == "zh" then -- zh说明退出前是中文的，应该被重置
        os.execute("cmd.exe /C \"im-switch-x64.exe zh > " .. os.getenv("TMP") .. "\\null\"")
      end
      file:close()
    end
  else
    -- 退出插入模式时将将当前状态记录下来，并切回英文
    os.execute("cmd.exe /C \"im-switch-x64.exe en > " .. os.getenv("TMP") .. "\\nvim-im-state\"")
  end
end

-- 自动切换输入法
function _G.auto_switch_im(mode)
  local os = os.getenv("OS")
  if os ~= nil then
    if string.find(string.lower(os), "win") ~= nil then
      return auto_switch_micro_pinyin(mode)
    end
  else 
    if os.getenv("WSL_DISTRO_NAME") ~= nil then
      return auto_switch_micro_pinyin_wsl(mode)
    else
      return auto_switch_fcitx5(mode)
    end
  end
end

-- 在相应的时机自动进行函数调用
-- vim自动命令参考：http://yyq123.github.io/learn-vim/learn-vi-49-01-autocmd.html
vim.api.nvim_create_autocmd(
  { "InsertLeave" },
  { pattern = "*", command = ":call v:lua.auto_switch_im('out')"}
)
vim.api.nvim_create_autocmd(
  { "InsertEnter" },
  { pattern = "*", command = ":call v:lua.auto_switch_im('in')"}
)
-- vim.api.nvim_create_autocmd(
--   { "BufCreate" },
--   { pattern = "*", command = ":call v:lua.auto_switch_im('out')"}
-- )
-- vim.api.nvim_create_autocmd(
--   { "BufEnter" },
--   { pattern = "*", command = ":call v:lua.auto_switch_im('out')"}
-- )
-- vim.api.nvim_create_autocmd(
--   { "BufLeave" },
--   { pattern = "*", command = ":call v:lua.auto_switch_im('out')"}
-- )
```

# Config

由于微软拼音输入法没有提供API进行状态查询，因此使用了图片搜索的方式进行状态判断，需要截取微软拼音输入法的中英文托盘截图分别放在`zh`和`en`目录（可参考我的截图，默认情况下需使用png结尾），另外如果需要支持多分辨率，你可以在不同的分辨率下都进行截图，放在相应语言的文件夹下。

同样由于微软拼音输入法没有提供API进行状态切换，脚本中将使用自动发送组合热键的方式实现输入法状态切换，默认情况下是`ctrl+空格`，如果你使用了其它组合可以修改`config.ini`中`General`下的`SwitchKeys`项，热键对应的字符串参考[Send](https://wyagd001.github.io/v2/docs/commands/Send.htm)。

一般情况下使用默认的`config.ini`文件即可，如需定制可进行修改：

- General
  - TempFilename：临时文件名称
  - SwitchKeys：切换中英文输入法的热键
  - EnImgs：英文图片匹配名称
  - ZhImgs：中文图片匹配名称

# Dev

如果你需要对脚本进行调整，只需要修改`im-switch.ahk`文件，然后使用Ahk2Exe进行编译即可，autohotkey2语法比较简单，我本身也是刚刚接触它，如果你有编程基础，参考[AutoHotkey](https://wyagd001.github.io/v2/docs/AutoHotkey.htm)应该能够很快进行调整，否则也可以向我提issue。

可以从autohotkey2官网下载安装包安装它，我喜欢使用scoop：

```powershell
scoop install autohotkey2
```

因为scoop安装的autohotkey2是最小版本，因此还需要安装一下`install-ahk2exe.ahk`：

```powershell
autohotkey2.exe C:\Users\fengwk\scoop\apps\autohotkey2\2.0-beta.7\UX\install-ahk2exe.ahk
```

然后就能在`C:\Users\fengwk\scoop\apps\autohotkey2\2.0-beta.7\Compiler`目录下找到可执行程序`Ahk2Exe.exe`，双击打开就能编译`ahk`为可执行`exe`。

# Tips

- 在首次执行或分辨率切换后首次执行时会稍显卡顿，因为需要对全屏进行图像搜索，但执行过一次后就会进行位置信息缓存，因此如果输入法托盘位置没有发生变更，执行速度将大大提升，完全能够满足自动切换的需求。
- 由于使用图像搜索方式实现输入法状态判断，因此如果使用全屏模式会导致任务栏被遮挡，最终使得搜索失败。

**end, enjoy!**
