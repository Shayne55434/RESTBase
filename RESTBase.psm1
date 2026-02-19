# Import all public and private functions
$PublicFunctions = @(Get-ChildItem -Path "$PSScriptRoot/public/*.ps1" -ErrorAction SilentlyContinue)
$PrivateFunctions = @(Get-ChildItem -Path "$PSScriptRoot/private/*.ps1" -ErrorAction SilentlyContinue)

foreach ($Function in @($PublicFunctions + $PrivateFunctions)) {
   try {
      . $Function.FullName
   }
   catch {
      Write-Error "Failed to import function $($Function.Name): $_"
   }
}

# Cleanup
Remove-Variable -Name PublicFunctions, PrivateFunctions -Force -ErrorAction SilentlyContinue