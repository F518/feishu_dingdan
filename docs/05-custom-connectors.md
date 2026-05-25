# 自定义连接器设计

## 使用原则

优先使用飞书低代码/集成平台原生动作。只有原生动作无法覆盖以下能力时，才添加自定义连接器：

- 下载消息中的图片或文件资源。
- 上传审批附件。
- 创建审批实例。
- 查询审批实例详情用于回写。

自定义连接器仍部署在飞书低代码/集成平台中，不依赖员工电脑、本地脚本或个人服务。

## 连接器一：下载消息资源

用途：把群消息中的图片或文件附件交给后续 AI 识别流程。

接口：

- 方法：`GET`
- 路径：`/open-apis/im/v1/messages/{message_id}/resources/{file_key}`
- 查询参数：`type=image|file`
- 身份：应用机器人

输入：

- `message_id`
- `file_key`
- `resource_type`

输出：

- 文件二进制或平台文件引用。
- 文件名、MIME 类型、大小。

## 连接器二：上传审批附件

用途：将已确认的发票和行程单上传到审批系统，获得审批表单附件 code。

接口：

- 方法：`POST`
- URL：`https://www.feishu.cn/approval/openapi/v2/file/upload`
- Content-Type：`multipart/form-data`

输入：

- `name`
- `type`: `image` 或 `attachment`
- `content`

输出：

- `code`
- `url`

限制：

- 每次只能上传一个文件。
- 附件最大 50 MB。
- 图片最大 10 MB。

## 连接器三：创建审批实例

用途：确认后提交公司现有报销审批。

接口：

- 方法：`POST`
- URL：`https://open.feishu.cn/open-apis/approval/v4/instances`
- Content-Type：`application/json; charset=utf-8`

输入：

- `approval_code`
- `open_id` 或 `user_id`
- `department_id`
- `form`
- `uuid`

输出：

- 审批实例 code 或 ID。
- 审批跳转链接。

注意：

- `form` 是 JSON 数组压缩转义后的字符串。
- `uuid` 用于幂等，建议由 `message_id + invoice_number + amount` 生成。
- 如果审批定义有自选审批人或抄送人，需要补充节点参数。

## 连接器四：查询审批实例

用途：调试或后续回写审批状态。

接口：

- 方法：`GET`
- URL：`https://open.feishu.cn/open-apis/approval/v4/instances/{instance_id}`

输入：

- `instance_id`

输出：

- 审批状态。
- 审批任务列表。
- 审批表单内容。
