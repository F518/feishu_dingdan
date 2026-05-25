# 低代码流程规格

## 流程一：群消息资料接收

触发器：

- 飞书消息事件：`im.message.receive_v1`
- 过滤条件：目标群 `chat_id` 命中报销群白名单，消息包含图片或文件附件。

步骤：

1. 解析事件中的 `message_id`、`chat_id`、`sender.open_id`、`message_type`、附件 key。
2. 查询多维表格是否已有相同 `message_id` 或附件 key。
3. 已存在则写入 `duplicate` 状态并回复发送人。
4. 不存在则创建台账记录，状态为 `received`。
5. 调用消息资源下载连接器，获取附件文件引用。
6. 更新附件清单，状态为 `files_downloaded`。
7. 调用飞书内置 AI 抽取字段，要求输出符合 `config/ai-extraction-schema.json` 的 JSON。
8. 将 AI 原始 JSON、核心字段和置信度写回多维表格。
9. 根据必填字段校验结果设置 `need_more_info` 或 `pending_confirm`。
10. 如果待确认，向发送人发送确认卡片。

## 流程二：确认后提交审批

触发器：

- 确认卡片按钮回调。
- 只接受原始发送人点击确认。

步骤：

1. 根据卡片回调中的台账记录 ID 查询多维表格。
2. 校验状态必须为 `pending_confirm`。
3. 重新检查发票号、金额、日期和附件 key，防止确认期间被误改。
4. 上传审批附件，获取审批文件 code。
5. 按 `config/approval-mapping.template.json` 生成审批 `form` 字符串。
6. 使用 `sender.open_id` 或映射出的 `user_id` 作为审批发起人。
7. 使用稳定 `uuid` 创建审批实例。
8. 成功后写入审批实例 ID，状态改为 `submitted`。
9. 失败则写入 `failed`，保存错误码和错误信息，并通知管理员。

## 流程三：人工补录

触发器：

- 财务或管理员在多维表格中将状态改为 `pending_confirm`。
- 或员工补充缺失资料后再次触发消息流程。

步骤：

1. 检查台账记录是否包含必须字段。
2. 重新生成确认卡片。
3. 后续沿用流程二。

## 必填字段建议

- 报销人 open_id 或 user_id。
- 发票号码。
- 发票日期。
- 发票金额。
- 费用类型。
- 出差开始日期和结束日期。
- 出发地和目的地。
- 至少一个发票附件。
- 至少一个行程单或出差说明附件。

## 错误处理

- 附件下载失败：状态 `failed`，错误类型 `file_download_failed`。
- AI 识别失败：状态 `need_more_info`，错误类型 `ai_extract_failed`。
- 审批附件上传失败：状态 `failed`，错误类型 `approval_file_upload_failed`。
- 审批创建失败：状态 `failed`，错误类型 `approval_instance_create_failed`。
- 权限不足：通知管理员检查应用可见范围、机器人群成员关系和审批 scope。
