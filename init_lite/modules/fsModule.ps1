# file system module

. "$myScriptRoot\modules\includes\init_lite_filesystem.ps1"

# threshold in percent
Function myFsChkDriveUsage($driveId,$metric,$threshold,$computerName) {
   
  if (-not $computerName) {

    $computerName = "localhost"

  }

  if (-not $threshold) { return $false }


  $drive = myGetDriveInfo $driveId $computerName

  if ($metric -eq "pct") {
  
    $percentFull = myGetDrivePercentFull $drive $computerName

    if (($percentFull) -ge $threshold) {
  
      return "{0:N2}" -f $percentFull

    }
  
  }

  if ($metric -eq "bytes") {

    $driveFreeSpace = myGetDriveFreeSpace($drive)

    if ($driveFreeSpace -le $threshold) {

      return $driveFreeSpace

    }

  }

  return $false

}

Function myFsChkBakDriveSpace() {

}

Function myFsChkJobsFolderSpace() {


}

Function myFsChkDbSpace() {

  # sql module

}

# just wraps myGetDrives for the momment
Function myFsGetDrives() {

  return myGetDrives

}
