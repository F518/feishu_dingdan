# 群 MVP 运行手册

## MVP 范围

当前最简版只做三件事：

1. 监听飞书群消息事件 `im.message.receive_v1`。
2. 收到群内图片或文件消息后，机器人回复“已收到报销资料”。
3. 将事件 JSON 留存在本地 `runtime/events/`，用于确认字段结构和下一步接多维表格。

暂不做：

- 自动识别发票字段。
- 自动创建审批。
- 多维表格写入。

这样可以先验证最关键的群内闭环：应用、机器人、群、事件订阅、消息回复权限都能跑通。

## 需要在飞书后台开启

在企业自建应用中确认：

- 机器人能力已开启。
- 应用可见范围包含测试群成员。
- 机器人已加入测试报销群。
- 事件订阅已添加：`im.message.receive_v1`。
- 权限至少包含：
  - 接收消息事件需要的消息读取权限。
  - 机器人发送/回复消息权限。
  - 群信息读取权限。

如果启动脚本报权限错误，按 CLI 输出的 `console_url` 到后台补开对应 scope。

## 启动命令

监听所有机器人所在群：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\start-group-mvp-listener.ps1
```

只监听指定群：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\start-group-mvp-listener.ps1 -ChatId "oc_xxx"
```

临时测试文本消息也回复：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\start-group-mvp-listener.ps1 -ReplyToText
```

运行 10 分钟后自动退出：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\start-group-mvp-listener.ps1 -TimeoutMinutes 10
```

短跑 15 秒验证事件消费是否能启动：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\start-group-mvp-listener.ps1 -TimeoutSeconds 15
```

## 验证方式

1. 在测试群发送一张发票图片或一个 PDF。
2. 机器人应在原消息下回复“已收到你的报销资料”。
3. 本地 `runtime/events/` 下应出现事件 JSON。
4. 终端日志应显示已回复的 `message_id`。

## 停止

在终端按 `Ctrl+C`。

不要用强杀方式停止事件消费进程，避免事件订阅状态残留。
