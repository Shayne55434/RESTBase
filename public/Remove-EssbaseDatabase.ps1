function Remove-EssbaseDatabase {
   <#
      .SYNOPSIS
         Delete an Essbase database.
      .DESCRIPTION
         Deletes one or more databases from a specified Essbase application.
      .PARAMETER RestUrl
         The base URL for the REST API (e.g., 'https://your.domain.com/essbase/rest/v1').
      .PARAMETER Application
         Application name where the database exists.
      .PARAMETER Name
         Database name(s) to delete. Supports pipeline input.
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
         Remove-EssbaseDatabase -RestUrl 'https://your.domain.com/essbase/rest/v1' -Application 'MyApp' -Name 'MyDB' -WebSession $Session -WhatIf
      .EXAMPLE
         'DB1', 'DB2' | Remove-EssbaseDatabase -RestUrl 'https://your.domain.com/essbase/rest/v1' -Application 'MyApp' -Credential $Cred -Confirm
      .NOTES
         Created by: Shayne Scovill
      .LINK
         https://docs.oracle.com/en/database/other-databases/essbase/21/essrt/op-applications-application-databases-database-delete.html
   #>
   [CmdletBinding(SupportsShouldProcess)]
   param(
      [Parameter(Mandatory, Position = 0)]
      [ValidateNotNullOrEmpty()]
      [string]$RestUrl,
      
      [Parameter(Mandatory)]
      [ValidateNotNullOrEmpty()]
      [string]$Application,
      
      [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
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
      foreach ($DatabaseName in $Name) {
         $Uri = "$RestUrl/applications/$Application/databases/$DatabaseName"
         
         if ($PSCmdlet.ShouldProcess("Database: $Application.$DatabaseName", "Permanently delete database")) {
            try {
               Write-Verbose "Deleting database: $Application.$DatabaseName"
               $null = Invoke-EssbaseRequest -Method Delete -Uri $Uri @AuthParams
               Write-Information "Database '$Application.$DatabaseName' deleted successfully."
            }
            catch {
               Write-Error "Failed to delete database '$Application.$DatabaseName': $_"
            }
         }
      }
   }
}