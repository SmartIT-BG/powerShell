# Symantec Endpoint Protection batch uninstall
# admin@smartit.bg

param(
  [string]$computerList="computer-list.txt",
  [string]$productName="Symantec Endpoint Protection"
)


if ($PSVersionTable.PSVersion.Major -le 3) {

  $myScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent

} else {

  $myScriptRoot = $PSScriptRoot

}

. "$myScriptRoot\sep_includes.ps1"

$todayDate = Get-Date -Format "yyyyMMdd"
$logFile = "$myScriptRoot\uninstall-log-$todayDate.txt"

$computerNamesFile = "$myScriptRoot\$computerList"

if (-not (Test-Path $computerNamesFile)) {
  Write-Host "You must provide valid computer list file name."
  Exit 1

}

Write-Host "Computer list file: $computerNamesFile"
Write-Host "Product name: $productName"

Write-Host

# Get computer names list
$computerNames = Get-Content $computerNamesFile


foreach ($computerName in $computerNames) {
  
  Write-Host "Working on computer $computerName"
  $connection = $false


  Write-Host "Testing ping with fallback port check to computer $computerName"
  if (Test-Connection -Quiet $computerName) {
    $connection = $true

  } else {

    # Try port check then
    $portCheck = Test-Port $computerName 135
    if ($portCheck.GetResponce) {

      $connection = $true

    }

  }

  if ($connection) {

    Write-Host "Ping successful. Creating uninstall session..."
    $psSession = New-PSSession -ComputerName $computerName

  } else {

    $message = "$computerName, is not reachable"
    $message

  }

  $result = $null

  if ($psSession) {

    if (($psSession.State -eq "Opened") -and ($psSession.Availability -eq "Available")) {

      Write-Host "Uninstall session is ready. Starting uninstall process..."
      
      $result = Invoke-Command -Session $psSession -ArgumentList $productName -ScriptBlock {

        $productName = $args[0]

        $symProduct = Get-WmiObject -Class Win32_Product -Filter "Name = '$productName'"

        if (-not $symProduct) {
          $message = "Symantec Endpoint Protection does not exists"
          $message

          Exit 1

        }

        $uninstallResult = $symProduct.Uninstall()

        if ($uninstallResult.ReturnValue -eq 0) {
          
          $message = "Uninstall for this computer is successful"
          $message

        } else {
          
          $message = "Uninstall for this computer failed with return code $($uninstallResult.ReturnValue)"
          $message

        }

      }

    } else {
      $message = "$computerName, PowerShell session is not operational."
      $message

    }

    Remove-PSSession $psSession
    $psSession = $null

  } else {
    $message = "$computerName, PowerShell session can't be established."
    $message

  }

  # Log result from remote session
  if($result) {
    Write-Host "$computerName, $result"
    $message = "$computerName, $result"

  }

  if (-not (Test-Path -Path $logFile)) {
    $message | Out-File -FilePath $logFile

  } else { 
    $message | Out-File -FilePath $logFile -Append 
    
  }

  Write-Host

}
