# Task Schduler Folder Sync v0.1a
# Synchronize Task Scheduler Folder from local server to remote server
# admin@smartit.bg

# Usage Example: sync_tasksch_folder.ps1 EcheckTasks nebula.easycredit.bg
# or sync_tasksch_folder.ps1 -syncFolder "EcheckTasks" -remoteServer "nebula.easycredit.bg"
# DA SE STARTIRA S HIGHEST PRIVILEGES ili Run As Administrator
# Iziskva PS versia >= 2.0


# todo:
# (1) - da se vzeme predvid s koy akaunt se startira taska i da se podade pri update/sazdavane na task
#   na otdalechenata mashina, inache taska shte bade sazdaden/updatnat sas start account po podrazbirane s DOMAIN\task
# 1K - Korekcia. Da se pazi tablica sas tekushtite zadachite i tiahnoto sastoianie na sinhronizacia.
#   SYNC(true,false),DESC(ERRID-1(account missmatch),99(Unknown)),EMAILED (true,false)
# 2 - Da se hvashtat exception-i (niama vrazka sas server, niama dostatachno privilegii i t.n.
# 3 - Da se sazdade logging mehanizam
# 4 - Da podobrim saobshteniata v konzola
# 5 - Da se kopira sddl
# 6 - Rekursivno izvikvane?
# 7 - Compare metod - xml,lastwritetime,task history


param(
  $syncFolder,
  $remoteServer

)

# Treat non-terminating errors as terminating
$ErrorActionPreference = "Stop"

if(($syncFolder -eq $null) -or ($remoteServer -eq $null)) { 
  Write-Host "`nMissing Parameters -syncFolder -serverName"

  Return

}


$windowsTasksFolder = "Windows\system32\Tasks\"
$remoteWindowsTasksFolder = "Windows\system32\Tasks\"
$systemDrive = "C:\"
$remoteSystemDrive = "C:\"

# Include functions for schedule.service COM object
. "$PSScriptRoot\schedule_service.ps1"
. "$PSScriptRoot\sync_tasksch_sqlite.ps1"
. "$PSScriptRoot\sync_tasksch_common.ps1"


# Proverka dali Task direktoriata sashtestvuva

try {

  New-taskObject -path "\$syncFolder" | Out-Null

}
Catch {

  Write-Host "`nCannot find $syncFolder folder on local. Stop Here.`n"
  Return

}

try {

  New-taskObject -path "\$syncFolder" -remoteServer "$remoteServer" | Out-Null

}
Catch {

  Write-Host "`nCannot find $syncFolder folder on remote. Creating it...`n"

  try {

    New-TaskFolder -folder (New-taskObject -path "\" -remoteServer $remoteServer) `
                   -path $syncFolder | Out-Null
  }
  Catch {
    
    Write-Host "`n-Error creating task folder on remote (permission problems?)... exiting"
    Return

  }

}

$remoteSyncFolderPath = "\\{0}\{1}{2}{3}" -f $remoteServer,$remoteSystemDrive.Replace(":", "$"), `
                                             $remoteWindowsTasksFolder,$syncFolder

$localSyncFolderPath = "{0}{1}{2}" -f $systemDrive,$windowsTasksFolder,$syncFolder


try {
 
  $remoteTaskFiles = Get-ChildItem $remoteSyncFolderPath

}
Catch {
  
  Write-Host "`nCannot list remote path $remoteSyncFolderPath" -ForegroundColor Red
  Return

}


try {

  $localTaskFiles = Get-ChildItem $localSyncFolderPath

}
Catch {

  Write-Host "`nCannot list local path $remoteSyncFolderPath" -ForegroundColor Red
  Return

}


#$netBIOSDomainName = (Get-ADDomain -Identity (Get-WmiObject Win32_ComputerSystem).Domain).NetBIOSName

# Get Credentials

# $startUserCredentials = New-Object System.Management.Automation.PSCredential `
#                                   -ArgumentList "$netBIOSDomainName\, $SecurePassword

Write-Host "`nStart syncing $localSyncFolderPath to $remoteSyncFolderPath`n"

$matchCount = 0
$notMatchCount = 0
$anyChanges = $false


if($localTaskFiles) {

# sinhronizray v posoka ot local kam remote
# proverka samo dali ima nov task
ForEach ($localTaskFile in $localTaskFiles)
{
  $remoteTaskFilePath = "{0}\{1}" -f $remoteSyncFolderPath,$localTaskFile.Name

  if(-not (Test-Path $remoteTaskFilePath)) {
    #sazdavame task-a ako lipsva

    Write-Host "`n$($localTaskFile.Name) is missing on remote task folder... createing"

    # proverka za UserId
    $taskDefinition = myGet-Task-Definition -folder (New-TaskObject -path "\$syncFolder") -taskName $localTaskFile.Name
    
    #if($taskDefinition.Principal.UserId -ne "$netBIOSDomainName\task") {
    #  Write-Host "`n-The task UserId is not expected one!"
    #
      # da vzemem NetBIOSName
    #  Write-Host "-The task will be created to run with $netBIOSDomainName\task account!`n"

    #}

    # deaktivirane na zadachata!
    $taskSettings = $taskDefinition.Settings
    $taskSettings.Enabled = $false

    $credentials = myRead-Credentials $taskDefinition.Principal.UserId

    try {
      
      $registeredTask = myRegisterTask  -folder (New-TaskObject -path "\$syncFolder" -remoteServer $remoteServer) `
                                        -taskName $($localTaskFile.Name) `
                                        -xmlText $($taskDefinition.XmlText) `
                                        -credentials $credentials
                                        #-xmlText (Get-Task-XML (New-TaskObject -path "\$syncFolder") `
                                        #-taskName $($localTaskFile.Name))

    }
    Catch {

      Write-Host "`nError creating task on remote... exiting" -ForegroundColor Red
      Write-Host "Possible permission is not granted." -ForegroundColor Red
      Return

    }

    # Izhackai Remote Task Scheduler da sazdade faila
    Start-Sleep -s 10

    #proverka dali faila e sazdaden, ako da smeni LastWriteTime

    $remoteTaskFile = Get-Item $remoteTaskFilePath
    $remoteTaskFile.LastWriteTime = $localTaskFile.LastWriteTime

    $anyChanges = $true

  }

}

}
else {
  Write-Host "`nLocal task folder is empty...`n"
}

if($remoteTaskFiles) { 

# sinhroniziray v posoka ot remote kam local
ForEach ($remoteTaskFile in $remoteTaskFiles)
{
  $localTaskFilePath = "{0}\{1}" -f $localSyncFolderPath,$remoteTaskFile.Name

  if(-not (Test-Path $localTaskFilePath)) {
    
    Write-Host "`n$($remoteTaskFile.Name) dose not exist locally. deleting it..."
    
    # Call DeleteTask
    try {

      myDeleteTask -folder (New-TaskObject -path "\$syncFolder" -remoteServer $remoteServer) -taskName $remoteTaskFile.Name
    
    }
    Catch {

      Write-Host "`nError deleting task on remote... exiting" -ForegroundColor Red
      Write-Host "Possible permission is not granted." -ForegroundColor Red
      Break

    }

    $anyChanges = $true

  }
  else {

    $localTaskFile = Get-Item $localTaskFilePath

    if($remoteTaskFile.LastWriteTime -ne $localTaskFile.LastWriteTime) { 

      # ako ima obnoviavane na localTaskFile, to
      # obnovi remoteTaskFile ot localTaskFile XML
      # ako ok, to obnovi LastWriteTime da savpada s local LastWriteTime
      # zapishi v loga obnnoviavaneto


      Write-Host "Remote file $($remoteTaskFile.Name) LastWriteTime is different from local file LastWriteTime... Updating definition and fixing LastWriteTime"

      # remote task definition
      #$taskDefinitionRemote = myGet-Task-Definition -folder (New-TaskObject -path "\$syncFolder" -remoteServer $remoteServer) `
      #                                        -taskName $($remoteTaskFile.Name)

      # local task definition
      $taskDefinitionLocal = myGet-Task-Definition -folder (New-TaskObject -path "\$syncFolder") `
                                                   -taskName $($localTaskFile.Name)

      # proveri definiciata na lokalnia task
      #if($taskDefinitionLocal.Principal.UserId -ne "$netBIOSDomainName\task") {
      #  Write-Host "`n-The task UserId is not expected one!"

      #  Write-Host "-The task will be modified to run with $netBIOSDomainName\task account!`n"

      #}

      # deaktivirane na zadachata!
      $taskSettings = $taskDefinitionLocal.Settings
      $taskSettings.Enabled = $false


      $credentials = myRead-Credentials $taskDefinitionLocal.Principal.UserId

      try {

        $registeredTask = myRegisterTask -folder (New-TaskObject -path "\$syncFolder" -remoteServer $remoteServer) `
                                         -taskName $($remoteTaskFile.Name) `
                                         -xmlText $($taskDefinitionLocal.XmlText) `
                                         -credentials $credentials
                                         #-xmlText (Get-Task-XML (New-TaskObject -path "\$syncFolder") `
                                         #-taskName $($remoteTaskFile.Name))
      }
      Catch {

        Write-Host "`nError updating task on remote... exiting" -ForegroundColor Red
        Write-Host "Possible permission is not granted." -ForegroundColor Red
        Break

      }

      # obnovi LastWriteTime
      $remoteTaskFile.LastWriteTime = $localTaskFile.LastWriteTime

      $anyChanges = $true

    }
    else {
 
      # zapishi v loga savpadenie

    }

  }

}

}

if (-not $anyChanges) { Write-Host "`n..Nothing to do`n" }
