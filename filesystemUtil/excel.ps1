
# opens first wokrsheet
Function openExcelWorkbook($filePath) {

  $ci = new-object system.globalization.cultureinfo "en-US"

  $excelObj = New-Object -ComObject Excel.Application
  #$excelObj.visible = $true

  $excelWorkbook = $excelObj.workbooks.Open($filePath)

  return $excelWorkbook

}

Function saveExcelWorkbook($excelWorkbook) {

  $excelWorkbook.Save()

}

Function closeExcelWorkbook($excelWorkbook) {

  $excelWorkbook.Close()

}

Function openExcelWorksheet($excelWorkbook,$excelWorksheetNumber) {

  $excelWorksheets = $excelWorkbook.worksheets
  $excelWorksheet = $excelWorkbook.worksheets.Item($excelWorksheetNumber)

  return $excelWorksheet

}

Function Read-Headers ($excelWorksheet) {

  # Parameters: Excel worksheet
  # Returns: Hash table of the contents of each cell in the first row and the
  #    corresponding column number
  # Note: Processes until first blank cell

  $headers = @{}
  $column = 1
  
  do {

    $header = $excelWorksheet.cells.item(1,$column).text
    if ($header) {

      $headers.add($header, $column)
      $column++
    
    }

    } until (!$header)

    $headers

}
