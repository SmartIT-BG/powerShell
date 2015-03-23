# filesystemUtil
#
# admin@smartit.bg


if ($PSVersionTable.PSVersion.Major -le 3) {

  $myScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent

} else {

  $myScriptRoot = $PSScriptRoot

}

$todayDate = Get-Date -Format "yyyyMMdd"

$excelTemplateName = "filesystemUtil_template.xlsx"

$computerNamesFile = "$myScriptRoot\servers.txt"
$excelReportFile = "$myScriptRoot\$excelTemplateName"
$excelTodayFile = "$myScriptRoot\filesystemUtil_$($todayDate).xlsx"

. "$myScriptRoot\filesystem.ps1"
. "$myScriptRoot\contact.ps1"
. "$myScriptRoot\excel.ps1"


# remove previous files
$archFiles = Get-ChildItem -Path "$myScriptRoot\*" -Include *.xlsx -Exclude $excelTemplateName

if ($archFiles) {

  $archFiles | Remove-Item

}

# Wait random period for imitate humans.
# Seed is based on system time, so you should
# choose random task delay in task trigger,
# otherwise random number will be equal every time.

$randomNumber = Get-Random -Minimum 600 -Maximum 900

Start-Sleep -Seconds $randomNumber


# Read servers from file

$computerNames = Get-Content $computerNamesFile

$computerList = @{}

foreach ($computerName in $computerNames) {

  $computerVolumes = myGetDrives $computerName
  
  if(-not $computerVolumes) {
    
    if (-not $wmiErrorList) {
    
      $wmiErrorList = $computerName
    
    }
    else {

      $wmiErrorList = "$wmiErrorList, $computerName"

    }

    # don't include this server in the list
    Continue

  }

  $computerList.$($computerName) = $computerVolumes

}

if ($wmiErrorList) {

  # alert message

  [string[]]$smtpTo = "John Barleycorn <john@acme.intranet>", "Support ACME <support@acme.intranet>"
  $smtpFrom = "filesystemUtil Alert <filesystemUtil@acme.intranet>"
  $smtpSubject = "filesystemUtil Error"
  $smtpBody = "Can't get WMI info from machine(s) $wmiErrorList"
  $smtpServer = "smtp.acme.intranet"

  mySendMail $smtpTo $smtpFrom $smtpSubject $smtpBody $smtpServer

}

# Write to excel
#
# http://daniellange.wordpress.com/2009/12/03/working-with-excel-in-powershell/

$thisThread = [System.Threading.Thread]::CurrentThread
$originalCulture = $thisThread.CurrentCulture
$thisThread.CurrentCulture = New-Object System.Globalization.CultureInfo('en-US')

Copy-Item $excelReportFile $excelTodayFile

$workbook = openExcelWorkbook $excelTodayFile
$worksheet = openExcelWorksheet $workbook 1

$worksheetHeaders = Read-Headers $worksheet

# First computer
$currentRow = 3

foreach ($computer in $computerList.GetEnumerator()) {

  
  # Row, column
  $worksheet.cells.item($currentRow,$worksheetHeaders["Name"]) = $computer.Key
  $computer.Key
  foreach($vol in $computer.Value) {

    # Type 3 is Fixed drive
    if($vol.DriveType -eq 3) {

      $worksheet.cells.item($currentRow,$worksheetHeaders["Volume"]) = "$($vol.DeviceID) $($vol.VolumeName)"
      $worksheet.cells.item($currentRow,$worksheetHeaders["Free space"]) = "{0:N2}" -f ((myGetDriveFreeSpace $vol) / 1073741824)
      $worksheet.cells.item($currentRow,$worksheetHeaders["Util %"]) = "{0:N2}" -f (myGetDrivePercentFull $vol)

      $currentRow++


    }

  }

  $currentRow++


}

saveExcelWorkbook $workbook
closeExcelWorkbook $workbook

$thisThread.CurrentCulture = $originalCulture

# Mail message

$mailSubjectDate = Get-Date -Format "MM.dd.yyyy"

$smtpTo = "support@acme.intranet"
$smtpFrom = [Io.File]::ReadAllText("$myScriptRoot\sender.txt")
$smtpSubject = "FileSystem Utilization $mailSubjectDate"
$smtpBody = [Io.File]::ReadAllText("$myScriptRoot\signature.txt")
$smtpServer = "smpt.acme.intranet"
$smtpAttachments = $excelTodayFile

# Send mail, excel file as attachment

mySendMail $smtpTo $smtpFrom $smtpSubject $smtpBody $smtpServer $smtpAttachments