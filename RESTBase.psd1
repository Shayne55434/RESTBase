@{
   # Assemblies that must be loaded prior to importing this module
   RequiredAssemblies = @()
   
   # Script module or binary module file associated with this manifest.
   RootModule         = 'RESTBase.psm1'
   
   # Version number of this module.
   ModuleVersion      = '1.1.0'
   
   # ID used to uniquely identify this module
   GUID               = '9d78f6f8-20d3-4ce2-824b-cb52b9fa8da8'
   
   # Author of this module
   Author             = 'Shayne Scovill'
   
   # Company or vendor of this module
   CompanyName        = 'Shayne'
   
   # Copyright statement for this module
   Copyright          = @'
Copyright (c) 2022 Shayne Scovill

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the 'Software'), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
'@

   # Description of the functionality provided by this module
   Description        = 'PowerShell module for Oracle Essbase REST API administration.'
   
   # Minimum PowerShell version required to run this module.
   PowerShellVersion  = '5.1'
   
   # Functions to export from this module
   FunctionsToExport  = @(
      'Copy-EssbaseApplication',
      'Copy-EssbaseDatabase',
      'Disconnect-EssbaseSession',
      'Get-EssbaseApplication',
      'Get-EssbaseAuthenticationToken',
      'Get-EssbaseDatabase',
      'Get-EssbaseFile',
      'Get-EssbaseJob',
      'Get-EssbaseReport',
      'Get-EssbaseSession',
      'Get-EssbaseWebSession',
      'Invoke-EssbaseJob',
      'Invoke-ShadowPromote',
      'New-MultiFileUpload',
      'New-ShadowCopy',
      'Out-EssbaseFile',
      'Remove-EssbaseApplication',
      'Remove-EssbaseDatabase',
      'Remove-EssbaseFile',
      'Start-EssbaseApplication',
      'Stop-EssbaseApplication'
   )
   
   # Aliases to export from this module
   AliasesToExport    = @()
   
   # Cmdlets to export from this module
   CmdletsToExport    = @()
   
   # Private data to pass to the module specified in RootModule/ModuleToProcess
   PrivateData        = @{
      PSData = @{
         Category     = 'Essbase'
         Tags         = @('Essbase', 'Oracle', 'REST', 'Administration')
         ProjectUri   = 'https://github.com/Shayne55434/RESTBase'
         LicenseUri   = 'https://github.com/Shayne55434/RESTBase/blob/master/LICENSE'
         IsPrerelease = 'False'
      }
   }
}