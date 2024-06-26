Set-Alias workday Power-History-Today
Set-Alias workweek Power-History
function Power-History-Today {
    Power-History -DaysFromToday 1
}
function Power-History {
    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [int]       $DaysFromToday = 7,
 
        [int]       $MaxEvents = 9999
    )
 
    BEGIN {}
 
    PROCESS {
            try {
                $Computer = $env:COMPUTERNAME.ToUpper()
                $EventList = Get-WinEvent -ComputerName $Computer -FilterHashtable @{
                    Logname = 'system'
                    Id = '1074', '6008', '42', '4647', '4624', '27'
                    StartTime = (Get-Date).AddDays(-$DaysFromToday)
                } -MaxEvents $MaxEvents -ErrorAction Stop

                foreach ($Event in $EventList) {
                    if ($Event.Id -eq 1074) {
                        [PSCustomObject]@{
                            TimeStamp = $Event.TimeCreated
                            State = '-'
                            Action = $Event.Properties.value[4]
                        }
                    }

                    if ($Event.Id -eq 4647) {
                        [PSCustomObject]@{
                            TimeStamp    = $Event.TimeCreated
                            State = '-'
                            Action = 'logoff'
                        }
                    }

                    if ($Event.Id -eq 4624) {
                        [PSCustomObject]@{
                            TimeStamp    = $Event.TimeCreated
                            State = '+'
                            Action = 'logon'
                        }
                    }

                    if ($Event.Id -eq 27 -And $Event.Properties.value[0] -eq 2) {
                        [PSCustomObject]@{
                            TimeStamp    = $Event.TimeCreated
                            State = '+'
                            Action = 'wake'
                        }
                    }

                    if ($Event.Id -eq 27 -And $Event.Properties.value[0] -eq 0) {
                        [PSCustomObject]@{
                            TimeStamp = $Event.TimeCreated
                            State = '+'
                            Action = 'boot'
                        }
                    }

                    if ($Event.Id -eq 42) {
                        [PSCustomObject]@{
                            TimeStamp    = $Event.TimeCreated
                            State = '-'
                            Action = 'sleep'
                        }
                    }

                    if ($Event.Id -eq 6008) {
                        [PSCustomObject]@{
                            TimeStamp = $Event.TimeCreated
                            State = '-'
                            Action = 'unexpected shutdown'
                        }
                    }
 
                }
 
            } catch {
                Write-Error $_.Exception.Message
            }
    }
 
    END {}
}
function aliases {
    Compare-Object (Get-Alias) (PowerShell -NoProfile {Get-Alias}) -Property Name |sort Name
}
function functions { Get-ChildItem function:\ }
function Trust-Certs { dotnet dev-certs https --trust }
function Clean-Solution { Get-ChildItem -inc bin,obj -rec | Remove-Item -rec -force }
function update-visual-studio
(
	[string]$path
)
{
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

Invoke-Expression (&starship init powershell)
Invoke-Expression (& { (zoxide init powershell | Out-String) })
