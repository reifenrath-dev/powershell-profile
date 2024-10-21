function test-command-exists {
    param ($command)
    $oldPreference = $ErrorActionPreference
    $ErrorActionPreference = ‘stop’
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

Set-Alias workday Power-History-Today
Set-Alias workweek Power-History-This-Week
function Get-Power-History-Today {
    Power-History -StartTime (Get-Date).Date
}
function Get-Power-History-This-Week {
    Power-History -StartTime (Get-Date).Date.AddDays(1 - (Get-Date).Date.DayOfWeek.value__)
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
                    1074 {
                        [PSCustomObject]@{
                            TimeStamp = $Event.TimeCreated
                            State     = '-'
                            Action    = $Event.Properties.value[4]
                        }
                    }
                    4647 {
                        [PSCustomObject]@{
                            TimeStamp = $Event.TimeCreated
                            State     = '-'
                            Action    = 'logoff'
                        }
                    }
                    4624 {
                        [PSCustomObject]@{
                            TimeStamp = $Event.TimeCreated
                            State     = '+'
                            Action    = 'logon'
                        }
                    }
                    { $_ -eq 27 -And $Event.Properties.value[0] -eq 2 } {
                        [PSCustomObject]@{
                            TimeStamp = $Event.TimeCreated
                            State     = '+'
                            Action    = 'wake'
                        }
                    }
                    { $_ -eq 27 -And $Event.Properties.value[0] -eq 0 } {
                        [PSCustomObject]@{
                            TimeStamp = $Event.TimeCreated
                            State     = '+'
                            Action    = 'boot'
                        }
                    }
                    42 {
                        [PSCustomObject]@{
                            TimeStamp = $Event.TimeCreated
                            State     = '-'
                            Action    = 'sleep'
                        }
                    }
                    6008 {
                        [PSCustomObject]@{
                            TimeStamp = $Event.TimeCreated
                            State     = '-'
                            Action    = 'unexpected shutdown'
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
function aliases {
    Compare-Object (Get-Alias) (PowerShell -NoProfile { Get-Alias }) -Property Name | sort Name
}
function functions { Get-ChildItem function:\ }
function Trust-Certs { dotnet dev-certs https --trust }
function Clean-Solution { Get-ChildItem -inc bin, obj -rec | Remove-Item -rec -force }
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
