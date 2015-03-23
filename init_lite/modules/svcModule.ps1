
Function mySvcChkState($svcName) {

     $svcObj = Get-Service -Name $svcName
     
     if ($svcObj) {

       return $svcObj.Status

     }

     return $false

}

#mySvcChkState