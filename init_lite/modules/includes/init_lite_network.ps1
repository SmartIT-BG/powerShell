
Function myIcmpTest($host) {

  return Test-Connection -Quiet -ComputerName $host

}

