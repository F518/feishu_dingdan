# Feishu Reimbursement Bot

公司级飞书报销机器人实施包。目标是让员工在指定飞书群里发送发票和行程单后，由机器人完成资料整理、字段识别、人工确认和飞书审批提交。

## 当前实现范围

- 入口：飞书自建应用机器人，不使用群自定义 Webhook 机器人。
- 编排：优先使用飞书低代码平台/集成平台。
- 状态：使用多维表格记录每笔报销资料的处理状态。
- 审批：复用公司已有飞书报销审批模板。
- 兜底：低代码原生动作不足时，用自定义连接器补齐飞书 OpenAPI 调用。

## 交付物

- [架构说明](docs/01-architecture.md)
- [低代码流程规格](docs/02-lowcode-workflows.md)
- [飞书配置清单](docs/03-feishu-setup-checklist.md)
- [验收测试计划](docs/04-acceptance-test-plan.md)
- [自定义连接器设计](docs/05-custom-connectors.md)
- [群 MVP 运行手册](docs/06-group-mvp-runbook.md)
- [多维表格字段模板](config/bitable-schema.json)
- [审批字段映射模板](config/approval-mapping.template.json)
- [AI 抽取结果结构](config/ai-extraction-schema.json)
- [连接器端点规格](config/connector-endpoints.json)
- [离线配置校验脚本](scripts/validate-config.ps1)

## 最小落地顺序

1. 在飞书开发者后台创建企业自建应用，开启机器人能力。
2. 将机器人加入试点报销群。
3. 创建多维表格并按 `config/bitable-schema.json` 建表。
4. 从现有报销审批模板获取 `approval_code` 和控件 ID，填写 `config/approval-mapping.template.json`。
5. 在低代码平台搭建消息处理流程和确认后提交流程。
6. 如低代码原生动作缺失，按 `docs/05-custom-connectors.md` 添加自定义连接器。
7. 用 `docs/04-acceptance-test-plan.md` 做试点验收。

## 群 MVP 启动

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\start-group-mvp-listener.ps1
```

只监听一个群时传入 `chat_id`：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\start-group-mvp-listener.ps1 -ChatId "oc_xxx"
```

## 本地校验

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\validate-config.ps1
```

该脚本只检查本仓库 JSON 配置是否能被解析，不访问飞书、不提交审批。
