function test-command-exists($command) {
    $oldPreference = $ErrorActionPreference
    $ErrorActionPreference = 'stop'
    try {
        if (Get-Command $command) {
            return $true
        }
    }
    catch {
        Write-Host “$command does not exist”; return $false
    }
    finally {
        $ErrorActionPreference = $oldPreference
    }
}

function test-command-exists-silent($command) {
    $exists = $null -ne (Get-Command $command -ErrorAction SilentlyContinue)
    return $exists
}

$EDITOR = if (test-command-exists-silent vscodium) { 'vscodium' }
          elseif (test-command-exists-silent code) { 'code' }
          elseif (test-command-exists-silent notepad++) { 'notepad++' }
          else { 'notepad' }
Set-Alias edit $EDITOR

function reload-profile {
    & $profile
}
Set-Alias reload reload-profile

function today {
    Get-Power-History -StartTime (Get-Date).Date
}
function week {
    Get-Power-History -StartTime (Get-Date).Date.AddDays(1 - (Get-Date).Date.DayOfWeek.value__)
}
function Get-Power-History([DateTime]$StartTime = (Get-Date).Date) {
    $EventList = Get-WinEvent -FilterHashtable @{
        Logname   = 'system'
        Id        = '1074', '6008', '42', '4647', '4624', '27', '107', '566'
        StartTime = $StartTime
    }

    foreach ($Event in $EventList) {
        switch ($Event.Id) {
            # Source: User32
            # User initiated a shutdown
            # Shutdown type is logged as string in param5/Properties.value[4]
            1074 {
                [PSCustomObject]@{
                    TimeStamp = $Event.TimeCreated
                    State     = '-'
                    Action    = $Event.Properties.value[4]
                }
            }
            # Source: Kernel-Boot
            # Boot-Type: Cold Boot from Full Shutdown
            { $_ -eq 27 -And $Event.Properties.value[0] -eq 0 } {
                [PSCustomObject]@{
                    TimeStamp = $Event.TimeCreated
                    State     = '+'
                    Action    = 'boot'
                }
            }
            # Source: Kernel-Boot
            # Boot-Type: Fast Startup / Hybrid Boot
            { $_ -eq 27 -And $Event.Properties.value[0] -eq 1 } {
                [PSCustomObject]@{
                    TimeStamp = $Event.TimeCreated
                    State     = '+'
                    Action    = 'fast startup'
                }
            }
            # Source: Kernel-Boot
            # Boot-Type: Resume from Hibernation
            { $_ -eq 27 -And $Event.Properties.value[0] -eq 2 } {
                [PSCustomObject]@{
                    TimeStamp = $Event.TimeCreated
                    State     = '+'
                    Action    = 'wake'
                }
            }
            # Source: Kernel-Power
            # The system is entering sleep
            42 {
                [PSCustomObject]@{
                    TimeStamp = $Event.TimeCreated
                    State     = '-'
                    Action    = 'sleep'
                }
            }
            # Source: Kernel-Power
            # The system has resumed from sleep
            107 {
                [PSCustomObject]@{
                    TimeStamp = $Event.TimeCreated
                    State     = '+'
                    Action    = 'wake'
                }
            }
            # Source: Kernel-Power
            # Power off for an unknown reason
            { $_ -eq 566 -and $Event.Properties.value[1] -eq 1} {
                [PSCustomObject]@{
                    TimeStamp = $Event.TimeCreated
                    State     = '-'
                    Action    = 'unplug'
                }
            }
            # Source: EventLog
            # The previous system shutdown was unexpected
            # 6008 {
            #    [PSCustomObject]@{
            #        TimeStamp = $Event.TimeCreated
            #        State     = '+'
            #        Action    = 'startup after unexpected shutdown'
            #    }
            # }
            # A user successfully logged on to a computer
            4624 {
                [PSCustomObject]@{
                    TimeStamp = $Event.TimeCreated
                    State     = '+'
                    Action    = 'logon'
                }
            }
            # A user initiated the logoff process
            4647 {
                [PSCustomObject]@{
                    TimeStamp = $Event.TimeCreated
                    State     = '-'
                    Action    = 'logoff'
                }
            }
        }
    }
}
# Finds duplicated files in the current directory and sub-directories using their hashes.
# More info here: https://stackoverflow.com/a/58677703
function find-duplicates {
    Get-ChildItem -Recurse -File `
    | Group-Object -Property Length `
    | Where-Object{ $_.Count -gt 1 } `
    | ForEach-Object{ $_.Group } `
    | Get-FileHash `
    | Group-Object -Property Hash `
    | Where-Object{ $_.Count -gt 1 } `
    | ForEach-Object{ $_.Group }
}
function aliases {
    Compare-Object (Get-Alias) (PowerShell -NoProfile { Get-Alias }) -Property Name | sort Name
}
function functions { Get-ChildItem function:\ }
function edit-profile { edit $PROFILE.AllUsersAllHosts }

# -----------
# START: Dotnet Dev Functions
# -----------
function trust-certs { dotnet dev-certs https --trust }
function clean-solution { Get-ChildItem -inc bin, obj -rec | Remove-Item -rec -force }
function update-visual-studio([string]$path) {
    Start-Process -FilePath $path -ArgumentList "updateall --quiet --force"
}
# -----------
# END: Dotnet Dev Functions
# -----------

# -----------
# START: Aliases & Functions from https://github.com/ChrisTitusTech/powershell-profile
# -----------
Set-Alias ff find-file
function find-file($name) {
    Get-ChildItem -recurse -filter "*${name}*" -ErrorAction SilentlyContinue | ForEach-Object {
        $place_path = $_.directory
        Write-Output "${place_path}\${_}"
    }
}
function unzip ($file) {
    Write-Output("Extracting", $file, "to", $pwd)
    $fullFile = Get-ChildItem -Path $pwd -Filter .\cove.zip | ForEach-Object { $_.FullName }
    Expand-Archive -Path $fullFile -DestinationPath $pwd
}
function grep($regex, $dir) {
    if ( $dir ) {
        Get-ChildItem $dir | select-string $regex
        return
    }
    $input | select-string $regex
}
function touch($file) {
    "" | Out-File $file -Encoding ASCII
}
function pkill($name) {
    Get-Process $name -ErrorAction SilentlyContinue | Stop-Process
}
function pgrep($name) {
    Get-Process $name
}
# -----------
# END: Aliases & Functions from https://github.com/ChrisTitusTech/powershell-profile
# -----------

if(test-command-exists starship) { Invoke-Expression (&starship init powershell) }
if(test-command-exists zoxide) { Invoke-Expression (& { (zoxide init powershell | Out-String) }) }
