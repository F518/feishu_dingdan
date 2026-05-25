param(
  [string]$ConfigDir = (Join-Path $PSScriptRoot "..\config")
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $ConfigDir)) {
  throw "Config directory not found: $ConfigDir"
}

$jsonFiles = Get-ChildItem -LiteralPath $ConfigDir -Filter "*.json" -File | Sort-Object Name
if ($jsonFiles.Count -eq 0) {
  throw "No JSON config files found in: $ConfigDir"
}

foreach ($file in $jsonFiles) {
  try {
    $null = Get-Content -LiteralPath $file.FullName -Encoding UTF8 -Raw | ConvertFrom-Json
    Write-Host "[OK] $($file.Name)"
  }
  catch {
    throw "Invalid JSON in $($file.FullName): $($_.Exception.Message)"
  }
}

$mappingPath = Join-Path $ConfigDir "approval-mapping.template.json"
$mapping = Get-Content -LiteralPath $mappingPath -Encoding UTF8 -Raw | ConvertFrom-Json
if (-not $mapping.approval.approval_code) {
  throw "Missing approval.approval_code in approval-mapping.template.json"
}

if (-not $mapping.form_controls -or $mapping.form_controls.Count -eq 0) {
  throw "approval-mapping.template.json must contain at least one form control mapping"
}

$requiredControlFields = @("source", "approval_control_id", "approval_control_type", "required")
foreach ($control in $mapping.form_controls) {
  foreach ($field in $requiredControlFields) {
    if (-not ($control.PSObject.Properties.Name -contains $field)) {
      throw "Form control mapping is missing field '$field'"
    }
  }
}

Write-Host "Config validation completed."
