<#
   .SYNOPSIS
      Upload file(s) to Essbase.
   .DESCRIPTION
      Upload file(s) to Essbase.
   .PARAMETER RestURL <string>
      The base URL for the REST API interface. Example: 'https://your.domain.com/essbase/rest/v1'
   .PARAMETER Path <string>
      Name of the Application to upload the file to.
   .PARAMETER WebSession <WebRequestSession>
      A Web Request Session that contains authentication and header information for the connection.
   .PARAMETER Credentials <pscredential>
      PowerShell credentials that contain authentication information for the connection.
   .PARAMETER Overwrite <switch>
      If used, it will overwrite any files with the same name.
   .INPUTS
      System.String[]
   .OUTPUTS
      None
   .EXAMPLE
      Out-EssbaseFile -RestURL 'https://your.domain.com/essbase/rest/v1' -Application 'MyApp' -Database 'MyDatabase' -FilePath 'C:\MyFile.txt' -WebSession $MyWebsession -Overwrite
   .EXAMPLE
      'C:\MyFile.txt', 'C:\MyOtherFile.txt' | Out-EssbaseFile -RestURL 'https://your.domain.com/essbase/rest/v1' -Application 'MyApp' -Database 'MyDatabase' -Credential $MyCredentials
   .NOTES
      Created by : Shayne Scovill
   .LINK
      https://github.com/Shayne55434/RESTBase
#>
function Out-EssbaseFile {
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
      [switch]$Overwrite,
      
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
      $UploadID = @()
   }
   process {
      foreach ($strPath in $Path) {
         [hashtable]$htbInvokeParameters = @{
            Method = 'Post'
            Uri = "$RestURL/files/upload-create$($Path)"
            ContentType = 'Application/JSON'
            Headers = @{
               accept = 'Application/JSON'
            }
         } + $htbAuthentication
         
         if ($Overwrite.IsPresent) {
            Write-Verbose "Overwriting '$strFileName', if it exists."
            $htbInvokeParameters.Uri = "$($htbInvokeParameters.Uri)?overwrite=true"
         }
         
         try {
            $results = Invoke-RestMethod @htbInvokeParameters
            $UploadID += $results
         }
         catch {
            Write-Error "Failed to create upload for '$strPath'. $($_)"
         }
      }
      
      return $UploadID
   }
}