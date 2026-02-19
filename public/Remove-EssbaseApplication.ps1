<#
   .SYNOPSIS
      Delete an Application.
   .DESCRIPTION
      Delete an Application.
   .PARAMETER RestURL <string>
      The base URL for the REST API interface. Example: 'https://your.domain.com/essbase/rest/v1'
   .PARAMETER Name <string[]>
      The name of the Application to be deleted. Accepts value(s) from Pipeline.
   .PARAMETER WebSession <WebRequestSession>
      A Web Request Session that contains authentication and header information for the connection.
   .PARAMETER Credentials <pscredential>
      PowerShell credentials that contain authentication information for the connection.
   .PARAMETER Force <switch>
      If used, this will utilize a different API that forcefully deletes the application, without waiting for processes to finish.
   .INPUTS
      System.String[]
   .OUTPUTS
      None
   .EXAMPLE
      Remove-EssbaseApplication -RestURL 'https://your.domain.com/essbase/rest/v1' -Application 'MyApp' -WebSession $MyWebSession -Force -Confirm
   .EXAMPLE
      'MyApp', 'MyOtherApp' | Remove-EssbaseApplication -RestURL 'https://your.domain.com/essbase/rest/v1' -Credential $MyCredentials -WhatIf
   .NOTES
      Created by : Shayne Scovill
   .LINK
      https://github.com/Shayne55434/RESTBase
#>
function Remove-EssbaseApplication {
   [CmdletBinding(SupportsShouldProcess)]
   param(
      [Parameter(Mandatory, Position=0)]
      [ValidateNotNullOrEmpty()]
      [string]$RestURL,
      
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
      [string]$Username,
      
      [Parameter(HelpMessage='This will utilize a different API that forcefully deletes the application, without waiting for processes to finish.')]
      [switch]$Force
   )
   
   begin {
      # Decipher which authentication type is being used
      [hashtable]$htbAuthentication = @{}
      if ($Credential) {
         $htbAuthentication.Add('Credential', $Credential)
         Write-Verbose 'Using provided credentials.'
      }
      elseif ($WebSession)  {
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
      foreach ($Application in $Name) {
         [hashtable]$htbInvokeParameters = @{
            Method = 'Delete'
            Uri = "$RestURL/applications/$($Application)"
            Headers = @{
               accept = 'Application/JSON'
            }
         } + $htbAuthentication
         
         if ($Force.IsPresent) {
            Write-Verbose "The application will be forcefully deleted."
            $htbInvokeParameters.Uri = "$RestURL/applications/actions/shadowDelete/$($Application)"
         }
         
         try {
            if ($PSCmdlet.ShouldProcess("$Application" , "Remove Application - This is PERMANENT")) {
               Write-Verbose "Deleting application '$($Application)'."
               $null = Invoke-RestMethod @htbInvokeParameters
            }
         }
         catch {
            Write-Error "Failed to delete '$($Application)'. $($_)"
         }
      }
   }
}