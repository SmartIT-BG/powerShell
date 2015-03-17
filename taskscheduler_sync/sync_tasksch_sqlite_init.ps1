# Create SQLite database

# Import PowerShell SQLite module
import-module "$PSScriptRoot\Modules\SQLite"

# db drive name
$dbDriveName = "tasksch_sync"

# Initialize database

# Mount SQLite drive

# Parvo proveri, dali veche ne e montiran drive

if(-not (Get-PSDrive $dbDriveName -ErrorAction Continue)) {

  # new-psdrive -psprovider SQLite -name mydb -root "DataSource=D:\sqlitedb.sqlite"
  mount-sqlite -name $dbDriveName -dataSource "$PSScriptRoot\db\sync_tasksch_folder.sqlite"

}

if(-not (Get-ChildItem "$($dbDriveName):\" -ErrorAction Continue)) {

  Write-Host "`nDatabase $dbDriverName is not created. Creating it...`n"


  # Create Tables
  #
  # Accounts Tables
  new-item -path "$($dbDriveName):/accounts" -value "id INTEGER PRIMARY KEY, accountName TEXT NOT NULL, 
                                                     securePassword TEXT NOT NULL, encryptedWithAccount TEXT NOT NULL"
  #
  # tasksSyncStatus
  new-item -path "$($dbDriveName):/tasksSyncStatus" -value "id INTEGER PRIMARY KEY, taskName TEXT NOT NULL,
                                                     syncStatus INTEGER, errCode INTEGER, lastCheck TEXT, 
                                                     emailed INTEGER"

}

Write-Host "`nDatabase $dbDriveName is ready`n"

if((Read-Host "Create accounts [y/n]?") -eq "y") {
  
  . "$PSScriptRoot\sync_tasksch_accounts.ps1"

}
