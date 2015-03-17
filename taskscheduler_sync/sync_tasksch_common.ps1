# common help functions v0.1a

Function myRead-Credentials($accountName)
{
   
   $account = get-childitem tasksch_sync:/accounts -filter "accountName='$accountName'"

   $username = $account.accountName
   $secret = $account.securePassword | ConvertTo-SecureString

   return $credentials = New-Object System.Management.Automation.PSCredential `
                                    -ArgumentList $username, $secret

}

Function mySave-Credentials($path,$userName,$securePassword)
{
  # not implemented

}

Function mySet-Acl($folderPath)
{
  # not implemented

}