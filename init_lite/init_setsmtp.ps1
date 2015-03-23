# create user credentials

if ($PSVersionTable.PSVersion.Major -le 3) {

  $myScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent

} else {

  $myScriptRoot = $PSScriptRoot

}

$xmlConfig = [xml](Get-Content "$myScriptRoot\configuration.xml")
$smtpCredentialsFile = $xmlConfig.Configuration.Contact.Smtp.CredentialsFile

$userName = Read-Host "username: "

$secureString= Read-Host "secret: " -AsSecureString
$secureSecret = $secureString | ConvertFrom-SecureString


$userName, $secureSecret | Out-File -FilePath "$myScriptRoot\$smtpCredentialsFile"
