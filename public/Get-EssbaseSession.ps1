function Get-EssbaseSession {
   <#
      .SYNOPSIS
         Get session information from Essbase.
      .DESCRIPTION
         Retrieves active session information from the Essbase server, optionally filtered by application, database, or user ID.
      .PARAMETER RestUrl
         The base URL for the REST API (e.g., 'https://your.domain.com/essbase/rest/v1').
      .PARAMETER Application
         Filter sessions by application name.
      .PARAMETER Database
         Filter sessions by database name.
      .PARAMETER UserId
         Filter sessions by user ID.
      .PARAMETER Credential
         PowerShell credential object for authentication.
      .PARAMETER AuthToken
         Bearer token for authentication.
      .PARAMETER WebSession
         Existing web session for authentication.
      .PARAMETER Username
         Username for interactive credential prompt.
      .INPUTS
         None
      .OUTPUTS
         System.Object
      .EXAMPLE
         Get-EssbaseSession -RestUrl 'https://your.domain.com/essbase/rest/v1' -WebSession $Session
      .EXAMPLE
         Get-EssbaseSession -RestUrl 'https://your.domain.com/essbase/rest/v1' -Application 'TestCube' -Credential $Cred
      .EXAMPLE
         Get-EssbaseSession -RestUrl 'https://your.domain.com/essbase/rest/v1' -UserId 'admin' -AuthToken $Token
      .NOTES
         Created by: Shayne Scovill
      .LINK
         https://docs.oracle.com/en/database/other-databases/essbase/21/essrt/op-sessions-get.html
   #>
   
   [CmdletBinding()]
   param(
      [Parameter(Mandatory, Position = 0)]
      [ValidateNotNullOrEmpty()]
      [string]$RestUrl,
      
      [Parameter()]
      [ValidateNotNullOrEmpty()]
      [string]$Application,
      
      [Parameter()]
      [ValidateNotNullOrEmpty()]
      [string]$Database,
      
      [Parameter()]
      [ValidateNotNullOrEmpty()]
      [string]$UserId,
      
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
   
   $AuthParams = Resolve-AuthenticationParameter -Credential $Credential -WebSession $WebSession -Username $Username -AuthToken $AuthToken
   
   # Build URI with query parameters
   $QueryParams = @()
   if ($Application) {$QueryParams += "application=$([System.Web.HttpUtility]::UrlEncode($Application))"}
   if ($Database) {$QueryParams += "database=$([System.Web.HttpUtility]::UrlEncode($Database))"}
   if ($UserId) {$QueryParams += "userId=$([System.Web.HttpUtility]::UrlEncode($UserId))"}
   
   $Uri = "$RestUrl/sessions"
   if ($QueryParams) {
      $Uri += "?$($QueryParams -join '&')"
   }
   
   Write-Verbose "Retrieving sessions from: $Uri"
   
   try {
      $Response = Invoke-EssbaseRequest -Method Get -Uri $Uri @AuthParams
      return $Response
   }
   catch {
      Write-Error "Failed to get Essbase sessions: $_"
   }
}