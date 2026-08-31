# FToolBox
使用flutter自己写的一些工具软件，集成到这里面，主要是桌面端 
- [x] 将文件按照时间进行重新排序组织，以年为单位，主要用来整理视频和照片
- [x] 图片转视频
- [x] 视频下载（需本机 yt-dlp）
- [] 倒计时

## 视频下载

“视频下载”使用本机的 [yt-dlp](https://github.com/yt-dlp/yt-dlp) 解析公开、未加密的视频页面，并显示进度、速度和日志。Windows 下请将 `yt-dlp.exe` 放到程序 exe 同目录，或安装后加入系统 `PATH`。该功能仅适用于您有权保存的内容，不支持 DRM、付费内容破解或登录权限绕过。


# 当前flutter版本
3.29.3

# 编译
flutter build windows
