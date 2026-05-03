<#
.SYNOPSIS
    SDLC Lifecycle Orchestrator — drives autonomous Worker/Reviewer cycles across ROADMAP tasks.

.DESCRIPTION
    Reads ROADMAP.md, picks up PENDING tasks in order, and launches Worker and Reviewer
    agent sessions via `antigravity chat`. Coordinates through filesystem artifacts
    (status.md in each task directory). Each task goes through two review gates:
    1. Plan review — Worker writes plan, Reviewer critiques it
    2. Code review — Worker implements, Reviewer reviews the diff
    Commits only after code review approval. Stops on blocked tasks by default.

.PARAMETER RoadmapPath
    Path to the ROADMAP.md file. Default: ROADMAP.md in the current directory.

.PARAMETER SdlcDir
    Path to the SDLC working state directory. Default: .agents/sdlc

.PARAMETER WorkerTimeoutMin
    Minutes to wait for a Worker session to complete before timing out. Default: 30.

.PARAMETER ReviewerTimeoutMin
    Minutes to wait for a Reviewer session to complete before timing out. Default: 20.

.PARAMETER MaxRounds
    Maximum review rounds per phase (plan and code each get up to this many). Default: 3.

.PARAMETER PollIntervalSec
    How often (seconds) to check the status file for changes. Default: 15.

.PARAMETER ContinueOnBlocked
    By default, the pipeline stops when a task is BLOCKED. Set this flag to skip
    blocked tasks and continue to the next one instead.

.EXAMPLE
    .\sdlc-orchestrate.ps1
    .\sdlc-orchestrate.ps1 -MaxRounds 2 -ContinueOnBlocked
    .\sdlc-orchestrate.ps1 -RoadmapPath "docs/ROADMAP.md" -WorkerTimeoutMin 45
#>

param(
    [string]$RoadmapPath = "ROADMAP.md",
    [string]$SdlcDir = ".agents/sdlc",
    [int]$WorkerTimeoutMin = 30,
    [int]$ReviewerTimeoutMin = 20,
    [int]$MaxRounds = 3,
    [int]$PollIntervalSec = 15,
    [switch]$ContinueOnBlocked
)

# Makes any PowerShell error (e.g., failed file I/O) throw a terminating exception
# so the try/finally block can clean up the lock file reliably.
$ErrorActionPreference = "Stop"

# ── Logging ──────────────────────────────────────────────────────────────────
# All output goes to both the terminal (with color) and a log file in the SDLC
# working directory so the user can review what happened after an unattended run.

$script:LogFile = $null

function Initialize-Logging {
    param([string]$SdlcDir)
    $logDir = Join-Path $SdlcDir "logs"
    New-Item -Path $logDir -ItemType Directory -Force | Out-Null
    $timestamp = Get-Date -Format "yyyy-MM-dd_HHmmss"
    $script:LogFile = Join-Path $logDir "orchestrator-$timestamp.log"
    New-Item -Path $script:LogFile -ItemType File -Force | Out-Null
}

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[$timestamp] [$Level] $Message"

    # Terminal output with color
    $color = switch ($Level) {
        "INFO"    { "Cyan"    }
        "SUCCESS" { "Green"   }
        "WARN"    { "Yellow"  }
        "ERROR"   { "Red"     }
        default   { "White"   }
    }
    Write-Host $line -ForegroundColor $color

    # File output (plain text, no color codes)
    if ($script:LogFile) {
        Add-Content -Path $script:LogFile -Value $line
    }
}

# ── ROADMAP Parsing ──────────────────────────────────────────────────────────
# Supports two ROADMAP formats:
#   Recommended:    ### [PENDING] TASK-NNN: Title
#   Session-based:  ## Session N: Title  (with `[ ]` checkbox in a Session Index table)

function Get-NextPendingTask {
    param([string]$Path)

    if (-not (Test-Path $Path)) {
        Write-Log "ROADMAP file not found: $Path" "ERROR"
        return $null
    }

    $content = Get-Content $Path -Raw

    # Try recommended format first: ### [PENDING] TASK-NNN: Title
    $recommendedPattern = '###\s+\[PENDING\]\s+(TASK-\d{3}):\s+(.+)'
    $match = [regex]::Match($content, $recommendedPattern)
    if ($match.Success) {
        return @{
            Id     = $match.Groups[1].Value
            Title  = $match.Groups[2].Value.Trim()
            Format = "recommended"
        }
    }

    # Fallback: session-based format
    # Find first row in Session Index table with `[ ]` (unchecked)
    # Format: | N | [Title](#anchor) | Tier | `[ ]` |
    # Note: backtick is PowerShell's escape char, so we use single-quoted strings
    $sessionPattern = '\|\s*(\d+)\s*\|\s*\[([^\]]+)\][^\|]*\|[^\|]*\|\s*`\[ \]`'
    $match = [regex]::Match($content, $sessionPattern)
    if ($match.Success) {
        $sessionNum = $match.Groups[1].Value.PadLeft(3, '0')
        return @{
            Id     = "SESSION-$sessionNum"
            Title  = $match.Groups[2].Value.Trim()
            Format = "session"
        }
    }

    # No pending tasks in either format
    return $null
}

function Update-RoadmapStatus {
    param(
        [string]$Path,
        [string]$TaskId,
        [string]$NewStatus
    )

    $content = Get-Content $Path -Raw

    if ($TaskId -match '^TASK-') {
        # Recommended format: replace [CURRENT_STATUS] TASK-ID with [NEW_STATUS] TASK-ID
        $pattern = "\[(?:PENDING|IN_PROGRESS|DONE|BLOCKED)\]\s+$TaskId"
        $replacement = "[$NewStatus] $TaskId"
        $updated = $content -replace $pattern, $replacement
    }
    elseif ($TaskId -match '^SESSION-(\d+)') {
        # Session format checkbox states: `[ ]` pending, `[/]` in-progress, `[x]` done
        $sessionNum = [int]$Matches[1]
        # Build a pattern that matches any of the three checkbox states for this session
        $pattern = '(\|\s*' + $sessionNum + '\s*\|[^\|]*\|[^\|]*\|\s*)`\[[ /x]\]`'
        if ($NewStatus -eq "DONE") {
            $replacement = '${1}`[x]`'
        }
        elseif ($NewStatus -eq "IN_PROGRESS") {
            $replacement = '${1}`[/]`'
        }
        else {
            # BLOCKED or other states: revert to pending checkbox (block details in status.md)
            $replacement = '${1}`[ ]`'
        }
        $updated = $content -replace $pattern, $replacement
    }
    else {
        Write-Log "Unknown task ID format: $TaskId - skipping ROADMAP update" "WARN"
        return
    }

    Set-Content -Path $Path -Value $updated -NoNewline
}

# ── Task State ───────────────────────────────────────────────────────────────
# The status.md file is the handshake between agents and the orchestrator.
# First line = status keyword, remaining lines = metadata (phase, round, etc.)

function Get-TaskStatus {
    param([string]$TaskDir)
    $statusFile = Join-Path $TaskDir "status.md"
    if (-not (Test-Path $statusFile)) { return "UNKNOWN" }
    return (Get-Content $statusFile -First 1).Trim()
}

function Get-TaskPhase {
    param([string]$TaskDir)
    $statusFile = Join-Path $TaskDir "status.md"
    if (-not (Test-Path $statusFile)) { return "UNKNOWN" }

    # Look for "phase: PLAN" or "phase: CODE" in the status file
    $content = Get-Content $statusFile -Raw
    if ($content -match 'phase:\s*(PLAN|CODE)') {
        return $Matches[1]
    }
    return "UNKNOWN"
}

function Set-TaskStatus {
    param(
        [string]$TaskDir,
        [string]$Status,
        [string]$TaskId,
        [string]$Phase = "PLAN",
        [int]$Round = 1,
        [string]$Reason = ""
    )

    $timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"
    $content = "$Status`nphase: $Phase`nround: $Round`nupdated: $timestamp`ntask: $TaskId"
    if ($Reason) {
        $content += "`nreason: $Reason"
    }

    $statusFile = Join-Path $TaskDir "status.md"
    Set-Content -Path $statusFile -Value $content
}

function Poll-TaskStatus {
    param(
        [string]$TaskDir,
        [string[]]$ExpectedStatuses,
        [int]$TimeoutMin
    )

    $deadline = (Get-Date).AddMinutes($TimeoutMin)
    $statusFile = Join-Path $TaskDir "status.md"

    Write-Log "Polling $statusFile for: $($ExpectedStatuses -join ', ') (timeout: ${TimeoutMin}m)"

    while ((Get-Date) -lt $deadline) {
        if (Test-Path $statusFile) {
            $currentStatus = (Get-Content $statusFile -First 1).Trim()
            if ($ExpectedStatuses -contains $currentStatus) {
                Write-Log "Status changed to: $currentStatus" "SUCCESS"
                return $true
            }
        }
        Start-Sleep -Seconds $PollIntervalSec
    }

    Write-Log "Timeout after ${TimeoutMin} minutes waiting for: $($ExpectedStatuses -join ', ')" "WARN"
    return $false
}

# ── Commit Helpers ───────────────────────────────────────────────────────────

function Get-CommitMessage {
    param([string]$TaskDir)

    $summaryFile = Join-Path $TaskDir "summary.md"
    if (-not (Test-Path $summaryFile)) {
        Write-Log "No summary.md found - using fallback commit message" "WARN"
        return "chore: complete task (no summary available)"
    }

    $content = Get-Content $summaryFile -Raw

    # Extract the text between "## Commit Message" and the next "##" heading (or end of file)
    $pattern = '(?s)## Commit Message\s*\n(.+?)(?=\n## |\z)'
    $match = [regex]::Match($content, $pattern)

    if ($match.Success) {
        return $match.Groups[1].Value.Trim()
    }

    Write-Log "Could not parse commit message from summary.md - using fallback" "WARN"
    return "chore: complete task"
}

# ── Agent Session ────────────────────────────────────────────────────────────
# Launches an antigravity chat session with the given prompt.
# The prompt should naturally trigger the sdlc-lifecycle skill via its description.

function Start-AgentSession {
    param([string]$Prompt)

    Write-Log "Launching agent session: $Prompt"
    # The -r flag reuses the current window so sessions don't pile up.
    # The -m agent flag ensures the agent has full tool access.
    antigravity chat -m agent -r $Prompt
}

# ── Review Cycle ─────────────────────────────────────────────────────────────
# Runs one complete review cycle (plan OR code) with up to MaxRounds of
# Worker→Reviewer back-and-forth. Returns the final outcome: DONE or BLOCKED.

function Invoke-ReviewCycle {
    param(
        [string]$TaskId,
        [string]$TaskDir,
        [string]$Phase,               # "plan" or "code" — used in log messages only
        [string]$InitialWorkerPrompt, # Prompt to launch the Worker for the first time
        [int]$MaxRounds,
        [int]$WorkerTimeoutMin,
        [int]$ReviewerTimeoutMin
    )

    Write-Log "[$TaskId] ── Starting $Phase phase ──"

    # Launch initial Worker session
    Start-AgentSession $InitialWorkerPrompt

    $workerDone = Poll-TaskStatus -TaskDir $taskDir -ExpectedStatuses @("AWAITING_REVIEW") -TimeoutMin $WorkerTimeoutMin
    if (-not $workerDone) {
        Write-Log "[$TaskId] Worker timed out during $Phase phase" "ERROR"
        Set-TaskStatus -TaskDir $taskDir -Status "BLOCKED" -TaskId $taskId -Phase $Phase.ToUpper() -Reason "WORKER_TIMEOUT"
        return "BLOCKED"
    }

    # Review rounds
    for ($round = 1; $round -le $MaxRounds; $round++) {
        Write-Log "[$TaskId] $Phase review - round ${round}/${MaxRounds}"

        Start-AgentSession "Review the current roadmap task"

        $reviewDone = Poll-TaskStatus -TaskDir $taskDir -ExpectedStatuses @("DONE", "NEEDS_FIXES", "BLOCKED") -TimeoutMin $ReviewerTimeoutMin
        if (-not $reviewDone) {
            Write-Log "[$TaskId] Reviewer timed out during $Phase phase" "ERROR"
            Set-TaskStatus -TaskDir $taskDir -Status "BLOCKED" -TaskId $taskId -Phase $Phase.ToUpper() -Round $round -Reason "REVIEWER_TIMEOUT"
            return "BLOCKED"
        }

        $status = Get-TaskStatus -TaskDir $taskDir

        if ($status -eq "DONE") {
            Write-Log "[$TaskId] $Phase approved at round $round" "SUCCESS"
            return "DONE"
        }
        elseif ($status -eq "BLOCKED") {
            Write-Log "[$TaskId] $Phase blocked by Reviewer at round $round" "WARN"
            return "BLOCKED"
        }
        elseif ($status -eq "NEEDS_FIXES") {
            if ($round -ge $MaxRounds) {
                Write-Log "[$TaskId] Max rounds ($MaxRounds) exhausted for $Phase phase" "WARN"
                Set-TaskStatus -TaskDir $taskDir -Status "BLOCKED" -TaskId $taskId -Phase $Phase.ToUpper() -Round $round -Reason "MAX_ROUNDS_EXCEEDED"
                return "BLOCKED"
            }

            Write-Log "[$TaskId] $Phase round ${round}: fixes requested, relaunching Worker"
            Start-AgentSession "Address review findings for roadmap task $TaskId"

            $fixDone = Poll-TaskStatus -TaskDir $taskDir -ExpectedStatuses @("AWAITING_REVIEW") -TimeoutMin $WorkerTimeoutMin
            if (-not $fixDone) {
                Write-Log "[$TaskId] Worker timed out addressing $Phase fixes" "ERROR"
                Set-TaskStatus -TaskDir $taskDir -Status "BLOCKED" -TaskId $taskId -Phase $Phase.ToUpper() -Round $round -Reason "WORKER_TIMEOUT"
                return "BLOCKED"
            }
        }
    }

    return "BLOCKED"
}

# ── Main ─────────────────────────────────────────────────────────────────────
# Guard: skip main logic when dot-sourced (e.g., for Pester testing).
# When dot-sourced, only the function definitions above are loaded.

if ($MyInvocation.InvocationName -eq '.') {
    return
}

# Resolve paths
$RoadmapPath = Resolve-Path $RoadmapPath -ErrorAction Stop
$SdlcDir = if (Test-Path $SdlcDir) { (Resolve-Path $SdlcDir).Path } else { $SdlcDir }

# Ensure SDLC directory structure exists
$tasksDir = Join-Path $SdlcDir "tasks"
New-Item -Path $tasksDir -ItemType Directory -Force | Out-Null

# Initialize log file
Initialize-Logging -SdlcDir $SdlcDir

# Lock file — prevents two orchestrators from running simultaneously
$lockFile = Join-Path $SdlcDir ".lock"
if (Test-Path $lockFile) {
    Write-Log "Another SDLC orchestration appears to be running. Lock file: $lockFile" "ERROR"
    Write-Log "If this is stale, delete it manually and re-run." "ERROR"
    exit 1
}

New-Item -Path $lockFile -ItemType File -Force | Out-Null
Write-Log "Lock acquired. Starting SDLC pipeline. Log file: $($script:LogFile)"

try {
    $completedTasks = 0
    $blockedTasks = 0

    while ($true) {
        # Find the next pending task from ROADMAP (tries both formats)
        $nextTask = Get-NextPendingTask -Path $RoadmapPath
        if (-not $nextTask) {
            Write-Log "No more pending tasks in $RoadmapPath" "SUCCESS"
            break
        }

        $taskId = $nextTask.Id
        $taskTitle = $nextTask.Title
        $taskDir = Join-Path $tasksDir $taskId

        Write-Log "═══════════════════════════════════════════════════════"
        Write-Log "Starting: $taskId - $taskTitle"
        Write-Log "═══════════════════════════════════════════════════════"

        New-Item -Path $taskDir -ItemType Directory -Force | Out-Null

        # Mark task as in-progress in the ROADMAP
        # Recommended format: [PENDING] -> [IN_PROGRESS]
        # Session format: `[ ]` -> `[/]`
        Update-RoadmapStatus -Path $RoadmapPath -TaskId $taskId -NewStatus "IN_PROGRESS"

        # ── Phase 1: Plan Review ──────────────────────────────────────
        $planResult = Invoke-ReviewCycle `
            -TaskId $taskId `
            -TaskDir $taskDir `
            -Phase "plan" `
            -InitialWorkerPrompt "Create a plan for roadmap task $taskId" `
            -MaxRounds $MaxRounds `
            -WorkerTimeoutMin $WorkerTimeoutMin `
            -ReviewerTimeoutMin $ReviewerTimeoutMin

        if ($planResult -eq "BLOCKED") {
            Update-RoadmapStatus -Path $RoadmapPath -TaskId $taskId -NewStatus "BLOCKED"
            $blockedTasks++
            if (-not $ContinueOnBlocked) {
                Write-Log "Pipeline halted on blocked task. Use -ContinueOnBlocked to skip." "WARN"
                break
            }
            continue
        }

        # ── Phase 2: Code Review ──────────────────────────────────────
        $codeResult = Invoke-ReviewCycle `
            -TaskId $taskId `
            -TaskDir $taskDir `
            -Phase "code" `
            -InitialWorkerPrompt "Implement the approved plan for roadmap task $taskId" `
            -MaxRounds $MaxRounds `
            -WorkerTimeoutMin $WorkerTimeoutMin `
            -ReviewerTimeoutMin $ReviewerTimeoutMin

        if ($codeResult -eq "BLOCKED") {
            Update-RoadmapStatus -Path $RoadmapPath -TaskId $taskId -NewStatus "BLOCKED"
            $blockedTasks++
            if (-not $ContinueOnBlocked) {
                Write-Log "Pipeline halted on blocked task. Use -ContinueOnBlocked to skip." "WARN"
                break
            }
            continue
        }

        # ── Commit ────────────────────────────────────────────────────
        # Reviewer already updated ROADMAP.md to mark the task as DONE.
        # git add -A stages all changes that aren't in .gitignore.
        # Since .agents/ is gitignored, only source code + ROADMAP.md are staged.
        $commitMsg = Get-CommitMessage -TaskDir $taskDir
        Write-Log "[$taskId] Committing: $($commitMsg.Split("`n")[0])"
        git add -A
        git commit -m $commitMsg

        $completedTasks++
        Write-Log "[$taskId] Done!" "SUCCESS"
    }

    # ── Summary ──────────────────────────────────────────────────────
    Write-Log "═══════════════════════════════════════════════════════"
    Write-Log "Pipeline complete. Completed: $completedTasks | Blocked: $blockedTasks"
    Write-Log "═══════════════════════════════════════════════════════"

} finally {
    # Always release the lock, even on errors or Ctrl+C
    Remove-Item -Path $lockFile -ErrorAction SilentlyContinue
    Write-Log "Lock released."
}
