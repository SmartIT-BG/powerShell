# vSphere add port-groups to standard switch
# netadmin@smartit.bg

# In some cases, server certificate may be denied...
# Override with this cmdlet:
# Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false

 param(
  [string]$vServer ="vcsa.smartitbg.int", # Defaut: vcsa.smartitbg.int
  [string]$vCluster="BladesCluster", # Default: BladesCluster
  [string]$hostName="*", # Default: All hosts in the cluster
  [string]$vSwitch="vSwitch0", # Default: vSwitch0
  [Parameter(Mandatory = $true)][AllowEmptyString()][string]$portGroupsFile
)

function PrintLineError {
  Write-Host -ForegroundColor Red "Not valid port group entry at line $line"
  Write-Host "-------------------`n"
}

if($portGroupsFile) {
  if (-not (Test-Path $portGroupsFile)) {
    Write-Host "You must provide valid port groups file."
    Exit 1
   }
} else {
  Write-Host "portGroupsFile cannot be empty."
  Exit 1
}

Write-Host "`nUsing:`n--------------------------"

Write-Host "vSphere server: $vServer"
Write-Host "Cluster: $vCluster"
Write-Host "vSwitch: $vSwitch"
Write-Host "File port groups: $portGroupsFile"

Write-Host "--------------------------"

Write-Host


$proceed = Read-Host "Hit enter to continue"
Write-Host

$credentials = Get-Credential -Message "Credentials for $vServer"

if(-not $credentials) {
   Write-Host "No credentials provided"
   Exit 1
}

try {
  # Connect to vSphere.
  $vServerConnection = Connect-VIserver $vServer -Credential $credentials -ErrorAction Stop
  # All hosts in the cluster.
  $vmHosts = Get-Cluster $vCluster | Get-VMhost
} catch {
  Write-Host "Unable to connect to server: $vServer"
  Exit 1
}

$portGroups = Get-Content -Path $portGroupsFile

# Iterate through port groups.
$line = 1
foreach($pg in $portGroups) {
  $pgArray = $pg.Split(",")

  # Validate port group
  if($pgArray.Length -ne 2){
    PrintLineError
    $line++
    continue
  }

  # Valid name contains only alphanumeric chars and dashes.
  # Max 20 chars.
  if(-not ($pgArray[0] -match '^[a-z0-9-_ ]{1,25}$')) {
    PrintLineError
    $line++
    continue
  }

  # VLAN ID must be within interval 0-4095
  if(-not (([int]$pgArray[1] -ge 0) -and ([int]$pgArray[1] -le 4095))) {
    PrintLineError
    $line++
    continue
  }

  # Port group Name.
  $pgName = $pgArray[0]
  # Port group VLAN ID.
  $pgVlanID = [int]$pgArray[1]

  if($hostName -eq "*") {

    # Iterate through hosts and add port group.
    foreach ($vmHost in $vmHosts)
    {
      Write-Host "Adding VLAN $pgName ($pgVlanID) to Host $($vmHost.Name)"
      try {
          Get-VirtualSwitch -VMhost $vmHost -Name $vSwitch | New-VirtualPortGroup -Name $pgName -VlanId $pgVlanID -ErrorAction Stop | Out-Null
          Write-Host -ForegroundColor Green "OK"
      } catch {
          Write-Host -ForegroundColor Red "Unable to add VLAN. Host disconnected or VLAN already exists."
      }

      Write-Host

    }
  } else {
      Write-Host "Adding VLAN $pgName ($pgVlanID) to Host $hostName"
      try {
          Get-VirtualSwitch -VMhost $hostName -Name $vSwitch | New-VirtualPortGroup -Name $pgName -VlanId $pgVlanID -ErrorAction Stop | Out-Null
          Write-Host -ForegroundColor Green "OK"
      } catch {
          Write-Host -ForegroundColor Red "Unable to add VLAN. Host disconnected or VLAN already exists."
      }

      Write-Host
  }

  Write-Host "-------------------`n"

  $line++
}

# Disconnect from vServer
Disconnect-VIServer -Server $vServerConnection -Force -Confirm:$false
Write-Host "Finished"