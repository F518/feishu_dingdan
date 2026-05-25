param(
  [string]$ChatId = "",
  [string]$RuntimeDir = "runtime",
  [int]$TimeoutMinutes = 0,
  [int]$TimeoutSeconds = 0,
  [switch]$ReplyToText
)

$ErrorActionPreference = "Stop"

function Write-MvpLog {
  param([string]$Message)
  $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
  Write-Host "[$timestamp] $Message"
}

function Get-JsonString {
  param($Value)
  if ($null -eq $Value) {
    return ""
  }

  if ($Value -is [string]) {
    return $Value
  }

  return ($Value | ConvertTo-Json -Depth 20 -Compress)
}

function ConvertFrom-Utf8Base64 {
  param([string]$Value)
  return [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($Value))
}

function Invoke-LarkReply {
  param(
    [string]$MessageId,
    [string]$Text,
    [string]$IdempotencyKey
  )

  $args = @(
    "im",
    "+messages-reply",
    "--as",
    "bot",
    "--message-id",
    $MessageId,
    "--text",
    $Text,
    "--idempotency-key",
    $IdempotencyKey
  )

  & lark-cli @args | Out-Null
}

function Save-Event {
  param($Event)

  $eventsDir = Join-Path $RuntimeDir "events"
  if (-not (Test-Path -LiteralPath $eventsDir)) {
    New-Item -ItemType Directory -Force -Path $eventsDir | Out-Null
  }

  $eventId = if ($Event.event_id) { $Event.event_id } else { [guid]::NewGuid().ToString("N") }
  $path = Join-Path $eventsDir "$eventId.json"
  $Event | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $path -Encoding UTF8
}

if (-not (Get-Command lark-cli -ErrorAction SilentlyContinue)) {
  throw "lark-cli was not found in PATH."
}

if (-not (Test-Path -LiteralPath $RuntimeDir)) {
  New-Item -ItemType Directory -Force -Path $RuntimeDir | Out-Null
}

$status = & lark-cli auth status --verify | ConvertFrom-Json
if (-not $status.identities.bot.available) {
  throw "Bot identity is not available. Run lark-cli config init first."
}

$allowedMessageTypes = @("image", "file")
if ($ReplyToText) {
  $allowedMessageTypes += "text"
}

$timeoutArg = @()
if ($TimeoutSeconds -gt 0) {
  $timeoutArg = @("--timeout", "${TimeoutSeconds}s")
}
elseif ($TimeoutMinutes -gt 0) {
  $timeoutArg = @("--timeout", "${TimeoutMinutes}m")
}

$consumeArgs = @(
  "event",
  "consume",
  "im.message.receive_v1",
  "--as",
  "bot"
) + $timeoutArg

Write-MvpLog "Starting Feishu group MVP listener."
if ($ChatId.Trim().Length -gt 0) {
  Write-MvpLog "Only handling chat_id=$ChatId"
}
else {
  Write-MvpLog "No ChatId specified. Handling all group chats visible to this bot."
}
Write-MvpLog "Allowed message types: $($allowedMessageTypes -join ', ')"
Write-MvpLog "Press Ctrl+C to stop."

& lark-cli @consumeArgs | ForEach-Object {
  if (-not $_) {
    return
  }

  try {
    $evt = $_ | ConvertFrom-Json
  }
  catch {
    Write-MvpLog "Skipped non-JSON event line."
    return
  }

  Save-Event -Event $evt

  $eventId = [string]$evt.event_id
  $messageId = [string]$evt.message_id
  $messageType = [string]$evt.message_type
  $chatType = [string]$evt.chat_type
  $chatId = [string]$evt.chat_id
  $senderId = [string]$evt.sender_id

  if ($chatType -ne "group") {
    Write-MvpLog "Ignored non-group message: $messageId"
    return
  }

  if ($ChatId.Trim().Length -gt 0 -and $chatId -ne $ChatId) {
    Write-MvpLog "Ignored message from another chat: $chatId"
    return
  }

  if ($allowedMessageTypes -notcontains $messageType) {
    Write-MvpLog "Ignored message type=$messageType message_id=$messageId"
    return
  }

  $content = Get-JsonString -Value $evt.content
  $replyIntro = ConvertFrom-Utf8Base64 -Value "5bey5pS25Yiw5L2g55qE5oql6ZSA6LWE5paZ44CCCgrlvZPliY0gTVZQIOW3suWujOaIkO+8mue+pOa2iOaBr+ebkeWQrOOAgei1hOaWmeaOpeaUtuehruiupOOAgeS6i+S7tueVmeaho+OAggrkuIvkuIDmraXkvJrov5vlhaXvvJrlj5Hnpagv6KGM56iL5Y2V6K+G5Yir44CB5aSa57u06KGo5qC85Y+w6LSm44CB56Gu6K6k5ZCO5o+Q5Lqk5a6h5om544CC"
  $messageTypeLabel = ConvertFrom-Utf8Base64 -Value "5raI5oGv57G75Z6L77ya"
  $messageIdLabel = ConvertFrom-Utf8Base64 -Value "5raI5oGvSUTvvJo="
  $replyText = @"
$replyIntro

$messageTypeLabel$messageType
$messageIdLabel$messageId
"@

  $idempotencyKey = "reimbursement-mvp-$eventId"
  try {
    Invoke-LarkReply -MessageId $messageId -Text $replyText -IdempotencyKey $idempotencyKey
    Write-MvpLog "Replied to message_id=$messageId sender=$senderId content=$content"
  }
  catch {
    Write-MvpLog "Reply failed for message_id=$messageId`: $($_.Exception.Message)"
  }
}
