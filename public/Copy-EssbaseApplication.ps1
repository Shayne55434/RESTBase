function Copy-EssbaseApplication {
   <#
      .SYNOPSIS
         Copy an Essbase application.
      .DESCRIPTION
         Creates a copy of an existing Essbase application. Optionally deletes the destination application first if it exists.
      .PARAMETER RestUrl
         The base URL for the REST API (e.g., 'https://your.domain.com/essbase/rest/v1').
      .PARAMETER Source
         Source application name to copy from.
      .PARAMETER Destination
         Destination application name(s) to create. Supports pipeline input.
      .PARAMETER DeleteExisting
         Delete destination application(s) before copying if they exist.
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
         Copy-EssbaseApplication -RestUrl 'https://your.domain.com/essbase/rest/v1' -Source 'MyApp' -Destination 'MyAppCopy' -WebSession $Session
      .EXAMPLE
         'Copy1', 'Copy2' | Copy-EssbaseApplication -RestUrl 'https://your.domain.com/essbase/rest/v1' -Source 'MyApp' -Credential $Cred -DeleteExisting
      .NOTES
         Created by: Shayne Scovill
      .LINK
         https://docs.oracle.com/en/database/other-databases/essbase/21/essrt/op-applications-actions-copy-post.html
   #>
   
   [CmdletBinding()]
   param(
      [Parameter(Mandatory, Position = 0)]
      [ValidateNotNullOrEmpty()]
      [string]$RestUrl,
      
      [Parameter(Mandatory)]
      [ValidateNotNullOrEmpty()]
      [string]$Source,
      
      [Parameter(Mandatory, ValueFromPipeline)]
      [ValidateNotNullOrEmpty()]
      [string[]]$Destination,
      
      [Parameter()]
      [switch]$DeleteExisting,
      
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
      foreach ($DestinationName in $Destination) {
         if ($DeleteExisting.IsPresent) {
            try {
               Write-Verbose "Deleting existing application: $DestinationName"
               $null = Remove-EssbaseApplication -RestUrl $RestUrl @AuthParams -Name $DestinationName -Force -Confirm:$false
            }
            catch {
               Write-Warning "Could not delete existing application '$DestinationName': $_"
            }
         }
         
         $Uri = "$RestUrl/applications/actions/copy"
         $Body = @{
            from = $Source
            to   = $DestinationName
         }
         
         try {
            Write-Verbose "Copying application '$Source' to '$DestinationName'"
            $null = Invoke-EssbaseRequest -Method Post -Uri $Uri -Body $Body @AuthParams
            Write-Information "Application copied: $Source -> $DestinationName"
         }
         catch {
            Write-Error "Failed to copy application '$Source' to '$DestinationName': $_"
         }
      }
   }
}