function Remove-EssbaseApplication {
   <#
      .SYNOPSIS
         Delete an Essbase application.
      .DESCRIPTION
         Deletes one or more Essbase applications. Optionally uses forced deletion without waiting for processes to finish.
      .PARAMETER RestUrl
         The base URL for the REST API (e.g., 'https://your.domain.com/essbase/rest/v1').
      .PARAMETER Name
         Application name(s) to delete. Supports pipeline input.
      .PARAMETER Force
         Use forced deletion API that doesn't wait for processes to finish.
      .PARAMETER Credential
         PowerShell credential object for authentication.
      .PARAMETER AuthToken
         Bearer token for authentication.
      .PARAMETER WebSession
         Existing web session for authentication.
      .PARAMETER Username
         Username for interactive credential prompt.
      .INPUTS
         System.String
      .OUTPUTS
         None
      .EXAMPLE
         Remove-EssbaseApplication -RestUrl 'https://your.domain.com/essbase/rest/v1' -Name 'MyApp' -WebSession $Session -Confirm
      .EXAMPLE
         'App1', 'App2' | Remove-EssbaseApplication -RestUrl 'https://your.domain.com/essbase/rest/v1' -Credential $Cred -Force -WhatIf
      .NOTES
         Created by: Shayne Scovill
      .LINK
         https://docs.oracle.com/en/database/other-databases/essbase/21/essrt/op-applications-application-delete.html
   #>
   [CmdletBinding(SupportsShouldProcess)]
   param(
      [Parameter(Mandatory, Position = 0)]
      [ValidateNotNullOrEmpty()]
      [string]$RestUrl,
      
      [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
      [ValidateNotNullOrEmpty()]
      [string[]]$Name,
      
      [Parameter()]
      [switch]$Force,
      
      [Parameter(Mandatory, ParameterSetName = 'Credential')]
      [ValidateNotNullOrEmpty()]
      [pscredential]$Credential,
      
      [Parameter(Mandatory, ParameterSetName = 'AuthToken')]
      [ValidateNotNullOrEmpty()]
      [string]$AuthToken,
      
      [Parameter(Mandatory, ParameterSetName = 'WebSession')]
      [ValidateNotNullOrEmpty()]
      [Microsoft.PowerShell.Commands.WebRequestSession]$WebSession,
      
      [Parameter(Mandatory, ParameterSetName = 'Username')]
      [ValidateNotNullOrEmpty()]
      [string]$Username
   )
   
   begin {
      $AuthParams = Resolve-AuthenticationParameter -Credential $Credential -WebSession $WebSession -Username $Username -AuthToken $AuthToken
   }
   
   process {
      foreach ($ApplicationName in $Name) {
         if ($Force.IsPresent) {
            $Uri = "$RestUrl/applications/actions/shadowDelete/$ApplicationName"
            Write-Verbose "Using forced deletion for: $ApplicationName"
         }
         else {
            $Uri = "$RestUrl/applications/$ApplicationName"
         }
         
         if ($PSCmdlet.ShouldProcess("Application: $ApplicationName", "Permanently delete application")) {
            try {
               Write-Verbose "Deleting application: $ApplicationName"
               $null = Invoke-EssbaseRequest -Method Delete -Uri $Uri @AuthParams
               Write-Information "Application '$ApplicationName' deleted successfully."
            }
            catch {
               Write-Error "Failed to delete application '$ApplicationName': $_"
            }
         }
      }
   }
}