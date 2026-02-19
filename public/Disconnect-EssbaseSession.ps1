<#
   .SYNOPSIS
      Disconnect a session from Essbase.
   .DESCRIPTION
      Disconnect a session from Essbase.
   .PARAMETER RestURL <string>
      The base URL for the REST API interface. Example: 'https://your.domain.com/essbase/rest/v1'
   .PARAMETER WebSession <WebRequestSession>
      A Web Request Session that contains authentication and header information for the connection.
   .PARAMETER Credentials <pscredential>
      PowerShell credentials that contain authentication information for the connection.
   .INPUTS
      None
   .OUTPUTS
      None
   .EXAMPLE
      Disconnect-EssbaseSession -RestURL 'https://your.domain.com/essbase/rest/v1' -WebSession $MyWebSession
   .EXAMPLE
      Disconnect-EssbaseSession -RestURL 'https://your.domain.com/essbase/rest/v1' -Credential $MyCredentials
   .NOTES
      Created by : Shayne Scovill
   .LINK
      https://github.com/Shayne55434/RESTBase
#>
function Disconnect-EssbaseSession {
   [CmdletBinding(SupportsShouldProcess)]
   Param(
      [Parameter(Mandatory, Position=0)]
      [ValidateNotNullOrEmpty()]
      [string]$RestURL,
      
      [Parameter(Mandatory, ValueFromPipeline)]
      [ValidateNotNullOrEmpty()]
      [string[]]$SessionID,
      
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
      foreach ($ID in $SessionID) {
         [hashtable]$htbInvokeParameters = @{
            Method = 'Delete'
            Uri = "$RestURL/sessions/$($ID)?disconnect=true"
            Headers = @{
               accept = 'Application/JSON'
            }
         } + $htbAuthentication
         
         if ($PSCmdlet.ShouldProcess("$ID" , "Disconnect session")) {
            try {
               Write-Verbose "Disconnecting from Essbase."
               $null = Invoke-RestMethod @htbInvokeParameters -DisableKeepAlive
            }
            catch {
               Write-Error "Failed to disconnect from Essbase. $($_)"
            }
         }
      }
   }
}