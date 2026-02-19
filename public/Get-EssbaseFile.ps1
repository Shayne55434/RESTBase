<#
   .SYNOPSIS
      List all files from a specified application and database.
   .DESCRIPTION
      List all files from a specified application and database.
   .PARAMETER RestURL <string>
      The base URL for the REST API interface. Example: 'https://your.domain.com/essbase/rest/v1'
   .PARAMETER Path <string[]>
      String value of the path for which to get a list of files/folders.
   .PARAMETER WebSession <WebRequestSession>
      A Web Request Session that contains authentication and header information for the connection.
   .PARAMETER Credentials <pscredential>
      PowerShell credentials that contain authentication information for the connection.
   .INPUTS
      None
   .OUTPUTS
      System.Object
   .EXAMPLE
      Get-EssbaseFile -RestURL 'https://your.domain.com/essbase/rest/v1' -Application 'Test1' -Database 'MyDB' -WebSession $MyWebsession
   .EXAMPLE
      Get-EssbaseFile -RestURL 'https://your.domain.com/essbase/rest/v1' -Application 'Test1' -Database 'MyDB'' -Credential $MyCredentials
   .NOTES
      Created by : Shayne Scovill
   .LINK
      https://github.com/Shayne55434/RESTBase
#>
function Get-EssbaseFile {
   [CmdletBinding()]
   param(
      [Parameter(Mandatory, Position=0)]
      [ValidateNotNullOrEmpty()]
      [string]$RestURL,
      
      [Parameter(Mandatory, ValueFromPipeline)]
      [ValidateNotNullOrEmpty()]
      [string[]]$Path,
      
      [Parameter()]
      [ValidateNotNullOrEmpty()]
      [string]$Filter,
      
      [Parameter()]
      [ValidateNotNullOrEmpty()]
      [string]$Type,
      
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
      $Files = @()
   }
   process {
      foreach ($strPath in $Path) {
         $URI = "$RestURL/files$($strPath)?"
            
         if ($Filter) {
            $URI += '&filter=' + $Filter
         }
         if ($Type) {
            $URI += '&type=' + $Type
         }
      
         [hashtable]$htbInvokeParameters = @{
            Method = 'Get'
            Uri = $URI
            Headers = @{
               accept = 'Application/JSON'
            }
         } + $htbAuthentication
         
         try{
            Write-Verbose "Getting a list of files from '$strPath'."
            $results = Invoke-RestMethod @htbInvokeParameters
            
            # To maintain consistancy, we'll only store the contents of the 'items' object.
            $Files += $results.items
         }
         catch {
            Write-Error "Failed to get a list of items. $($_)"
         }
      }
   }
   end {
      return $Files
   }
}