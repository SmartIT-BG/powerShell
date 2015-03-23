
# level one functions

Function myGetDriveInfo($deviceID, $computerName) {
  
  if (-not $computerName) {
  
    $computerName = "localhost"
  
  }

  return Get-WmiObject win32_logicaldisk -ComputerName $computerName | Where-Object { $_.DeviceID -eq $deviceID }

 }


Function myGetDrives($computerName) {
  

  if (-not $computerName) {
    
    $computerName = "localhost"

  }

  return Get-WmiObject win32_logicaldisk -ComputerName $computerName

}


# level two functions

Function myGetDrivePercentFull($wmiDrive) {

  if (-not $wmiDrive) {

    return $false
  
  }

  # Avoid divide by zero

  if ($wmiDrive.Size) {

    return (100.0 - (($wmiDrive.FreeSpace) / ($wmiDrive.Size) * 100.0))
  
  }

}


# in bytes
Function myGetDriveFreeSpace($wmiDrive) {

  if (-not $wmiDrive) {

    return $false
  
  }

  return $wmiDrive.FreeSpace

}
