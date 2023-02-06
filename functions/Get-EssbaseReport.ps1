<#
   .SYNOPSIS
      Gets the results from an Essbase report.
   .DESCRIPTION
      Executes an existing report on the Essbase server and returns the results.
   .PARAMETER RestURL <string>
      The base URL for the REST API interface. Example: 'https://your.domain.com/essbase/rest/v1'
   .PARAMETER Application <string>
      String value of the Application name that contains the report.
   .PARAMETER Database <string>
      String value of the Database name that contains the report.
   .PARAMETER ReportName <string>
      String value of the name of the report to be executed san the file extension.
   .PARAMETER WebSession <WebRequestSession>
      A Web Request Session that contains authentication and header information for the connection.
   .PARAMETER Credential <pscredential>
      PowerShell credential that contain authentication information for the connection.
   .INPUTS
      System.String[]
   .OUTPUTS
      None
   .EXAMPLE
      Copy-EssbaseApplication -RestURL 'https://your.domain.com/essbase/rest/v1' -SourceApplication 'MyApplication' -DestinationApplication 'CopyOfMyApplication' -WebSession $MyWebSession [-DeleteExisting]
   .EXAMPLE
      'CopyOfMyApplication', 'AnotherCopyOfMyApplication' | Copy-EssbaseApplication -RestURL 'https://your.domain.com/essbase/rest/v1' -SourceApplication 'MyApplication' -Credential $MyCredentials [-DeleteExisting]
   .NOTES
      Created by : Shayne Scovill
   .LINK
      https://github.com/Shayne55434/RESTBase
#>

function Get-EssbaseReport {
   [CmdletBinding()]
   param(
      [Parameter(Mandatory, Position=0)]
      [ValidateNotNullOrEmpty()]
      [string]$RestURL,
      
      [Parameter(Mandatory)]
      [ValidateNotNullOrEmpty()]
      [string]$Application,
      
      [Parameter(Mandatory)]
      [ValidateNotNullOrEmpty()]
      [string]$Database,
      
      [Parameter(Mandatory, ValueFromPipeline)]
      [ValidateNotNullOrEmpty()]
      [string[]]$ReportName,
      
      [Parameter()]
      [ValidateNotNullOrEmpty()]
      [switch]$LockForUpdate,
      
      [Parameter()]
      [ValidateNotNullOrEmpty()]
      [string]$OutFile,
      
      [Parameter()]
      [ValidateScript({$null -ne $OutFile -and $OutFile -ne ''})]
      [switch]$PassThru,
      
      [Parameter(Mandatory, ParameterSetName='WebSession')]
      [ValidateNotNullOrEmpty()]
      [Microsoft.PowerShell.Commands.WebRequestSession]$WebSession,
      
      [Parameter(Mandatory, ParameterSetName='Credential')]
      [ValidateNotNullOrEmpty()]
      [pscredential]$Credential,
      
      [Parameter(Mandatory, ParameterSetName='Username')]
      [ValidateNotNullOrEmpty()]
      [string]$Username
   )
   
   begin {
      # Decipher which authentication type is being used
      [hashtable]$htbAuthentication = @{}
      if ($Credential) {
         $htbAuthentication.Add('Credential', $Credential)
         Write-Verbose 'Using provided credentials.'
      }
      elseif ($WebSession) {
         $htbAuthentication.Add('WebSession', $WebSession)
         Write-Verbose 'Using provided Web Session variable.'
      }
      else {
         [pscredential]$Credential = Get-Credential -Message 'Please enter your Essbase password' -UserName $Username
         $htbAuthentication.Add('Credential', $Credential)
         Write-Verbose 'Using provided username and password.'
      }
   }
   process {
      foreach ($Report in $ReportName) {
         # Since the REST API cannot have any file extensions, let's make sure to remove any
         # While this is not 100% safe, it's simple and should be fine
         $Report = $Report.Replace('.rep', '')
         [hashtable]$htbInvokeParameters = @{
            Method = 'Get'
            Uri = "$RestURL/applications/$($Application)/databases/$($Database)/executeReport?filename=$($Report)&lockForUpdate=$($LockForUpdate.IsPresent)"
            Headers = @{
               accept = 'Application/Octet-Stream'
            }
         } + $htbAuthentication
         
         if ($null -ne $OutFile -and $OutFile -ne '') {
            Write-Verbose "Results will be saved to '$OutFile'."
            $htbInvokeParameters.Add('OutFile', $OutFile)
         }
         if ($PassThru.IsPresent) {
            Write-Verbose "PassThru is enabled."
            $htbInvokeParameters.Add('PassThru', $true)
         }
         
         try{
            Write-Verbose "Executing report '$ReportName'."
            [object]$Results = Invoke-RestMethod @htbInvokeParameters
         }
         catch {
            Write-Error "Failed to execute the report. $($_)"
         }
         
         return $Results
      }
   }
}