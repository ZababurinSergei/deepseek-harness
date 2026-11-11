---
name: kill-process
description: Safely find and stop processes on Windows (PS 5.1) and nix by port, PID, or command line
---

# SKILL · kill-process (universal, Windows-first)

<!-- created: 20261027-181900 -->
<!-- sources: RULES.md -->

## 0. Назначение
Безопасно останавливать процессы на Windows (PowerShell 5.1) и *nix.
Правило: сначала найти, потом убить. Всегда логировать PID/CMD.
Никогда не убивать PID 0/4, explorer.exe, winlogon.exe, csrss.exe, services.exe, lsass.exe.

## 1. Запреты (RULES §2, §8)
- kill $$, kill $PPID, taskkill /F /IM *, Stop-Process -Name * — НЕЛЬЗЯ.
- exit, exec, set -e — НЕЛЬЗЯ.
- Убивать процесс, который держит чужой проект — НЕЛЬЗЯ без явного подтверждения.
- taskkill /T (дерево) — только если явно нужен весь subtree.

## 2. Windows: найти процесс по порту
```powershell
function Get-PidOnPort {
    param([int]$Port)
    $line = netstat -ano | Select-String -Pattern (":{0}\s+.*LISTENING\s+(\d+)\s*$" -f $Port)
    if ($line -and $line.Matches.Count -gt 0) { return [int]$line.Matches[0].Groups[1].Value }
    return $null
}
```

## 3. Windows: найти процессы по маске командной строки
```powershell
function Get-NodeProcsByCmd {
    param([string]$Pattern)
    $out = @()
    $nodes = Get-CimInstance Win32_Process -Filter "Name='node.exe'" -ErrorAction SilentlyContinue
    foreach ($p in $nodes) {
        if ("$($p.CommandLine)" -match $Pattern) { $out += $p }
    }
    return $out
}
```

## 4. Windows: остановить по PID (с проверкой)
```powershell
function Stop-PidSafe {
    param([int]$ProcId, [string]$Reason = "")
    if ($ProcId -le 4) { Write-Host "REFUSE pid=$ProcId (system)"; return $false }
    try {
        $p = Get-Process -Id $ProcId -ErrorAction Stop
        $name = $p.ProcessName
        if ($name -in @('explorer','winlogon','csrss','services','lsass')) {
            Write-Host "REFUSE pid=$ProcId name=$name (system)"; return $false
        }
        Write-Host ("KILL pid={0} name={1} reason={2}" -f $Pid, $name, $Reason)
        Stop-Process -Id $ProcId -Force -ErrorAction Stop
        return $true
    } catch {
        Write-Host "WARN kill pid=$ProcId : $($_.Exception.Message)"
        return $false
    }
}
```

## 5. Windows: остановить по порту
```powershell
function Stop-PortSafe {
    param([int]$Port, [string]$Reason = "")
    $p = Get-PidOnPort -Port $Port
    if (-not $p) { Write-Host "port $Port free"; return $false }
    return (Stop-PidSafe -ProcId $p -Reason ("port " + $Port + " " + $Reason))
}
```

## 6. Windows: остановить по маске командной строки
```powershell
function Stop-NodeByCmdSafe {
    param([string]$Pattern, [string]$Reason = "")
    $procs = Get-NodeProcsByCmd -Pattern $Pattern
    $killed = 0
    foreach ($p in $procs) {
        if (Stop-PidSafe -ProcId $p.ProcessId -Reason ("cmd " + $Pattern + " " + $Reason)) { $killed++ }
    }
    return $killed
}
```

## 6.1 Windows: мягко, затем жёстко (graceful -> force)
```powershell
function Stop-PidGraceful {
    param([int]$ProcId, [int]$WaitSec = 3)
    if ($ProcId -le 4) { return $false }
    try { Stop-Process -Id $ProcId -ErrorAction Stop } catch { return $false }
    for ($i=0; $i -lt $WaitSec; $i++) {
        Start-Sleep -Seconds 1
        if (-not (Get-Process -Id $ProcId -ErrorAction SilentlyContinue)) { return $true }
    }
    return (Stop-PidSafe -ProcId $pid -Reason "graceful-timeout")
}
```

## 7. *nix-эквивалент (Git Bash / Linux)
```bash
ss -ltnp 2>/dev/null | grep ':3108 ' || lsof -iTCP:3108 -sTCP:LISTEN -n -P
kill -TERM "$PID" 2>/dev/null; sleep 2; kill -KILL "$PID" 2>/dev/null
pgrep -af 'asuse-ai-meta-min' | awk '{print $1}' | xargs -r kill -TERM
```

## 8. Логирование (RULES §3)
Все KILL пишутся в terminal.log и CHANGES.txt артефакта:
KILL pid=12345 name=node reason="port 3108 stale"
KEEP: $DIR — обязателен.

## 9. Проверка после kill
```powershell
Start-Sleep -Seconds 2
$p = Get-PidOnPort -Port $Port
if ($p) { Write-Host "STILL LISTENING pid=$p" } else { Write-Host "FREE port=$Port" }
```

## 10. Типичные сценарии (asuse)
- gateway-min на 3100 -> Stop-PortSafe -Port 3100 -Reason "gateway restart"
- meta-min на 3108 -> Stop-PortSafe -Port 3108 -Reason "meta restart"
- зависший node index.js в asuse-ai-meta-min -> Stop-NodeByCmdSafe -Pattern 'asuse-ai-meta-min' -Reason 'stale'
- npm run start в asuse-ai-meta-min -> Stop-NodeByCmdSafe -Pattern 'asuse-ai-meta-min'

## 11. Антипаттерны (из реальных сессий)
- Stop-Process -Name node — убьёт ВСЕ node (vite, storybook, ESLS, WebStorm). НЕЛЬЗЯ.
- taskkill /IM node.exe /F — то же.
- Убийство PID 4 (System) — BSOD. НЕЛЬЗЯ.
- Убийство explorer.exe — рабочий стол пропадёт. НЕЛЬЗЯ.
- Убийство процесса, который держит чужой проект (Chat-Stream-Monitor, front-asuse-ai-infoenergo) — только с подтверждения.

## 12. Шаблон найти -> подтвердить -> убить -> проверить
```powershell
$pt = 3108
$p = Get-PidOnPort -Port $pt
if ($p) {
    $cim = Get-CimInstance Win32_Process -Filter "ProcessId=$p" -ErrorAction SilentlyContinue
    Write-Host ("FOUND pid={0} cmd={1}" -f $p, "$($cim.CommandLine)")
    Stop-PidSafe -ProcId $p -Reason "explicit restart" | Out-Null
    Start-Sleep -Seconds 2
    if (Get-PidOnPort -Port $pt) { Write-Host "STILL BUSY :$pt" } else { Write-Host "FREE :$pt" }
} else { Write-Host "FREE :$pt" }
```

## 13. Когда скилл обязателен
- Перед рестартом любого сервиса (gateway-min, meta-min, auth, admin).
- При EADDRINUSE — сначала Get-PidOnPort, потом Stop-PidSafe.
- При зависшем node index.js в проекте — Stop-NodeByCmdSafe по маске пути.

## 14. Связь с RULES
- §2: без kill $$, set -e, exit.
- §3: логи только append, KEEP артефактов.
- §7: WARN вместо FATAL.
- §17: Windows + PowerShell 5.1, скрипты через -File.
