Requirements:

- VMware-PowerCLI

  \\cow.easycredit.bg\FileServer\it\Admin\(3) Operations\VMWare\VMware-PowerCLI-6.5.0-4624819.exe

- Invalid SSL certificate exception 

  ��� ��� ������� ��� SSL ������������ �� �������, ��� ����� �� ��������� ������� �� ������ ������� cmdlet:

  Set-PowerCLIConfiguration -InvalidCertificateAction Ignore


[vsphere_add_portgroups.ps1]

Usage:

-vServer

  vSphere / ESXi ������, ��� ����� �� �� ������� �������.

-vCluster

  ��� �� �������, �������� "Hx5 Cluster"

-hostName

  ��� �� ����, ��� ����� �� �� ������� ���� �������. ��� �� �� ������, ���� ������� �� ������� �� ������ �������!

-vSwitch

  ��� �� vSwtich, �������� "vSwitch0". ���� VMWare standard switch!

-portGroupsFile

  ��� �� �����, � ����� �� ���������� ����� � ID �� ���� �������.
  ����� ��� ��� ����� ������ ����� � VLAN ID, ��������� ��� �������.

  ��������: MyVLAN,100

  ������� �� ���������� �� �������� � ��� ������� � �� ����� �� �������� ��������� �������. 
  VLAN ID ������ �� � � ��������: 0-4095


Examples:

.\vsphere_add_portgroups.ps1 -vServer "vcsa.smartitbg.int" -vCluster "Hx5 Cluster" -hostName "phoenix.easycredit.bg" -vSwitc
h "vSwitch0" -portGroupsFile "pg.txt"


[vsphere_get_portgroups.ps1]

-vServer

  vSphere / ESXi ������, ��� ����� �� �� ������� �������.

-vCluster

  ��� �� �������, �������� "Hx5 Cluster"

-hostName

  ��� �� ����, �� ����� �� �� �������� VLAN.

-vSwitch

  ��� �� vSwtich, �������� "vSwitch0". ���� VMWare standard switch!

-portGroupsFile

  ����, � ����� �� �� �������� ���� �������.
  ���� ������� �� ���������� ��� ������: ���,VLanId (�� ����� ���).


Examples:

.\vsphere_get_portgroups.ps1 -vServer "vcsa.smartitbg.int" -vCluster "Hx5 Cluster" -hostName "hydra.easycredit.bg" -vSwitc
h "vSwitch0" -portGroupsFile "pg.txt"