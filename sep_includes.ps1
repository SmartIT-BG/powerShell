# sep_includes.ps1
# admin@smartit.bg

function Test-Port($hostname, $port)
{
   # This works no matter in which form we get $host - hostname or ip address
   try {
     $ip = [System.Net.Dns]::GetHostAddresses($hostname) | 
     select-object IPAddressToString -expandproperty  IPAddressToString
     
     if($ip.GetType().Name -eq "Object[]") {
        #If we have several ip's for that address, let's take first one
        $ip = $ip[0]

     }

   } catch {
     Write-Host "Possibly $hostname is wrong hostname or IP"
     Return

   }

   $t = New-Object Net.Sockets.TcpClient
   
   try {
     $t.Connect($ip,$port)
   
   } catch {}

   if($t.Connected) {
     $t.Close()
     $object = [pscustomobject] @{
                    Hostname = $hostname
                    IP = $IP
                    TCPPort = $port
                    GetResponse = $True }

     Write-Output $object

   } else {
     $object = [pscustomobject] @{
                    Computername = $IP
                    TCPPort = $port
                    GetResponce = $False }
    
    Write-Output $object

   }

}
