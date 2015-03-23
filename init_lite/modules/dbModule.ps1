# module db

. "$myScriptRoot\modules\includes\init_lite_sqlserver.ps1"

Function myDbChkLinkedServer($lnkdServerName) {

  cd $(myGetInstContext)

  $lnkdServerObj = Get-ChildItem "LinkedServers" | Where-Object { $_.Name -eq $lnkdServerName }

  if ($lnkdServerObj) {

    try {
      
      $lnkdServerObj.Refresh()
      $lnkdServerObj.TestConnection()

    }
    catch {

      return $false

    }

    return $true

  }

  return $false

}


# check if job exists and executing
Function myDbChkAgentJobStatus($jobName) {

  cd $(myGetInstContext)

  $jobObj = Get-ChildItem "JobServer\Jobs" | Where-Object { $_.Name -eq $jobName }

  if ($jobObj) {
    
    $jobObj.Refresh()
    if ($jobObj.CurrentRunStatus.ToString() -eq "Executing") {

      return $true

    }

  }

  $false

}

Function myDbBackupInProgress() {

  $query = "SELECT session_id as SPID, command, a.text AS Query, start_time, percent_complete, dateadd(second,estimated_completion_time/1000, getdate()) as estimated_completion_time 
FROM sys.dm_exec_requests r CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) a 
WHERE r.command in ('BACKUP DATABASE')"

  $resultSet = myQuery $query

  if ($resultSet) {

     return $resultSet.percent_complete

   }

   return $false

}
