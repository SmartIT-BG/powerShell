CONTACT:

<pavel.zhelyazkov@smartit.bg>

filesystemUtil takes utilization of computer volumes via WMI from list of Windows machines and cooks nice excel report. Then it sends this report to email(s) of your choice. It waits random period of time before starting.

REQUIREMENTS:

  1. WMI access to probed machines
  2. Microsoft Excel installed
  
INSTALL:

  1. Populate 'servers.txt' with computer names. One computer name at line.
  2. Edit 'sender.txt' for email sender
  3. Edit 'signature.txt' for email sender signature