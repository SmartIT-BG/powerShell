# TightVNC Installer/Updater
#
# if 32-bit version exists on 64-bit system it will be removed
#
# admin@smartit.bg
#

# Get OS Architecture WMI
$OSArch = (Get-WmiObject -Class Win32_OperatingSystem).OSArchitecture

$tightVncPath = "C:\Program Files\TightVNC"
$tightVncPathx86 = "C:\Program Files (x86)\TightVNC"
$tightVncV1 = "WinVNC.exe"
$tightVncV2 = "tvnserver.exe"


# installation packages UNC paths
$installPath32 = "\\server\deploy\tightvnc-2.7.10-setup-32bit.msi"
$installPath64 = "\\server\deploy\tightvnc-2.7.10-setup-64bit.msi"

$serviceName = "tvnserver"
$serviceNameV1 = "VNC Server"

# important. this will be the final version
# make sure version match with installation package
#
$targetVersion = "2, 7, 10, 0"

# acceptable params:
#   $version = 1
#   $version = 2, "x86" ( check v2 32bit package on 64bit OS)
#   $version = 2
#
function tightVncVPresence($version, $x86dir) {

  if ($OSArch -eq "64-bit") {

    # version 1, 32bit build only
    if($version -eq 1) {

      if (Get-Item("$tightVncPathx86\$tightVncV1")) {

        return $true

      }

    # assuming version 2
    #
    } else {
      
      if ($x86dir -eq "x86") {

        if (Get-Item("$tightVncPathx86\$tightVncV2")) {

          return $true
      
        }
        
        return $false
      
      }

      if (Get-Item("$tightVncPath\$tightVncV2")) {

        return $true

      }

    }
   
  # assuming 32bit OSArch
  } else {

    if($version -eq 1) {

      if (Get-Item("$tightVncPath\$tightVncV1")) {

        return $true
      
      }
        
    # assuming version 2
    } else {

        if (Get-Item("$tightVncPath\$tightVncV2")) {

          return $true

        }

    }

  }

  # version does not exists
  return $false

}

function tightVncInstall() {

  if ($OSArch -eq "64-bit") {
    $pkg = $installPath64
  
  } else {

    $pkg = $installPath32

  }

  $rfbPort = "59326"
  
  if (getLaptop) { $rfbPort = "4898" }

  Start-Process -Wait -FilePath "msiexec" -ArgumentList "/i $pkg /quiet /norestart ADDLOCAL=Server SET_ALWAYSSHARED=1 VALUE_OF_ALWAYSSHARED=1 SET_ACCEPTHTTPCONNECTIONS=1 VALUE_OF_ACCEPTHTTPCONNECTIONS=0 SET_REMOVEWALLPAPER=1 VALUE_OF_REMOVEWALLPAPER=0  SET_RUNCONTROLINTERFACE=1 VALUE_OF_RUNCONTROLINTERFACE=0 SET_RFBPORT=1 VALUE_OF_RFBPORT=$rfbPort SET_USEVNCAUTHENTICATION=1 VALUE_OF_USEVNCAUTHENTICATION=1 SET_PASSWORD=1 VALUE_OF_PASSWORD=cOm&nO42 SET_VIEWONLYPASSWORD=1 VALUE_OF_VIEWONLYPASSWORD=cOm&nO42 SET_USECONTROLAUTHENTICATION=1 VALUE_OF_USECONTROLAUTHENTICATION=1 SET_CONTROLPASSWORD=1 VALUE_OF_CONTROLPASSWORD=cOm&nO42 SET_IPACCESSCONTROL=1 VALUE_OF_IPACCESSCONTROL=0.0.0.0-255.255.255.255:0"

}

function tightVncUninstall($version) {

  if ($OSArch -eq "64-bit") {
    
    $v1Path = $tightVncPathx86
  
  } else {

    $v1Path = $tightVncPath

  }

  if ($version -eq 1) {
    
    # version 1
    #
    # only if installed with official package
    #
    # Uninstall silently
    Start-Process -FilePath "$v1Path\unins000.exe" -ArgumentList "/silent"

  
  } else {

    # assuming version 2
    #
    # only if installed with official MSI package
    # Win32_Prduct WMI Class
    #
    $app = Get-WmiObject -Class Win32_Product `
                     -Filter "Name = 'TightVNC'"

    $uninstalled = $app.Uninstall()

  }


}

# experimental. not used
function tighVncFixReg() {
  
  $reg = "HKLM:\Software\TightVNC\Server"
  
  # example
  Set-ItemProperty -Path $reg -Name "RunControlInterface" -Value 1

}

# Check for laptop machine
Function getLaptop
{

 $isLaptop = $false

 if(Get-WmiObject -Class win32_systemenclosure | 
    Where-Object { $_.chassistypes -eq 9 -or $_.chassistypes -eq 10 `
    -or $_.chassistypes -eq 14})
   { $isLaptop = $true }
 if(Get-WmiObject -Class win32_battery) 
   { $isLaptop = $true }

 $isLaptop

} 


# main

if ($OSArch -eq "64-bit") {

  # uninstall version 1 if any
  if (tightVncVPresence 1) {

    Stop-Service $serviceNameV1

    tightVncUninstall 1

  }

  # uninstall 32bit verison 2 if any
  if (tightVncVPresence 2 "x86") {

    # Stop service and uninstall package
    Stop-Service $serviceName

    tightVncUninstall 2

  }

  if (tightVncVPresence 2) {
    
    # check product version
    if ((Get-Item "$tightVncPath\$tightVncV2").VersionInfo.ProductVersion -ne $targetVersion) {
      
      Stop-Service $serviceName

      # Uninstall first
      tightVncUninstall 2
      # Install
      tightVncInstall
    
    }

  } else {

    tightVncInstall

  }


}

if ($osArch -eq "32-bit") {

 
  # check for version 1
  if (tightVncVPresence 1) {

    # stop service first
    Stop-Service $serviceNameV1

    tightVncUninstall 1

  }

  if (tightVncVPresence 2) {
  
    # check for version 2
    if ((Get-Item "$tightVncPath\$tightVncV2").VersionInfo.ProductVersion -ne $targetVersion) {
      
      Stop-Service $serviceName

      # uninstall first
      tightVncUninstall 2
      # install
      tightVncInstall
    
    }

  } else {
    
    # finally
    tightVncInstall

  }
 
}

