
# just wraps Send-MailMessage
Function mySendMail($mailTo,$mailFrom,$mailSubject,$mailBody,$smtpServer,$smtpCredentialsFile)
{
  
  if ((Test-Path -Path "$myScriptRoot\$smtpCredentialsFile") -eq $false) {

    # if file not exists use current user credentials
    Send-MailMessage -To $mailTo -From $mailFrom -Subject $mailSubject -Body $mailBody `
                     -SmtpServer $smtpServer -UseSsl

  } else {

    $userName, $secureSecret = Get-Content "$myScriptRoot\$smtpCredentialsFile"
    $secureString = $secureSecret | ConvertTo-SecureString


    $credentials = New-Object System.Management.Automation.PSCredential `
                   -ArgumentList $userName, $secureString

    Send-MailMessage -Credential $credentials -To $mailTo -From $mailFrom -Subject $mailSubject -Body $mailBody `
                     -SmtpServer $smtpServer -UseSsl
   
   }

}

Function myCall($sipServer)
{
  $pjSuaPath = "$myScriptRoot\bin\pjsua"

  # make sure we don't have any running instances
  Stop-Process -Name "pjsua" -Force

  $dial =  $xmlConfig.Configuration.VoIP.Servers.Server.Dial

  $pjsuaPs = Start-Process -FilePath "$pjSuaPath\pjsua.exe" -PassThru `
       -ArgumentList "--config-file=$pjSuaPath\pjsua.cfg --log-file=$pjSuaPath\pjsua_log.txt $dial"
       
  
  # -RedirectStandardOutput "C:\pjsua_out.txt" -RedirectStandardError "C:\pjsua_err.txt"

  
  #Write-Host "Sleeping 120 sec"

  Start-Sleep -s 120
  Stop-Process -InputObject $pjsuaPs
        
}

Function mySms() {

  # not implemented yet

}