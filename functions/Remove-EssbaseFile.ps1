<#
   .SYNOPSIS
      Delete file from Essbase.
   .DESCRIPTION
      Delete file from Essbase.
   .PARAMETER RestURL <string>
      The base URL for the REST API interface. Example: 'https://your.domain.com/essbase/rest/v1'
   .PARAMETER Application <string>
      The name of the Application where the File to be deleted exists.
   .PARAMETER Database <string>
      The name of the Database where the File to be deleted exists.
   .PARAMETER FullPath <string>
      The name of the File to be deleted.
   .PARAMETER WebSession <WebRequestSession>
      A Web Request Session that contains authentication and header information for the connection.
   .PARAMETER Credentials <pscredential>
      PowerShell credentials that contain authentication information for the connection.
   .INPUTS
      System.String[]
   .OUTPUTS
      None
   .EXAMPLE
      Remove-EssbaseDatabase -RestURL 'https://your.domain.com/essbase/rest/v1' -FullPath '/applications/MyCube/MyDB/MyFile.txt' -WebSession $MyWebSession
   .EXAMPLE
      '/applications/MyCube/MyDB/MyFile.txt', '/applications/MyCube/MyDB/MyOtherFile.txt' | Remove-EssbaseDatabase -RestURL 'https://your.domain.com/essbase/rest/v1'-Credential $MyCredentials -Confirm
   .EXAMPLE
      Get-EssbaseFile -RestURL 'https://your.domain.com/essbase/rest/v1' -Username 'shayne.scovill@olddutchfoods.com' -Path '/applications/MyCube/MyDB' -Filter 'err_'  | Remove-EssbaseDatabase -RestURL 'https://your.domain.com/essbase/rest/v1'-Credential $MyCredentials -Confirm
   .NOTES
      Created by : Shayne Scovill
   .LINK
      https://github.com/Shayne55434/RESTBase
#>
function Remove-EssbaseFile {
   [CmdletBinding(SupportsShouldProcess)]
   param(
      [Parameter(Mandatory, Position=0)]
      [ValidateNotNullOrEmpty()]
      [string]$RestURL,
      
      [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
      [ValidateNotNullOrEmpty()]
      [string[]]$FullPath,
      
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
      foreach ($path in $FullPath) {
         [hashtable]$htbInvokeParameters = @{
            Method = 'Delete'
            Uri = "$RestURL/files$($path)"
            Headers = @{
               accept = 'Application/JSON'
            }
         } + $htbAuthentication
         
         try {
            if ($PSCmdlet.ShouldProcess("$path" , "Remove")) {
               Write-Verbose "Deleting '$path'."
               $null = Invoke-RestMethod @htbInvokeParameters
            }
         }
         catch {
            Write-Error "Failed to delete '$path'. $($_)"
         }
      }
   }
}