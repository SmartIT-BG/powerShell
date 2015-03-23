
# Import sqlps module first

Import-Module "$myScriptRoot\psmodules\SqlPs" –DisableNameChecking

# CONFIGURATION SECTION

$instanceName = $xmlConfig.Configuration.MSSQL.Instance.Name

$computerName = $env:COMPUTERNAME


# end CONFIGURATION SECTION

Function myGetInstContext() {

  return "SQLSERVER:\SQL\$computerName\$instanceName"

}

Function myGetDbContext($dbName) {

  return "SQLSERVER:\SQL\$computerName\$instanceName\Databases\$dbName"

}


Function myGetDb($dbName) {
  
  $dbResource = "SQLSERVER:\SQL\$computerName\$instanceName\Databases\$dbName"
   
  $dbReturn = Get-Item $dbResource

  return $dbReturn

}

Function myQuery($query) {

  cd $(myGetInstContext)

  $resultSet = Invoke-Sqlcmd -Query $query

  return $resultSet

}

Function myQueryDb($dbName, $query) {

  cd myGetDbContext

  $resultSet = Invoke-Sqlcmd -Query $query

  return $resultSet

}

Function myGetDbFileGroup($dbName) {

  

}

