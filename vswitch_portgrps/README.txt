Requirements:

- VMware-PowerCLI

  \\cow.easycredit.bg\FileServer\it\Admin\(3) Operations\VMWare\VMware-PowerCLI-6.5.0-4624819.exe

- Invalid SSL certificate exception 

  Ако има проблем със SSL сертификатът на сървъра, към който се изпълнява скрипта се ползва следния cmdlet:

  Set-PowerCLIConfiguration -InvalidCertificateAction Ignore


[vsphere_add_portgroups.ps1]

Usage:

-vServer

  vSphere / ESXi сървър, към който да се изпълни скрипта.

-vCluster

  Име на клъстер, например "Hx5 Cluster"

-hostName

  Име на хост, към който да се добавят порт групите. Ако не се посочи, порт групите се добавят на всички хостове!

-vSwitch

  Име на vSwtich, например "vSwitch0". Само VMWare standard switch!

-portGroupsFile

  Път до файла, в който се съхраняват имена и ID на порт групите.
  Всеки ред във файла описва името и VLAN ID, разделени със запетая.

  Например: MyVLAN,100

  Имената са ограничени до двадесет и пет символа и не могат да съдържат специални символи. 
  VLAN ID трябва да е в диапазон: 0-4095


Examples:

.\vsphere_add_portgroups.ps1 -vServer "vcsa.smartitbg.int" -vCluster "Hx5 Cluster" -hostName "phoenix.easycredit.bg" -vSwitc
h "vSwitch0" -portGroupsFile "pg.txt"


[vsphere_get_portgroups.ps1]

-vServer

  vSphere / ESXi сървър, към който да се изпълни скрипта.

-vCluster

  Име на клъстер, например "Hx5 Cluster"

-hostName

  Име на хост, от който да се извлекат VLAN.

-vSwitch

  Име на vSwtich, например "vSwitch0". Само VMWare standard switch!

-portGroupsFile

  Файл, в който да се съхранят порт групите.
  Порт групите се съхраняват във формат: ИМЕ,VLanId (на всеки ред).


Examples:

.\vsphere_get_portgroups.ps1 -vServer "vcsa.smartitbg.int" -vCluster "Hx5 Cluster" -hostName "hydra.easycredit.bg" -vSwitc
h "vSwitch0" -portGroupsFile "pg.txt"