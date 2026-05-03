# Pester 3.x tests for sdlc-orchestrate.ps1 helper functions.
# Run with: Invoke-Pester -Script .agents/skills/sdlc-lifecycle/scripts/sdlc-orchestrate.Tests.ps1

# Dot-source the script to load function definitions.
# The `if ($MyInvocation.InvocationName -eq '.') { return }` guard prevents main logic from running.
. "$PSScriptRoot/sdlc-orchestrate.ps1"

Describe "Get-NextPendingTask" {

    It "parses recommended format" {
        $roadmap = [System.IO.Path]::GetTempFileName()
        Set-Content $roadmap -Value @"
# Roadmap
### [DONE] TASK-001: Already done
### [PENDING] TASK-002: Add logging
### [PENDING] TASK-003: Add metrics
"@
        try {
            $result = Get-NextPendingTask -Path $roadmap
            $result.Id     | Should Be "TASK-002"
            $result.Title  | Should Be "Add logging"
            $result.Format | Should Be "recommended"
        } finally {
            Remove-Item $roadmap -ErrorAction SilentlyContinue
        }
    }

    It "parses session-based format with checkbox table" {
        $roadmap = [System.IO.Path]::GetTempFileName()
        Set-Content $roadmap -Value @"
# Roadmap
| # | Session | Tier | Status |
|---|---------|------|--------|
| 1 | [Circuit Breakers](#s1) | Critical | ``[x]`` |
| 2 | [Market Hours](#s2) | Critical | ``[ ]`` |
"@
        try {
            $result = Get-NextPendingTask -Path $roadmap
            $result.Id     | Should Be "SESSION-002"
            $result.Title  | Should Be "Market Hours"
            $result.Format | Should Be "session"
        } finally {
            Remove-Item $roadmap -ErrorAction SilentlyContinue
        }
    }

    It "returns null when no pending tasks" {
        $roadmap = [System.IO.Path]::GetTempFileName()
        Set-Content $roadmap -Value "### [DONE] TASK-001: All done"
        try {
            $result = Get-NextPendingTask -Path $roadmap
            $result | Should BeNullOrEmpty
        } finally {
            Remove-Item $roadmap -ErrorAction SilentlyContinue
        }
    }

    It "returns null when file does not exist" {
        $result = Get-NextPendingTask -Path "C:\DOES_NOT_EXIST_12345.md"
        $result | Should BeNullOrEmpty
    }
}

Describe "Update-RoadmapStatus" {

    It "updates recommended format status marker" {
        $roadmap = [System.IO.Path]::GetTempFileName()
        Set-Content $roadmap -Value "### [PENDING] TASK-001: Do things" -NoNewline
        try {
            Update-RoadmapStatus -Path $roadmap -TaskId "TASK-001" -NewStatus "IN_PROGRESS"
            $content = Get-Content $roadmap -Raw
            $content | Should Match "\[IN_PROGRESS\] TASK-001"
        } finally {
            Remove-Item $roadmap -ErrorAction SilentlyContinue
        }
    }

    It "updates session format checkbox to [/] on IN_PROGRESS" {
        $roadmap = [System.IO.Path]::GetTempFileName()
        Set-Content $roadmap -Value '| 2 | [Market Hours](#s2) | Critical | `[ ]` |' -NoNewline
        try {
            Update-RoadmapStatus -Path $roadmap -TaskId "SESSION-002" -NewStatus "IN_PROGRESS"
            $content = Get-Content $roadmap -Raw
            $content | Should Match '\[/\]'
        } finally {
            Remove-Item $roadmap -ErrorAction SilentlyContinue
        }
    }

    It "updates session format checkbox from [/] to [x] on DONE" {
        $roadmap = [System.IO.Path]::GetTempFileName()
        Set-Content $roadmap -Value '| 2 | [Market Hours](#s2) | Critical | `[/]` |' -NoNewline
        try {
            Update-RoadmapStatus -Path $roadmap -TaskId "SESSION-002" -NewStatus "DONE"
            $content = Get-Content $roadmap -Raw
            $content | Should Match '\[x\]'
        } finally {
            Remove-Item $roadmap -ErrorAction SilentlyContinue
        }
    }

    It "does not change session format checkbox for BLOCKED" {
        $roadmap = [System.IO.Path]::GetTempFileName()
        Set-Content $roadmap -Value '| 2 | [Market Hours](#s2) | Critical | `[/]` |' -NoNewline
        try {
            Update-RoadmapStatus -Path $roadmap -TaskId "SESSION-002" -NewStatus "BLOCKED"
            $content = Get-Content $roadmap -Raw
            $content | Should Match '\[ \]'
        } finally {
            Remove-Item $roadmap -ErrorAction SilentlyContinue
        }
    }
}

Describe "Get-TaskStatus" {

    It "reads first line of status.md" {
        $taskDir = Join-Path ([System.IO.Path]::GetTempPath()) "pester-task-status"
        New-Item $taskDir -ItemType Directory -Force | Out-Null
        Set-Content (Join-Path $taskDir "status.md") -Value "AWAITING_REVIEW`nphase: CODE`nround: 1"
        try {
            $result = Get-TaskStatus -TaskDir $taskDir
            $result | Should Be "AWAITING_REVIEW"
        } finally {
            Remove-Item $taskDir -Recurse -ErrorAction SilentlyContinue
        }
    }

    It "returns UNKNOWN when status.md missing" {
        $taskDir = Join-Path ([System.IO.Path]::GetTempPath()) "pester-task-empty"
        New-Item $taskDir -ItemType Directory -Force | Out-Null
        try {
            $result = Get-TaskStatus -TaskDir $taskDir
            $result | Should Be "UNKNOWN"
        } finally {
            Remove-Item $taskDir -Recurse -ErrorAction SilentlyContinue
        }
    }
}

Describe "Get-TaskPhase" {

    It "extracts PLAN phase" {
        $taskDir = Join-Path ([System.IO.Path]::GetTempPath()) "pester-phase-plan"
        New-Item $taskDir -ItemType Directory -Force | Out-Null
        Set-Content (Join-Path $taskDir "status.md") -Value "AWAITING_REVIEW`nphase: PLAN`nround: 1"
        try {
            $result = Get-TaskPhase -TaskDir $taskDir
            $result | Should Be "PLAN"
        } finally {
            Remove-Item $taskDir -Recurse -ErrorAction SilentlyContinue
        }
    }

    It "extracts CODE phase" {
        $taskDir = Join-Path ([System.IO.Path]::GetTempPath()) "pester-phase-code"
        New-Item $taskDir -ItemType Directory -Force | Out-Null
        Set-Content (Join-Path $taskDir "status.md") -Value "IN_REVIEW`nphase: CODE`nround: 2"
        try {
            $result = Get-TaskPhase -TaskDir $taskDir
            $result | Should Be "CODE"
        } finally {
            Remove-Item $taskDir -Recurse -ErrorAction SilentlyContinue
        }
    }

    It "returns UNKNOWN when no phase field" {
        $taskDir = Join-Path ([System.IO.Path]::GetTempPath()) "pester-phase-none"
        New-Item $taskDir -ItemType Directory -Force | Out-Null
        Set-Content (Join-Path $taskDir "status.md") -Value "IN_PROGRESS`nround: 1"
        try {
            $result = Get-TaskPhase -TaskDir $taskDir
            $result | Should Be "UNKNOWN"
        } finally {
            Remove-Item $taskDir -Recurse -ErrorAction SilentlyContinue
        }
    }
}

Describe "Set-TaskStatus" {

    It "writes all fields including reason" {
        $taskDir = Join-Path ([System.IO.Path]::GetTempPath()) "pester-set-status"
        New-Item $taskDir -ItemType Directory -Force | Out-Null
        try {
            Set-TaskStatus -TaskDir $taskDir -Status "BLOCKED" -TaskId "TASK-001" -Phase "CODE" -Round 2 -Reason "MAX_ROUNDS_EXCEEDED"
            $content = Get-Content (Join-Path $taskDir "status.md") -Raw
            $content | Should Match "^BLOCKED"
            $content | Should Match "phase: CODE"
            $content | Should Match "round: 2"
            $content | Should Match "task: TASK-001"
            $content | Should Match "reason: MAX_ROUNDS_EXCEEDED"
        } finally {
            Remove-Item $taskDir -Recurse -ErrorAction SilentlyContinue
        }
    }

    It "omits reason when not provided" {
        $taskDir = Join-Path ([System.IO.Path]::GetTempPath()) "pester-set-noreason"
        New-Item $taskDir -ItemType Directory -Force | Out-Null
        try {
            Set-TaskStatus -TaskDir $taskDir -Status "IN_PROGRESS" -TaskId "TASK-002"
            $content = Get-Content (Join-Path $taskDir "status.md") -Raw
            $content | Should Not Match "reason:"
        } finally {
            Remove-Item $taskDir -Recurse -ErrorAction SilentlyContinue
        }
    }
}

Describe "Get-CommitMessage" {

    It "extracts commit message from summary.md" {
        $taskDir = Join-Path ([System.IO.Path]::GetTempPath()) "pester-commit-msg"
        New-Item $taskDir -ItemType Directory -Force | Out-Null
        Set-Content (Join-Path $taskDir "summary.md") -Value @"
# Task Summary

## Commit Message
feat(logging): add structured logging

Replace println with SLF4J logger calls.

## What Changed
- Added logger
"@
        try {
            $result = Get-CommitMessage -TaskDir $taskDir
            $result | Should Match "feat\(logging\)"
            $result | Should Match "Replace println"
        } finally {
            Remove-Item $taskDir -Recurse -ErrorAction SilentlyContinue
        }
    }

    It "returns fallback when summary.md is missing" {
        $taskDir = Join-Path ([System.IO.Path]::GetTempPath()) "pester-commit-none"
        New-Item $taskDir -ItemType Directory -Force | Out-Null
        try {
            $result = Get-CommitMessage -TaskDir $taskDir
            $result | Should Be "chore: complete task (no summary available)"
        } finally {
            Remove-Item $taskDir -Recurse -ErrorAction SilentlyContinue
        }
    }

    It "returns fallback when commit message section is missing" {
        $taskDir = Join-Path ([System.IO.Path]::GetTempPath()) "pester-commit-bad"
        New-Item $taskDir -ItemType Directory -Force | Out-Null
        Set-Content (Join-Path $taskDir "summary.md") -Value "# Summary`nNo commit message here"
        try {
            $result = Get-CommitMessage -TaskDir $taskDir
            $result | Should Be "chore: complete task"
        } finally {
            Remove-Item $taskDir -Recurse -ErrorAction SilentlyContinue
        }
    }
}
