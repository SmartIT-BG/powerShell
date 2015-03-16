# Symantec Endpoint Protection batch install
# admin@smartit.bg

param(
  [string]$computerList="computer-list.txt",
  [string]$symPkgUNC="unknown",
  # (1) PS Remoting with double hop (CredSSP)
  # (2) PS Remoting with admin share - NOT IMPLEMENTED
  [int]$pkgDownloadType=1

)

if ($PSVersionTable.PSVersion.Major -le 3) {

  $myScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent

} else {

  $myScriptRoot = $PSScriptRoot

}

. "$myScriptRoot\sep_includes.ps1"


$todayDate = Get-Date -Format "yyyyMMdd"
$logFile = "$myScriptRoot\install-log-$todayDate.txt"

$computerNamesFile = "$myScriptRoot\$computerList"

if (-not (Test-Path $computerNamesFile)) {
  Write-Host "You must provide valid computer list file name."
  Exit 1

}

# Symantec MSI package UNC path
#$symPkg = "\\eamdc.easycredit.bg\public_share\Sym\Sep64.msi"

$symPkg = $symPkgUNC

if (-not (Test-Path -Path $symPkg)) {
  Write-Host "You must provide valid package UNC path."
  Exit 1

}

Write-Host

Write-Host "Computer list file: $computerNamesFile"
Write-Host "Package: $symPkg"

Write-Host

# Get computer names list
$computerNames = Get-Content $computerNamesFile

# Get user credentials
$userCredentials = Get-Credential

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

    Write-Host "Ping successful. Creating install session..."

    if ($pkgDownloadType -eq 1) {
      $psSession = New-PSSession -ComputerName $computerName -Authentication Credssp -Credential $userCredentials

    } elseif ($pkgDownloadType -eq 2) {
      $psSession = New-PSSession -ComputerName $computerName

    }
  } else {

    $message = "Computer $computerName is not reachable"
    $message

  }

  $result = $null

  if ($psSession) {

    if (($psSession.State -eq "Opened") -and ($psSession.Availability -eq "Available")) {

    Write-Host "Install session is ready. Starting install process... It can take a while."
      
      $result = Invoke-Command -Session $psSession -ArgumentList "$symPkg" -ScriptBlock {

        $symProduct = Get-WmiObject -Class Win32_Product -Filter "Name = 'Symantec Endpoint Protection'"

        if ($symProduct) {
          $message = "Symantec Endpoint Protection is already installed with version $($symProduct.Version)"
          $message

          Exit 1

        }

        $symPkg = $args[0]

        $installResult = Start-Process -PassThru -Wait -FilePath "msiexec" -ArgumentList "/i $symPkg /quiet /norestart"

        if ($installResult.ExitCode -eq 0) {
          $message = "Install for this computer is successful"
          $message

        } else {
          $message = "Install for this computer failed with exit code $($installResult.ExitCode)"
          $message

        }

      }

    }

    Remove-PSSession $psSession
    $psSession = $null

  }

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
