<#
   .SYNOPSIS
      Delete a Database.
   .DESCRIPTION
      Delete a Database from a specified Application.
   .PARAMETER RestURL <string>
      The base URL for the REST API interface. Example: 'https://your.domain.com/essbase/rest/v1'
   .PARAMETER Application <string>
      The name of the Application where the Database to be deleted exists.
   .PARAMETER Name <string[]>
      The name of the Database to be deleted. Accepts value(s) from Pipeline.
   .PARAMETER WebSession <WebRequestSession>
      A Web Request Session that contains authentication and header information for the connection.
   .PARAMETER Credentials <pscredential>
      PowerShell credentials that contain authentication information for the connection.
   .INPUTS
      None
   .OUTPUTS
      None
   .EXAMPLE
      Remove-EssbaseDatabase -RestURL 'https://your.domain.com/essbase/rest/v1' -Application 'MyApp' -Database 'MyDatabase' -WebSession $MyWebSession -WhatIf
   .EXAMPLE
      Remove-EssbaseDatabase -RestURL 'https://your.domain.com/essbase/rest/v1' -Application 'MyApp' -Database 'MyDatabase' -Credential $MyCredentials -Confirm
   .NOTES
      Created by : Shayne Scovill
   .LINK
      https://github.com/Shayne55434/RESTBase
#>
function Remove-EssbaseDatabase {
   [CmdletBinding(SupportsShouldProcess)]
   param(
      [Parameter(Mandatory, Position=0)]
      [ValidateNotNullOrEmpty()]
      [string]$RestURL,
      
      [Parameter(Mandatory)]
      [ValidateNotNullOrEmpty()]
      [string]$Application,
      
      [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
      [ValidateNotNullOrEmpty()]
      [string[]]$Name,
      
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
      foreach ($Database in $Name) {
         [hashtable]$htbInvokeParameters = @{
            Method = 'Delete'
            Uri = "$RestURL/applications/$($Application)/databases/$($Database)"
            ContentType = 'Application/JSON'
            Headers = @{
               accept = 'Application/JSON'
            }
         } + $htbAuthentication
         
         try {
            if ($PSCmdlet.ShouldProcess("$Application.$Database" , "Remove Database")) {
               Write-Verbose "Removing '$Application.$Database'."
               $null = Invoke-RestMethod @htbInvokeParameters
            }
         }
         catch {
            Write-Error "Failed to delete '$($Application).$($Database)'. $($_)"
         }
      }
   }
}