function Disconnect-EssbaseSession {
   <#
      .SYNOPSIS
         Disconnect a session from Essbase.
      .DESCRIPTION
         Disconnects one or more active Essbase sessions by session ID.
      .PARAMETER RestUrl
         The base URL for the REST API (e.g., 'https://your.domain.com/essbase/rest/v1').
      .PARAMETER SessionId
         Session ID(s) to disconnect. Supports pipeline input.
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
         Disconnect-EssbaseSession -RestUrl 'https://your.domain.com/essbase/rest/v1' -SessionId '123456' -WebSession $Session
      .EXAMPLE
         '123', '456', '789' | Disconnect-EssbaseSession -RestUrl 'https://your.domain.com/essbase/rest/v1' -Credential $Cred
      .NOTES
         Created by: Shayne Scovill
      .LINK
         https://docs.oracle.com/en/database/other-databases/essbase/21/essrt/op-sessions-id-delete.html
   #>
   
   [CmdletBinding(SupportsShouldProcess)]
   param(
      [Parameter(Mandatory, Position = 0)]
      [ValidateNotNullOrEmpty()]
      [string]$RestUrl,
      
      [Parameter(Mandatory, ValueFromPipeline)]
      [ValidateNotNullOrEmpty()]
      [string[]]$SessionId,
      
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
      foreach ($Id in $SessionId) {
         $Uri = "$RestUrl/sessions/$Id`?disconnect=true"
         
         if ($PSCmdlet.ShouldProcess("Session ID: $Id", "Disconnect Essbase session")) {
            try {
               Write-Verbose "Disconnecting session: $Id"
               $null = Invoke-EssbaseRequest -Method Delete -Uri $Uri @AuthParams
               Write-Information "Session '$Id' disconnected successfully."
            }
            catch {
               Write-Error "Failed to disconnect session '$Id': $_"
            }
         }
      }
   }
}