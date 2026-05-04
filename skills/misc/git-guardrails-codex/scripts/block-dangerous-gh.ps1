$ErrorActionPreference = 'Continue'

$inputJson = [Console]::In.ReadToEnd()
if ([string]::IsNullOrWhiteSpace($inputJson)) {
  exit 0
}

try {
  $payload = $inputJson | ConvertFrom-Json
} catch {
  exit 0
}

$command = [string]$payload.tool_input.command
if ([string]::IsNullOrWhiteSpace($command)) {
  exit 0
}

$gh = '(gh|gh\.exe)'
$prefix = '(^|[;&|()]\s*)'

# Match high-risk GitHub CLI mutations. Keep read-only `gh` commands allowed.
$DangerousPatterns = @(
  "$prefix$gh\s+pr\s+merge\b",
  "$prefix$gh\s+pr\s+close\b",
  "$prefix$gh\s+issue\s+close\b",
  "$prefix$gh\s+issue\s+delete\b",
  "$prefix$gh\s+repo\s+delete\b",
  "$prefix$gh\s+repo\s+archive\b",
  "$prefix$gh\s+repo\s+rename\b",
  "$prefix$gh\s+repo\s+transfer\b",
  "$prefix$gh\s+release\s+delete\b",
  "$prefix$gh\s+workflow\s+disable\b",
  "$prefix$gh\s+run\s+cancel\b",
  "$prefix$gh\s+run\s+delete\b",
  "$prefix$gh\s+secret\s+(set|delete)\b",
  "$prefix$gh\s+variable\s+(set|delete)\b",
  "$prefix$gh\s+label\s+delete\b",
  "$prefix$gh\s+api\b.*(\s-X\s*(DELETE|POST|PATCH|PUT)\b|\s--method(\s+|=)(DELETE|POST|PATCH|PUT)\b)"
)

foreach ($pattern in $DangerousPatterns) {
  if ($command -match $pattern) {
    [Console]::Error.WriteLine("BLOCKED: '$command' matches dangerous GitHub CLI pattern '$pattern'. Ask the user for an explicit manual action instead.")
    exit 2
  }
}

exit 0