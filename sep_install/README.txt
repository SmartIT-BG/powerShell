USAGE:

Install:

  sep_install.ps1 [[-computerList] <string>] [[-symPkgUNC] <string>] [[-pkgDownloadType] <int>]

  EXAMPLE:
  
  sep_install.ps1 -symPkgUNC "\\server\share\Sep64.msi" -computerList "64bit-list.txt"
   
Uninstall:

  sep_uninstall.ps1 [[-computerList] <string>] [[-productName] <string>]

  EXAMPLE:
  
  sep_uninstall.ps1 -computerList "32bit-lit.txt" -productName "Symantec Endpoint Protection"