; 官方语法文档：https://wyagd001.github.io/v2/docs/AutoHotkey.htm

; 将可执行子系统更改为控制台模式，编译为exe时生效
;@Ahk2Exe-ConsoleApp

; A_ScriptFullPath：脚本或可执行文件的全路径
; BaseDir：脚本或可执行文件所在的目录
BaseDir := SubStr(A_ScriptFullPath, 1, Instr(A_ScriptFullPath, "\", , -1))

; 配置文件路径
ConfigFilename := BaseDir "\config.ini"
General := "General"
General_TempFilename := "TempFilename"
General_SwitchKeys := "SwitchKeys"
General_EnImgs := "EnImgs"
General_ZhImgs := "ZhImgs"

; 快速搜索区间文件路径
ImSwitchIniFilename := A_Temp IniRead(ConfigFilename, General, General_TempFilename, "\im-switch.ini")
; Section SearchRegionCache，搜索区间缓存，为了加速搜索
SearchRegionCacheEn := "SearchRegionCacheEn"
SearchRegionCacheZh := "SearchRegionCacheZh"
SearchRegionCacheEn_Idx := "Idx"
SearchRegionCacheEn_X := "X"
SearchRegionCacheEn_Y := "Y"
SearchRegionCacheZh_Idx := "Idx"
SearchRegionCacheZh_X := "X"
SearchRegionCacheZh_Y := "ZhY"

; 输入法切换按键组合
SwitchKeys := IniRead(ConfigFilename, General, General_SwitchKeys, "^{Space}")

; 帮助文档
Help := "Usage: " A_ScriptName " [parameters]`n" "no parameters - show current state`n" "en - show current state and set en`n" "zh - show current state and set zh`n" "h or help - show help"

; 收集图片
CollectImgs(ImgFiles) {
    ImgArr := []
    Loop Files ImgFiles {
        ImgArr.Push(A_LoopFilePath)
    }
    return ImgArr
}

; 检查屏幕上是否包含Img图片
HasImg(SearchRegion, Img, &FoundX, &FoundY) {
    CoordMode "Pixel"  ; 将下面的坐标解释为相对于屏幕而不是活动窗口
    try {
        if ImageSearch(&FoundX, &FoundY, SearchRegion[1], SearchRegion[2], SearchRegion[3], SearchRegion[4], "*50 " Img) {
            return 1
        } else {
            return 0
        }
    } catch as exc {
        return 0
    } 
}

; 检查屏幕上是否包含Imgs数组中的图片
HasImgs(SearchRegion, Imgs, CacheIdx, &FoundX, &FoundY, &FoundIdx) {
    if CacheIdx > 0 and CacheIdx < Imgs.Length {
        if HasImg(SearchRegion, Imgs[CacheIdx], &FoundX, &FoundY) {
            FoundIdx := CacheIdx
            return 1
        } else {
            return 0
        }
    }

    Idx := 1
    for Img in Imgs {
        if HasImg(SearchRegion, Img, &FoundX, &FoundY) {
            FoundIdx := Idx
            return 1
        }
        Idx := Idx + 1
    }
    return 0
}

; EnImgs：英文图片路径数组
EnImgs := CollectImgs(BaseDir IniRead(ConfigFilename, General, General_EnImgs, "en\*.png"))
; ZhImgs：中文图片路径数组
ZhImgs := CollectImgs(BaseDir IniRead(ConfigFilename, General, General_ZhImgs, "zh\*.png"))

; DefaultSearchRegion：默认搜索的区间，全屏
DefaultSearchRegion := [0, 0, A_ScreenWidth, A_ScreenHeight]

; 检查当前状态是否为en，是返回1，不是返回0
IsEn(UseCache) {
    EnRegion := [0, 0, A_ScreenWidth, A_ScreenHeight]
    CacheEnIdx := 0
    ; 如果允许使用缓存，将尝试从缓存中读取一个上次搜索到的位置以加速搜索
    if UseCache {
        EnRegion[1] := IniRead(ImSwitchIniFilename, SearchRegionCacheEn, SearchRegionCacheEn_X, 0)
        EnRegion[2] := IniRead(ImSwitchIniFilename, SearchRegionCacheEn, SearchRegionCacheEn_Y, 0)
        CacheEnIdx := IniRead(ImSwitchIniFilename, SearchRegionCacheEn, SearchRegionCacheEn_Idx, 0)
    }

    if HasImgs(EnRegion, EnImgs, CacheEnIdx, &FoundX, &FoundY, &FoundIdx) {
        ; 如果搜索到了en，记录到缓存，然后直接返回1
        if FoundX != EnRegion[1] {
            IniWrite(FoundX, ImSwitchIniFilename, SearchRegionCacheEn, SearchRegionCacheEn_X)
        }
        if FoundY != EnRegion[2] {
            IniWrite(FoundY, ImSwitchIniFilename, SearchRegionCacheEn, SearchRegionCacheEn_Y)
        }
        if FoundIdx != CacheEnIdx {
            IniWrite(FoundIdx, ImSwitchIniFilename, SearchRegionCacheEn, SearchRegionCacheEn_Idx)
        }
        return 1
    } else if UseCache and EnRegion[1] > 0 {
        ; UseCache and EnRegion[1] > 0 说明允许使用缓存，并且真的使用了缓存
        ; 如果使用了缓存，并且没有搜索到，那么检查一下是否是zh，如果不是zh还需要全局搜索一次，防止因为缓存问题导致的没有搜索到的情况
        ZhRegion := [
            IniRead(ImSwitchIniFilename, SearchRegionCacheZh, SearchRegionCacheZh_X, 0), 
            IniRead(ImSwitchIniFilename, SearchRegionCacheZh, SearchRegionCacheZh_Y, 0), 
            A_ScreenWidth, 
            A_ScreenHeight]
        CacheZhIdx := IniRead(ImSwitchIniFilename, SearchRegionCacheZh, SearchRegionCacheZh_Idx, 0)
        if HasImgs(ZhRegion, ZhImgs, CacheZhIdx, &FoundX, &FoundY, &FoundIdx) {
            ; 如果是zh说明不是n，记录一下zh缓存，返回0即可
            if FoundX != ZhRegion[1] {
                IniWrite(FoundX, ImSwitchIniFilename, SearchRegionCacheZh, SearchRegionCacheZh_X)
            }
            if FoundY != ZhRegion[2] {
                IniWrite(FoundY, ImSwitchIniFilename, SearchRegionCacheZh, SearchRegionCacheZh_Y)
            }
            if FoundIdx != CacheZhIdx {
                IniWrite(FoundIdx, ImSwitchIniFilename, SearchRegionCacheZh, SearchRegionCacheZh_Idx)
            }
            return 0
        } else {
            ; 如果不是zh，有两种可能，1是zh缓存坏了，2是en缓存坏了
            ; 无缓存搜索一次en，如果是en说明en缓存坏了，如果不是en说明zh缓存坏了
            if IsEn(false) {
                ; en缓存坏了，清理掉该缓存
                IniDelete(ImSwitchIniFilename, SearchRegionCacheEn)
                return 1
            } else {
                ; zh缓存坏了，清理掉该缓存
                IniDelete(ImSwitchIniFilename, SearchRegionCacheZh)
                return 0
            }
        }
    } else {
        ; 如果搜索en没有使用缓存直接返回0
        return 0
    }
}

; 命令行指令
State := (IsEn(true) ? "en" : "zh")
if A_Args.Length == 0 {
    ; 没有参数时输出当前输入法状态，en-英文，zh-中文
    FileAppend(State, "*", "UTF-8")
} else {
    if A_Args[1] == "h" or A_Args[1] == "help" {
        FileAppend(Help, "*", "UTF-8")
    } else if A_Args[1] == "en" {
        FileAppend(State, "*", "UTF-8")
        if State == "zh" {
            ; 将输入法转为en
            Send(SwitchKeys)
        }
    } else if A_Args[1] == "zh" {
        FileAppend(State, "*", "UTF-8")
        if State == "en" {
            ; 将输入法转为zh
            Send(SwitchKeys)
        }
    } else {
        FileAppend(Help, "**", "UTF-8")
    }
}
