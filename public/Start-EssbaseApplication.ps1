function Start-EssbaseApplication {
   <#
      .SYNOPSIS
         Start an Essbase application.
      .DESCRIPTION
         Starts one or more Essbase applications on the server.
      .PARAMETER RestUrl
         The base URL for the REST API (e.g., 'https://your.domain.com/essbase/rest/v1').
      .PARAMETER Name
         Application name(s) to start. Supports pipeline input.
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
         Start-EssbaseApplication -RestUrl 'https://your.domain.com/essbase/rest/v1' -Name 'MyApp' -Credential $Cred
      .EXAMPLE
         'App1', 'App2' | Start-EssbaseApplication -RestUrl 'https://your.domain.com/essbase/rest/v1' -WebSession $Session
      .NOTES
         Created by: Shayne Scovill
      .LINK
         https://docs.oracle.com/en/database/other-databases/essbase/21/essrt/op-applications-application-actions-post.html
   #>
   
   [CmdletBinding()]
   param(
      [Parameter(Mandatory, Position = 0)]
      [ValidateNotNullOrEmpty()]
      [string]$RestUrl,
      
      [Parameter(Mandatory, ValueFromPipeline)]
      [ValidateNotNullOrEmpty()]
      [string[]]$Name,
      
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
         $Uri = "$RestUrl/applications/$ApplicationName`?action=start"
         
         try {
            Write-Verbose "Starting application: $ApplicationName"
            $null = Invoke-EssbaseRequest -Method Put -Uri $Uri @AuthParams
            Write-Information "Application '$ApplicationName' start request submitted successfully."
         }
         catch {
            Write-Error "Failed to start application '$ApplicationName': $_"
         }
      }
   }
}