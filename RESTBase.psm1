foreach ($directory in @('functions')) {
   Get-ChildItem -Path "$PSScriptRoot\$directory\*.ps1" | ForEach-Object { . $_.FullName }
}