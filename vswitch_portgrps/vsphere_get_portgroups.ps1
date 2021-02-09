# vSphere get port-groups from standard switch
# netadmin@smartit.bg

# In some cases, server certificate may be denied...
# Override with this cmdlet:
# Set-PowerCLIConfiguration -InvalidCertificateAction Ignore

 param(
  [string]$vServer ="vcsa.smartitbg.int", # Defaut: vcsa.smartitbg.int
  [string]$vCluster="BladesCluster", # Default: BladesCluster
  [Parameter(Mandatory = $true)][string]$hostName,
  [string]$vSwitch="vSwitch0", # Default: vSwitch0
  [Parameter(Mandatory = $true)][string]$portGroupsFile
)

Write-Host "`nUsing:`n--------------------------"

Write-Host "vSphere server: $vServer"
Write-Host "Cluster: $vCluster"
Write-Host "vSwitch: $vSwitch"
Write-Host "File port groups: $portGroupsFile"

Write-Host "--------------------------"

Write-Host


$proceed = Read-Host "Hit enter to continue"

$credentials = Get-Credential -Message "Credentials for $vServer"

if(-not $credentials) {
   Write-Host "No credentials provided"
   Exit 1
}

try {
  # Connect to vSphere.
  $vServerConnection = Connect-VIserver $vServer -Credential $credentials -ErrorAction Stop
  # All hosts in the cluster.
  $vmHost = Get-Cluster $vCluster | Get-VMhost -Name $hostName
} catch {
  Write-Host "Unable to connect to server: $vServer"
  Exit 1
}

try {
  $portGroups = Get-VirtualPortGroup -VMHost $vmHost -VirtualSwitch $vSwitch -ErrorAction Stop 
} catch {
  Write-Host "Unable to get virtua port groups from $vmHost,$vSwitch"
  Exit 1
}

# Create file.
try {
  Out-File -FilePath $portGroupsFile
} catch {
  Write-Host "Unalbe to create a file $portGroupsFile"
  Exit 1
}

# Iterate through port groups.
foreach($pg in $portGroups) {
  $pg.Name + "," + $pg.VLanId | Add-Content -Path $portGroupsFile
}

# Disconnect from vServer
Disconnect-VIServer -Server $vServerConnection -Force -Confirm:$false
Write-Host "Finished"