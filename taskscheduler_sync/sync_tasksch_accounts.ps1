# inicializirane

#. "$PSScriptRoot\sync_tasksch_sqlite_init.ps1"

# Create  accounts

# take from user
# ...

# another way

$dbDriveName = "tasksch_sync"


Function myPrintHelp() {

# print menu
Write-Host `
"`n1. Show all accounts `
2: Create account `
3: Edit account `
4: Delete account
h or ?: Print this help
0 or q: Quit`n"

}

$currentAccount = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
$choice = 10

myPrintHelp

while($true)
{
  
  $choice = Read-Host "# "

  switch -Regex ($choice) {
    
    1 {
      
      ForEach($acc in (Get-ChildItem "$($dbDriveName):\accounts"))
      {
        Write-Host "$($acc.id), $($acc.accountName) encrypted with $($acc.encryptedWithAccount)"

      }

    }

    2 {

      $accountName = Read-Host "account (DOMAIN\name)"
      $secureString = Read-Host "password: " -AsSecureString

      $secureSecret = $secureString | ConvertFrom-SecureString

      new-item -path "$($dbDriveName):\accounts" -accountName $accountName ` -securePassword $secureSecret `
                                                 -encryptedWithAccount "($env:computername) $currentAccount"

    }

    3 {

      Write-Host "Not implemented yet"

    }

    4 {
      
      $accountId = Read-Host "id (get with show accounts, 0 to return)"

      if($accountId -ne 0) {

        remove-item "$($dbDriveName):\accounts\$accountId"

      }

    }

    "[0q]" {

      Write-Host "Bye"
      Return

    }

    "[hH?]" {

      myPrintHelp

    }

  }


}
