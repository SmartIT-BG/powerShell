# admin@smartit.bg
#
# To run your program, you must supply scriptFile arg
# to this script, otherwise it will only report current day status

param(
  [string]$scriptFile="rundll32",
  [string]$runOnLastOfMonth="Off",
  [string]$runOnFirstOfMonth="Off"

)

if ($PSVersionTable.PSVersion.Major -le 3) {

  $myScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent

} else {

  $myScriptRoot = $PSScriptRoot

}

# search in current directory if path does not exists
if ((Test-Path -Path $scriptFile) -eq $false) {

  if ((Test-Path -Path "$myScriptRoot\$scriptFile") -eq $true) {

    $scriptFilePath = "$myScriptRoot\$scriptFile"

  } else {

    $scriptFilePath = $scriptFile

  }

} else {

  $scriptFilePath = $scriptFile

}

# get current month
$currMonth = Get-Date -Format MM

# did we are close to the next month 
$nextMonth = $(Get-Date -Hour 23 -Minute 59 -Second 59).AddSeconds(1) | Get-Date -Format MM

# first of month
$fistOfMonth = $(Get-Date -Hour 00 -Minute 00 -Second 00).AddSeconds(-1) | Get-Date -Format MM


if ($currMonth -eq $nextMonth) {
  
  if  ($currMonth -ne $fistOfMonth) {

    if ($runOnFirstOfMonth -eq "Off") {
      
      Write-Host "Today is first day of the month and runOnFirstMonth switch is Off"
      Write-Host "Terminating..."
      
      Return

    }

  }
  
  Write-Host "Today is not last day of the month"
  Write-Host "Starting process $scriptFilePath"

  Start-Process $scriptFilePath
       
} else {

   if ($runOnLastOfMonth -eq "On") {

    Write-Host "Today is last day of the month"
    Write-Host "Starting process $scriptFilePath"

    Start-Process $scriptFilePath

  } else {

    if ($runOnLastOfMonth -eq "Off") {

      Write-Host "Today is last day of the month and runOnLastOfMonth switch is Off"
      Write-Host "Terminating..."

      Return

    }

  }

}
