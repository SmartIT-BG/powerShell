# SQLite part

# Import PowerShell SQLite module
import-module "$PSScriptRoot\Modules\SQLite"

# proverka dali modulat e zaraden uspeshno!

# Initialize database

# Mount SQLite drive

# Parvo proveri, dali veche ne e montiran drive

if(-not (Get-PSDrive tasksch_sync -ErrorAction Continue)) {

  # new-psdrive -psprovider SQLite -name mydb -root "DataSource=D:\sqlitedb.sqlite"
  mount-sqlite -name tasksch_sync -dataSource "$PSScriptRoot\db\sync_tasksch_folder.sqlite"

}


try {

  Get-ChildItem tasksch_sync:/ -ErrorAction Stop | Out-Null

}
Catch
{
  
  Write-Host "`nDatabase is not created, please run init script first`n"
  Return

}