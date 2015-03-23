# init_lite
#
# admin@smartit.bg

# todo
#
# - threading (backgrouond jobs)
# - error catching


if ($PSVersionTable.PSVersion.Major -le 3) {

  $myScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent

} else {

  $myScriptRoot = $PSScriptRoot

}

# load configuration file

$xmlConfig = [xml](Get-Content "$myScriptRoot\configuration.xml")

# CONFIGURATION SECTION

$productVersion = $xmlConfig.Configuration.Version.ProductVersion
$powerShellVersion = "PS v$($PSVersionTable.PSVersion.Major).$($PSVersionTable.PSVersion.Minor)"

$smtpServer = $xmlConfig.Configuration.Contact.Smtp.Server
$smtpFrom = $xmlConfig.Configuration.Contact.Smtp.From
$smtpTo = $xmlConfig.Configuration.Contact.Smtp.To
$smtpCredentialsFile = $xmlConfig.Configuration.Contact.Smtp.CredentialsFile

# END CONFIGURATION SECTION

#. "$myScriptRoot\includes\init_lite_network.ps1"
. "$myScriptRoot\init_contact.ps1"

. "$myScriptRoot\modules\fsModule.ps1"
. "$myScriptRoot\modules\dbModule.ps1"
. "$myScriptRoot\modules\svcModule.ps1"

# main

# check drives
#

# call on critical event
$doCall = $false

# CPU Usage. Run measure on background
$cpuUsageJob = Start-Job -ScriptBlock { 

  (get-counter -Counter "\Processor(_Total)\% Processor Time" -SampleInterval 2 -MaxSamples 15 `
  | select -ExpandProperty countersamples | select -ExpandProperty cookedvalue `
  | Measure-Object -Average).average 

}

foreach ($volume in $xmlConfig.Configuration.Volumes.Volume) {
  
  if ($volume.Active -eq "True") {
    
    if ($volume.Type -eq "Remote") {

      $remoteComputerVolume = $volume.ComputerName

    } else {

      $remoteComputerVolume = "localhost"

    }

    if ( ($driveUsagePct = myFsChkDriveUsage $volume.Id "pct" $volume.UsageThreshold $remoteComputerVolume) -or `
         ($driveUsageSize = myFsChkDriveUsage $volume.Id "bytes" $volume.SizeThreshold $remoteComputerVolume) ) 

    {
      
      $volumePurpose = ($volume.Purpose).Split(",")
      # todo: strip whitespaces

      if ($volumePurpose -contains "Backup") {
        
        # continue if backup is in progress
        if ( myDbBackupInProgress ) { $dbBackupContinue = $true }
        
        # continue if Agent backup job is in progress
        # if it is not defined in configuration we can expect call :)
        foreach ($agentJob in $xmlConfig.Configuration.MSSQL.Agent.Jobs.Job) {
          
          if ($agentJob.Active -eq "False") { Continue }

          if ($agentJob.Purpose -eq "Backup") {
          
            if ( myDbChkAgentJobStatus($agentJob.Name) ) { $dbBackupContinue = $true }
          
          }

        }

        if ($dbBackupContinue) { Continue }
      
      }


      if ($volume.Type -eq "Remote") {

        $smtpBodyAdditional = "Additional Info: This is remote drive of machine $($volume.ComputerName)"
      
      } else {

        $smtpBodyAdditional = "Additional Info: n/a"
      
      }


      $smtpSubject = "(Emergency event) from $env:COMPUTERNAME"

      if (-not $driveUsagePct) { $driveUsagePct = "(not reached)" }
      if (-not $driveUsageSize) { $driveUsageSize = "(not reached)" }

      $smtpBody = @"
Event trigger: Drive $($volume.Id) usage threshold of $($volume.UsageThreshold)% reached with value $driveUsagePct or
               usage threshold of $($volume.SizeThreshold) bytes reached with value $driveUsageSize

$smtpBodyAdditional

$productVersion
$powerShellVersion
"@

      mySendMail $smtpTo $smtpFrom $smtpSubject $smtpBody $smtpServer $smtpCredentialsFile

      $doCall = $true

    }

  }

}

# Check services

foreach ($svc in $xmlConfig.Configuration.WindowsServices.Service) {
  
  $svcStatus = mySvcChkState $svc.Name

  if ($svc.Active -eq "True") {
    
    if ($svcStatus -ne "Running") {
    
      if (-not $svcStatus) {
    
        $svcStatus = "Not Registered"

      }

      $smtpSubject = "(Emergency event) from $env:COMPUTERNAME"

      $smtpBody = @"
Event trigger: Service $($svc.Name) have unexpected status - $svcStatus

$productVersion
$powerShellVersion
"@

      mySendMail $smtpTo $smtpFrom $smtpSubject $smtpBody $smtpServer $smtpCredentialsFile

      $doCall = $true

    }

  }

}


# Check SQL Server Linked Servers

foreach ($lnkdSrv in $xmlConfig.Configuration.MSSQL.LinkedServers.LinkedServer) {
  
  if ($lnkdSrv.Active -eq "True") {

    if (-not (myDbChkLinkedServer $lnkdSrv.Name)) {
      
      $smtpSubject = "(Emergency event) from $env:COMPUTERNAME"

      $smtpBody = @"
Event trigger: SQL Server LinkedServer $($lnkdSrv.Name) is not accessible

$productVersion
$powerShellVersion
"@

      mySendMail $smtpTo $smtpFrom $smtpSubject $smtpBody $smtpServer $smtpCredentialsFile
      $doCall = $true

    }

  }

}

# exit SqlServer provider
Set-Location C:

# IIS

if ((Get-Module -ListAvailable | Where-Object { $_.Name -eq "WebAdministration" })) {
  
  Import-Module WebAdministration

  # AppPools
  foreach ($iisAppPool in $xmlConfig.Configuration.IIS.AppPools.AppPool) {
    
    if ((Get-WebAppPoolState $iisAppPool.Name).Value -ne "Started") {

      $smtpSubject = "(Emergency event) from $env:COMPUTERNAME"

      $smtpBody = @"
Event trigger: IIS AppPool $($iisAppPool.Name) is not in started state or does not exist

$productVersion
$powerShellVersion
"@

      mySendMail $smtpTo $smtpFrom $smtpSubject $smtpBody $smtpServer $smtpCredentialsFile
      $doCall = $true

    }

  }

  # Sites

  foreach ($iisSite in $xmlConfig.Configuration.IIS.Sites.Site) {
    
    if ((Get-WebsiteState $iisSite.Name).Value -ne "Started") {

      $smtpSubject = "(Emergency event) from $env:COMPUTERNAME"

      $smtpBody = @"
Event trigger: IIS AppPool $($iisSite.Name) is not in started state or does not exist

$productVersion
$powerShellVersion
"@

      mySendMail $smtpTo $smtpFrom $smtpSubject $smtpBody $smtpServer $smtpCredentialsFile
      $doCall = $true

    }

  }

} else {

  Write-Host "IIS WebAdministration module is missing, skipping"

}


Wait-Job -Job $cpuUsageJob | Out-Null

$cpuUsage = Receive-Job -Job $cpuUsageJob

if ($xmlConfig.Configuration.CPU.Active -eq "True") {

  if ($cpuUsage -ge $xmlConfig.Configuration.CPU.UsageThreshold) {
  
    $smtpSubject = "(Emergency event) from $env:COMPUTERNAME"
    $smtpBody = @"
Event trigger: CPU Usage threshold of $($xmlConfig.Configuration.CPU.UsageThreshold) reached with $cpuUsage

$productVersion
$powerShellVersion
"@

    mySendMail $smtpTo $smtpFrom $smtpSubject $smtpBody $smtpServer $smtpCredentialsFile

    $doCall = $true

  }
}

# call logic

if ($doCall) { myCall }