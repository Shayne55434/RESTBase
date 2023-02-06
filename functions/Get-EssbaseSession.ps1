<#
   .SYNOPSIS
      Get session information from Essbase.
   .DESCRIPTION
      Get session information from Essbase.
   .PARAMETER RestURL <string>
      The base URL for the REST API interface. Example: 'https://your.domain.com/essbase/rest/v1'
   .PARAMETER Application <string>
      String value of the Application name for which to get sessions.
   .PARAMETER Database <string>
      String value of the Database name for which to get sessions.
   .PARAMETER UserID <string>
      String value of the UserID name for which to get sessions.
   .PARAMETER WebSession <WebRequestSession>
      A Web Request Session that contains authentication and header information for the connection.
   .PARAMETER Credentials <pscredential>
      PowerShell credentials that contain authentication information for the connection.
   .INPUTS
      None
   .OUTPUTS
      None
   .EXAMPLE
      Get-EssbaseSession -RestURL 'https://your.domain.com/essbase/rest/v1' -WebSession $MyWebSession
   .EXAMPLE
      Get-EssbaseSession -RestURL 'https://your.domain.com/essbase/rest/v1' -Credential $MyCredentials
   .EXAMPLE
      Get-EssbaseSession -RestURL 'https://your.domain.com/essbase/rest/v1' -Username 'MyUsername' -Application 'TestCube'
   .NOTES
      Created by : Shayne Scovill
   .LINK
      https://github.com/Shayne55434/RESTBase
#>
function Get-EssbaseSession {
   [CmdletBinding()]
   Param(
      [Parameter(Mandatory, Position=0)]
      [ValidateNotNullOrEmpty()]
      [string]$RestURL,
      
      [Parameter()]
      [ValidateNotNullOrEmpty()]
      [string]$Application,
      
      [Parameter()]
      [ValidateNotNullOrEmpty()]
      [string]$Database,
      
      [Parameter()]
      [ValidateNotNullOrEmpty()]
      [string]$UserID,
      
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
   
   # Create the URI to be used
   $URI = "$RestURL/sessions?"
   
   if ($Application) {
      $URI += '&application=' + $Application
   }
   if ($Database) {
      $URI += '&database=' + $Database
   }
   if ($UserID) {
      $URI += '&userId=' + $UserID
   }
   
   [hashtable]$htbInvokeParameters = @{
      Method = 'Get'
      Uri = $URI
      Headers = @{
         accept = 'Application/JSON'
      }
   } + $htbAuthentication
   
   try{
      $Sessions = Invoke-RestMethod @htbInvokeParameters
      
      return $Sessions
   }
   catch {
      Write-Error "Failed to get Essbase sessions. $($_)"
   }
}