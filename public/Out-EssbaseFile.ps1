<#
   .SYNOPSIS
      Upload file(s) to Essbase.
   .DESCRIPTION
      Upload file(s) to Essbase.
   .PARAMETER RestURL <string>
      The base URL for the REST API interface. Example: 'https://your.domain.com/essbase/rest/v1'
   .PARAMETER Application <string>
      Name of the Application to upload the file to.
   .PARAMETER Database <string>
      Name of the Database to upload the file to.
   .PARAMETER FilePath <string>
      Full path to the local file to be uploaded to Essbase. Accepts value(s) from Pipeline.
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
      
      [Parameter(Mandatory)]
      [ValidateNotNullOrEmpty()]
      [string]$Application,
      
      [Parameter(Mandatory)]
      [ValidateNotNullOrEmpty()]
      [string]$Database,
      
      [Parameter(Mandatory, ValueFromPipeline)]
      [ValidateNotNullOrEmpty()]
      [ValidateScript({Test-Path -Path $_})]
      [string[]]$FilePath,
      
      [Parameter(Mandatory, ParameterSetName='WebSession')]
      [ValidateNotNullOrEmpty()]
      [Microsoft.PowerShell.Commands.WebRequestSession]$WebSession,
      
      [Parameter(Mandatory, ParameterSetName='Credential')]
      [ValidateNotNullOrEmpty()]
      [pscredential]$Credential,
      
      [Parameter(Mandatory, ParameterSetName='Username')]
      [ValidateNotNullOrEmpty()]
      [string]$Username,
      
      [Parameter()]
      [ValidateNotNullOrEmpty()]
      [switch]$Overwrite
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
      foreach ($strFilePath in $FilePath) {
         [string]$strTempProgressPreference = $ProgressPreference
         [boolean]$blnFileIsReadOnly = $false
         [string]$strFileName = (Get-Item -Path $strFilePath).Name
         [hashtable]$htbInvokeParameters = @{
            Method = 'Put'
            Uri = "$RestURL/files/applications/$($Application)/$($Database)/$($strFileName)"
            ContentType = 'Application/Octet-Stream'
            InFile = $strFilePath
            Headers = @{
               accept = 'Application/JSON'
            }
         } + $htbAuthentication
         
         if ($Overwrite.IsPresent) {
            Write-Verbose "Overwriting '$strFileName', if it exists."
            $htbInvokeParameters.Uri = "$($htbInvokeParameters.Uri)?overwrite=true"
         }
         
         # Remove the ReadOnly property from the file, as Invoke-RestMethod will not upload it otherwise. Apparently, this bug is corrected in PS v7.
         if ((Get-ItemProperty -Path $strFilePath).IsReadOnly) {
            $blnFileIsReadOnly = $true
            Set-ItemProperty -Path $strFilePath -Name IsReadOnly -Value $false
            Write-Debug "Removed Read-Only attribute from $strFilePath."
         }
         
         try {
            # To increase performance, remove the progress bar from being displayed
            $ProgressPreference = 'SilentlyContinue'
            $null = Invoke-RestMethod @htbInvokeParameters
         }
         catch {
            Write-Error "Failed to upload '$strFilePath' to Essbase. $($_)"
         }
         finally{
            # Restore ProgressPreference and ReadOnly property on the file
            $ProgressPreference = $strTempProgressPreference
            if ($blnFileIsReadOnly) {
               Set-ItemProperty -Path $strFilePath -Name IsReadOnly -Value $true
               Write-Debug "Restored Read-Only attribute to $strFilePath."
            }
         }
      }
   }
}