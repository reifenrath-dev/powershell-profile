function test-command-exists {
    param ($command)
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

function today {
    Get-Power-History -StartTime (Get-Date).Date
}
function week {
    Get-Power-History -StartTime (Get-Date).Date.AddDays(1 - (Get-Date).Date.DayOfWeek.value__)
}
function Get-Power-History {
    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [DateTime]  $StartTime = (Get-Date).Date,
 
        [int]       $MaxEvents = 9999
    )
 
    BEGIN {}
 
    PROCESS {
        try {
            $Computer = $env:COMPUTERNAME.ToUpper()
            $EventList = Get-WinEvent -ComputerName $Computer -FilterHashtable @{
                Logname   = 'system'
                Id        = '1074', '6008', '42', '4647', '4624', '27'
                StartTime = $StartTime
            } -MaxEvents $MaxEvents -ErrorAction Stop

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
                    # Source: EventLog
                    # The previous system shutdown was unexpected
                    6008 {
                        [PSCustomObject]@{
                            TimeStamp = $Event.TimeCreated
                            State     = '+'
                            Action    = 'startup after unexpected shutdown'
                        }
                    }
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
        catch {
            Write-Error $_.Exception.Message
        }
    }
 
    END {}
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
function trust-certs { dotnet dev-certs https --trust }
function clean-solution { Get-ChildItem -inc bin, obj -rec | Remove-Item -rec -force }
function update-visual-studio
(
    [string]$path
) {
    Start-Process -FilePath $path -ArgumentList "updateall --quiet --force"
}

# -----------
# START: Aliases & Functions from https://github.com/ChrisTitusTech/powershell-profile
# -----------
function edit-profile {
    edit $PROFILE.AllUsersAllHosts
}
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
