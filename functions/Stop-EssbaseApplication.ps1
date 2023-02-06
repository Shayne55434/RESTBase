<#
   .SYNOPSIS
      Stop Essbase Application.
   .DESCRIPTION
      Stop Essbase Application.
   .PARAMETER RestURL <string>
      The base URL for the REST API interface. Example: 'https://your.domain.com/essbase/rest/v1'
   .PARAMETER Application <string>
      The name of the Application to be stopped.
   .PARAMETER WebSession <WebRequestSession>
      A Web Request Session that contains authentication and header information for the connection.
   .PARAMETER Credentials <pscredential>
      PowerShell credentials that contain authentication information for the connection.
   .INPUTS
      System.String[]
   .OUTPUTS
      None
   .EXAMPLE
      Stop-EssbaseApplication -RestURL 'https://your.domain.com/essbase/rest/v1' -Application 'MyApp' -WebSession $MyWebSession
   .EXAMPLE
      'MyApp', 'MyOtherApp' | Stop-EssbaseApplication -RestURL 'https://your.domain.com/essbase/rest/v1' -Credential $MyCredentials
   .NOTES
      Created by : Shayne Scovill
   .LINK
      https://github.com/Shayne55434/RESTBase
#>
function Stop-EssbaseApplication {
   [CmdletBinding()]
   Param(
      [Parameter(Mandatory, Position=0)]
      [ValidateNotNullOrEmpty()]
      [string]$RestURL,
      
      [Parameter(Mandatory, ValueFromPipeline)]
      [ValidateNotNullOrEmpty()]
      [string[]]$Application,
      
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
      foreach ($application in $Application) {
         [hashtable]$htbInvokeParameters = @{
            Method = 'Put'
            Uri = "$RestURL/applications/$($Application)?action=stop"
            Headers = @{
               accept = 'Application/JSON'
            }
         } + $htbAuthentication
         
         try {
            Write-Verbose "Stopping application $Application."
            $null = Invoke-RestMethod @htbInvokeParameters
         }
         catch {
            Write-Error "Unable to stop '$Application'. $($_)"
         }
      }
   }
}