$roots = @('C:\Users\phetrada\.gradle\caches\modules-2\files-2.1','C:\Users\phetrada\.gradle\caches\8.14\transforms')
$min = [datetime]'1980-01-01T00:00:00'
$max = [datetime]'2107-12-31T23:59:59'
$results = New-Object System.Collections.Generic.List[object]
foreach ($root in $roots) {
  if (-not (Test-Path $root)) { continue }
  Get-ChildItem -Path $root -Recurse -File | Where-Object { $_.Extension -in '.jar','.aar' } | ForEach-Object {
    $archivePath = $_.FullName
    try {
      $zip = [System.IO.Compression.ZipFile]::OpenRead($archivePath)
      try {
        foreach ($entry in $zip.Entries) {
          $ts = $entry.LastWriteTime.DateTime
          if ($ts -lt $min -or $ts -gt $max) {
            [void]$results.Add([pscustomobject]@{
              ArchivePath = $archivePath
              EntryPath   = $entry.FullName
              Timestamp   = $entry.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss zzz')
            })
          }
        }
      }
      finally { $zip.Dispose() }
    }
    catch {
      [void]$results.Add([pscustomobject]@{
        ArchivePath = $archivePath
        EntryPath   = '<<ERROR OPENING ARCHIVE>>'
        Timestamp   = $_.Exception.Message
      })
    }
  }
}
if ($results.Count -gt 0) { $results | Sort-Object ArchivePath, EntryPath | Format-Table -AutoSize | Out-String -Width 4096 | Write-Output } else { Write-Output 'NO_OFFENDERS_FOUND' }
