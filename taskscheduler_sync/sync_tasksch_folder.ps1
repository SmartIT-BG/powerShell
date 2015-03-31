# Windows Task Schduler folder sync
# Synchronizes 'Task Scheduler' folder from local server to remote server
#
# admin@smartit.bg

param(
  $localFolder,
  $remoteFolder,
  $remoteServer

)

# Treat non-terminating errors as terminating
$ErrorActionPreference = "Stop"

if(-not $remoteServer) { 
  Write-Host "`nMissing Parameters -syncFolder -serverName"
  #
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


# Check if local folder exists
if($localFolder) {
  try {    
    New-taskObject -path $localFolder | Out-Null

  }
  Catch {
    Write-Host "`nCannot find $localFolder folder locally. Stop Here.`n"
    Return

  }

}

# Check if remote folder exists. Create it otherwise.
if($syncFolder) {
  try {
    New-taskObject -path $syncFolder -remoteServer $remoteServer | Out-Null

  }
  Catch {
    Write-Host "`nCannot find $syncFolder folder on remote. Creating it...`n"

    try {
      New-TaskFolder -folder (New-taskObject -remoteServer $remoteServer) `
                     -path $syncFolder | Out-Null

    }
    Catch {
      Write-Host "`n-Error creating task folder on remote (permission problems?)... exiting"
      Return

    }

  }

}

$localSyncFolderPath = "{0}{1}{2}" -f $systemDrive,$windowsTasksFolder,$localFolder

$remoteSyncFolderPath = "\\{0}\{1}{2}{3}" -f $remoteServer,$remoteSystemDrive.Replace(":", "$"), `
                                             $remoteWindowsTasksFolder,$syncFolder



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

Write-Host "`nStart syncing $localSyncFolderPath to $remoteSyncFolderPath`n"

# Track changes
$anyChanges = $false

if($localTaskFiles) {

  # Sync from local to remote. Only checks for new tasks.
  ForEach ($localTaskFile in $localTaskFiles)
  {
    $remoteTaskFilePath = "{0}\{1}" -f $remoteSyncFolderPath,$localTaskFile.Name

    if(-not (Test-Path $remoteTaskFilePath)) {
      Write-Host "`n$($localTaskFile.Name) is missing on remote task folder... createing"

      # Check UserId
      $taskDefinition = myGet-Task-Definition -folder (New-TaskObject -path $localFolder) -taskName $localTaskFile.Name

      # Set the task to disabled state
      $taskSettings = $taskDefinition.Settings
      $taskSettings.Enabled = $false

      $credentials = myRead-Credentials $taskDefinition.Principal.UserId

      try {
        $registeredTask = myRegisterTask -folder (New-TaskObject -path $syncFolder -remoteServer $remoteServer) `
                                        -taskName $($localTaskFile.Name) `
                                        -xmlText $($taskDefinition.XmlText) `
                                        -credentials $credentials

      }
      Catch {
        Write-Host "`nError creating task on remote... exiting" -ForegroundColor Red
        Write-Host "Possible permission is not granted." -ForegroundColor Red
        Return

      }

      # Wait for remote task scheduler service to create the physical file
      Start-Sleep -s 10

      # Check if the file is created and change LastWriteTime
      $remoteTaskFile = Get-Item $remoteTaskFilePath
      $remoteTaskFile.LastWriteTime = $localTaskFile.LastWriteTime

      $anyChanges = $true

   }

}

} else {
  Write-Host "`nLocal task folder is empty...`n"

}

if($remoteTaskFiles) { 

  # Sync from remote to local
  ForEach ($remoteTaskFile in $remoteTaskFiles) {
    $localTaskFilePath = "{0}\{1}" -f $localSyncFolderPath,$remoteTaskFile.Name

    if(-not (Test-Path $localTaskFilePath)) {
    
      Write-Host "`n$($remoteTaskFile.Name) dose not exist locally. deleting it..."
    
      # Call DeleteTask
      try {
        myDeleteTask -folder (New-TaskObject -path "$syncFolder" -remoteServer $remoteServer) -taskName $remoteTaskFile.Name
    
      }
      Catch {
        Write-Host "`nError deleting task on remote... exiting" -ForegroundColor Red
        Write-Host "Possible credential is not granted." -ForegroundColor Red
        Break

      }

      $anyChanges = $true

    } else {
      $localTaskFile = Get-Item $localTaskFilePath

      if($remoteTaskFile.LastWriteTime -ne $localTaskFile.LastWriteTime) { 
        Write-Host "Remote file $($remoteTaskFile.Name) LastWriteTime is different from local file LastWriteTime... Updating definition and fixing LastWriteTime"

        # local task definition
        $taskDefinitionLocal = myGet-Task-Definition -folder (New-TaskObject -path "$localFolder") `
                                                     -taskName $($localTaskFile.Name)

        # Set the task to disabled state
        $taskSettings = $taskDefinitionLocal.Settings
        $taskSettings.Enabled = $false

        $credentials = myRead-Credentials $taskDefinitionLocal.Principal.UserId

        try {
          $registeredTask = myRegisterTask -folder (New-TaskObject -path "$syncFolder" -remoteServer $remoteServer) `
                                           -taskName $($remoteTaskFile.Name) `
                                           -xmlText $($taskDefinitionLocal.XmlText) `
                                           -credentials $credentials

        }
        Catch {
          Write-Host "`nError updating task on remote... exiting" -ForegroundColor Red
          Write-Host "Possible permission is not granted." -ForegroundColor Red
          Break

        }

        # Change remote task file LastWriteTime 
        $remoteTaskFile.LastWriteTime = $localTaskFile.LastWriteTime

        $anyChanges = $true

      } else {
 
        # log

      }

    }

  }

}

if (-not $anyChanges) { Write-Host "`n..Nothing to do`n" }
