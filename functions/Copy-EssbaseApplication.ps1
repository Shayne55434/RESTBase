<#
   .SYNOPSIS
      Creates a copy of an existing application.
   .DESCRIPTION
      Creates a copy of an existing application. If the application already exists, 'DeleteExisting' must be used or the copy will fail.
   .PARAMETER RestURL <string>
      The base URL for the REST API interface. Example: 'https://your.domain.com/essbase/rest/v1'
   .PARAMETER Source <string>
      String value of the Application name to be copied.
   .PARAMETER Destination <string>
      Array String value of the Application name to be (re)created. Accepts value(s) from Pipeline.
   .PARAMETER DeleteExisting <switch>
      If used, the Destination Application will be forcefully deleted before being copied from the Source Application.
   .PARAMETER WebSession <WebRequestSession>
      A Web Request Session that contains authentication and header information for the connection.
   .PARAMETER Credential <pscredential>
      PowerShell credentials that contain authentication information for the connection.
   .PARAMETER Username <string>
      If used, you will be prompted to enter your password.
   .INPUTS
      System.String[]
   .OUTPUTS
      None
   .EXAMPLE
      Copy-EssbaseApplication -RestURL 'https://your.domain.com/essbase/rest/v1' -Source 'MyApplication' -Destination 'CopyOfMyApplication' -WebSession $MyWebSession [-DeleteExisting]
   .EXAMPLE
      'CopyOfMyApplication', 'AnotherCopyOfMyApplication' | Copy-EssbaseApplication -RestURL 'https://your.domain.com/essbase/rest/v1' -Source 'MyApplication' -Credential $MyCredentials [-DeleteExisting]
   .NOTES
      Created by : Shayne Scovill
   .LINK
      https://github.com/Shayne55434/RESTBase
#>
function Copy-EssbaseApplication {
   [CmdletBinding()]
   param(
      [Parameter(Mandatory, Position=0)]
      [ValidateNotNullOrEmpty()]
      [string]$RestURL,
      
      [Parameter(Mandatory)]
      [ValidateNotNullOrEmpty()]
      [string]$Source,
      
      [Parameter(Mandatory, ValueFromPipeline)]
      [ValidateNotNullOrEmpty()]
      [string[]]$Destination,
      
      [Parameter(HelpMessage='If used, the Destination Application will be forcefully deleted before being copied from the Source Application.')]
      [switch]$DeleteExisting,
      
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
      foreach ($strDestination in $Destination){
         if ($DeleteExisting.IsPresent) {
            try {
               Write-Verbose "Deleting application '$strDestination'."
               $null = Remove-EssbaseApplication -RestURL $RestURL @htbAuthentication -Name $strDestination -Force -Confirm
            }
            catch {
               Write-Error "Unable to delete $strDestination. $($_)"
            }
         }
         
         [hashtable]$htbInvokeParameters = @{
            Method = 'Post'
            Uri = "$RestURL/applications/actions/copy"
            Body = @{
               from = $Source
               to = $strDestination
            } | ConvertTo-Json
            Headers = @{
               accept = 'Application/JSON'
            }
            ContentType = 'Application/JSON'
         } + $htbAuthentication
         
         try {
            Write-Verbose "Copying '$Source' to '$strDestination'."
            $null = Invoke-RestMethod @htbInvokeParameters
         }
         catch {
            Write-Error $($_)
         }
      }
   }
}