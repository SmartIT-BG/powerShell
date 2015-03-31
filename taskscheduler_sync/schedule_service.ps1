# schedule.service help functions v0.1a
#
# Da izpolzvame class?
#
# Reference
# http://msdn.microsoft.com/en-us/library/windows/desktop/aa383607(v=vs.85).aspx

Function Get-ScheduleService
{
  New-Object -ComObject schedule.service

}


# Vazmoznosht za podavane na credentials?
# For Backward compatability
#
Function New-TaskObjectRemote($path,$server)
{ 
  $taskObject = Get-ScheduleService
  $taskObject.Connect($server)

  if(-not $path) { $path = "\" }
    $taskObject.GetFolder($path)

}

# Vazmoznosht za podavane na credentials?
Function New-TaskObject($path,$remoteServer)
{ 
  $taskObject = Get-ScheduleService

  if(-not $remoteServer) {
    $taskObject.Connect()

   }
   else {
     $taskObject.Connect($remoteServer)

   }

  if(-not $path) { 
    $path = "\" 
  
  } else {
    $path = "\$path"

  }
  
  $taskObject.GetFolder($path)

}

Function Get-TaskFolder($folder,[switch]$recurse)
{
  if($recurse)
  {
    $colFolders = $folder.GetFolders(0)
    
    ForEach($i in $colFolders)
    {
      $i.path
      $subFolder = (New-taskObject -path $i.path)
      Get-taskFolder -folder $subFolder -recurse
    
    }

  }
  else
  {
    $folder.GetFolders(0) |
    ForEach-Object { $_.path }

  }

}

Function New-TaskFolder($folder,$path)
{
   $folder.createFolder($path)

}

Function Remove-TaskFolder($folder,$path)
{
  $folder.DeleteFolder($path,$null)

}

Function Get-Task-Count($folder)
{
  $taskCollection = $folder.GetTasks(0)
  $taskCollection.Count

}

Function Get-Task-List($folder)
{

  $taskCollection = $folder.GetTasks(0)

  ForEach($registeredTask in $taskCollection)
  {
    #$registeredTask | Get-Member -MemberType Property

  }

}


# Registrira Task. Ako sashtestvuva go obnoviava
Function myRegisterTask($folder,$taskName,$xmlText,$credentials)
{
  $registeredTask = $null

  $userName = $credentials.UserName
  $password = $credentials.GetNetworkCredential().Password

  $folder.RegisterTask($taskName,$xmlText,0x6,$username, `
                       $password,1,$registeredTask)

  return $registeredTask

}

Function myDeleteTask($folder,$taskName)
{
  #proverka, dali zadachata sashtestvuva

  $folder.DeleteTask($taskName,0)

}

Function Get-Task-XMl($folder,$taskName)
{
  $task = $folder.GetTask($taskName)

  return [string]$task.XML

}


Function myGet-Task-Definition($folder,$taskName)
{

  $registeredTask = $folder.GetTask($taskName)
  
  # Vrazshta UserId chrez koyto se startira zadachata
  $taskDefinition = $registeredTask.Definition

  Return $taskDefinition

}

# examples

#Get-Task-XMl -folder (New-TaskObject)

# Try to copy task from local machine to remote
#myRegisterTask -folder (New-TaskObjectRemote -server "acme.intranet") -taskName "test1" -xmlText (Get-Task-XML (New-TaskObject))
#myDeleteTask -folder (New-TaskObjectRemote -server "acme.intranet") -taskName "test1"
#Get-TaskFolder -folder (New-taskObject -path "\microsoft")
#Get-TaskFolder -folder (New-taskObject -path "\microsoft") -recurse 
#New-TaskFolder -folder (New-taskObject -path "\microsoft")
#Remove-TaskFolder -folder (New-taskObject -path "\microsoft")
#Get-Task-Count -folder (New-taskObjectRemote -path "\MyTasks")
#Get-Task-List -folder (New-TaskObjectRemote -path "\Test")
#(New-taskObject -path "\non-existing-folder")