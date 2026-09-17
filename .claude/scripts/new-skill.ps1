# new-skill.ps1 — Scaffold 1 skill mới theo chuẩn Agent Skills
# Dùng: pwsh -File .claude/scripts/new-skill.ps1 <name> "<description>"
param(
    [Parameter(Mandatory)][string]$Name,
    [Parameter(Mandatory)][string]$Description
)
if ($Name -notmatch '^[a-z0-9]+(-[a-z0-9]+)*$') {
    throw "Name phải kebab-case (vd: ctfd-aws-my-skill)"
}
$dir = ".claude/skills/ctfd-aws/$Name"
if (Test-Path $dir) { throw "Skill đã tồn tại: $dir" }
New-Item -ItemType Directory -Force -Path $dir | Out-Null

$content = @"
---
name: $Name
description: $Description
---

# $($Name -replace '-', ' ' -replace 'ctfd aws', 'CTFd AWS')

## Khi nào dùng skill này
- ...

## Quy trình
1. ...

## Lệnh tham khảo
``````bash
# ...
``````

## Cạm bẫy đã biết
- ...
"@
Set-Content -Path "$dir/SKILL.md" -Value $content -Encoding utf8
Write-Host "Đã tạo $dir/SKILL.md — điền nội dung thật vào các mục trên." -ForegroundColor Green
Write-Host "Gợi ý mô tả: viết rõ skill LÀM GÌ + KHI NÀO dùng (description quyết định agent có chọn skill)." 
