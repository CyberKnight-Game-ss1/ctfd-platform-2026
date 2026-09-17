# update-skills.ps1 — Re-clone vendored skills từ upstream về commit mới nhất
# Dùng: pwsh -File .claude/scripts/update-skills.ps1
# Sau khi chạy: git status + review + commit (đã vendoring, không submodule)
$ErrorActionPreference = "Stop"
$vendored = ".claude/skills/vendored"
$tmp = ".tmp/skills-update"

$repos = @(
    @{ Name = "anthropic-skills"; Url = "https://github.com/anthropics/skills.git" },
    @{ Name = "superpowers";      Url = "https://github.com/obra/superpowers.git" },
    @{ Name = "wshobson-agents";  Url = "https://github.com/wshobson/agents.git" }
)

New-Item -ItemType Directory -Force -Path $tmp | Out-Null
$manifest = @()
foreach ($r in $repos) {
    $dest = Join-Path $tmp $r.Name
    Write-Host ">> clone $($r.Url) (depth 1)"
    if (Test-Path $dest) { Remove-Item -Recurse -Force $dest }
    git clone --depth 1 --quiet $r.Url $dest
    if ($LASTEXITCODE -ne 0) { throw "clone fail: $($r.Url)" }
    $sha = (git -C $dest rev-parse HEAD).Trim()
    $manifest += [pscustomobject]@{ Name = $r.Name; Url = $r.Url; Sha = $sha }

    $target = Join-Path $vendored $r.Name
    if (Test-Path $target) { Remove-Item -Recurse -Force $target }
    Move-Item $dest $target
    # Gỡ .git nội bộ để vendoring (không embedded repo)
    Remove-Item -Recurse -Force (Join-Path $target ".git") -ErrorAction SilentlyContinue
    Write-Host "   -> $target @ $sha" -ForegroundColor Green
}

Write-Host "`n>> Cập nhật VENDORED.md"
$md = @("# Vendored DevOps Skills (clone upstream)`n")
$md += "Cập nhật lần cuối: $(Get-Date -Format 'yyyy-MM-dd')`n"
$md += "| Repo upstream | Commit HEAD |`n|---|---|`n"
foreach ($m in $manifest) { $md += "| $($m.Url) | ``$($m.Sha)`` |`n" }
$md += "`nQuy trình + lý do vendoring: xem git history của file này và .claude/skills/README.md`n"
Set-Content -Path (Join-Path $vendored "VENDORED.md") -Value $md -Encoding utf8

Write-Host "`nHoàn tất. git status để review rồi commit." -ForegroundColor Cyan
