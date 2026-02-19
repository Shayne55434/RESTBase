function Copy-EssbaseDatabase {
   <#
      .SYNOPSIS
         Copy an Essbase database.
      .DESCRIPTION
         Creates a copy of an existing database within or across Essbase applications. Optionally deletes the destination database first if it exists.
      .PARAMETER RestUrl
         The base URL for the REST API (e.g., 'https://your.domain.com/essbase/rest/v1').
      .PARAMETER SourceApplication
         Source application name.
      .PARAMETER SourceDatabase
         Source database name to copy from.
      .PARAMETER DestinationApplication
         Destination application name.
      .PARAMETER DestinationDatabase
         Destination database name to create.
      .PARAMETER DeleteExisting
         Delete destination database before copying if it exists.
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
         None
      .EXAMPLE
         Copy-EssbaseDatabase -RestUrl 'https://your.domain.com/essbase/rest/v1' -SourceApplication 'App' -SourceDatabase 'DB' -DestinationApplication 'App' -DestinationDatabase 'DBCopy' -WebSession $Session
      .EXAMPLE
         Copy-EssbaseDatabase -RestUrl 'https://your.domain.com/essbase/rest/v1' -SourceApplication 'App1' -SourceDatabase 'DB' -DestinationApplication 'App2' -DestinationDatabase 'DB' -Credential $Cred -DeleteExisting
      .NOTES
         Created by: Shayne Scovill
      .LINK
         https://docs.oracle.com/en/database/other-databases/essbase/21/essrt/op-applications-application-databases-actions-copy-post.html
   #>
   
   [CmdletBinding()]
   param(
      [Parameter(Mandatory, Position = 0)]
      [ValidateNotNullOrEmpty()]
      [string]$RestUrl,
      
      [Parameter(Mandatory)]
      [ValidateNotNullOrEmpty()]
      [string]$SourceApplication,
      
      [Parameter(Mandatory)]
      [ValidateNotNullOrEmpty()]
      [string]$SourceDatabase,
      
      [Parameter(Mandatory)]
      [ValidateNotNullOrEmpty()]
      [string]$DestinationApplication,
      
      [Parameter(Mandatory)]
      [ValidateNotNullOrEmpty()]
      [string]$DestinationDatabase,
      
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
   
   $AuthParams = Resolve-AuthenticationParameter -Credential $Credential -WebSession $WebSession -Username $Username -AuthToken $AuthToken
   
   if ($DeleteExisting.IsPresent) {
      try {
         Write-Verbose "Deleting existing database: $DestinationApplication.$DestinationDatabase"
         $null = Remove-EssbaseDatabase -RestUrl $RestUrl @AuthParams -Application $DestinationApplication -Name $DestinationDatabase -Confirm:$false
      }
      catch {
         Write-Warning "Could not delete existing database '$DestinationApplication.$DestinationDatabase': $_"
      }
   }
   
   $Uri = "$RestUrl/applications/$SourceApplication/databases/actions/copy"
   $Body = @{
      from = $SourceDatabase
      to   = @{
         application = $DestinationApplication
         database    = $DestinationDatabase
      }
   }
   
   try {
      Write-Verbose "Copying database '$SourceApplication.$SourceDatabase' to '$DestinationApplication.$DestinationDatabase'"
      $null = Invoke-EssbaseRequest -Method Post -Uri $Uri -Body $Body @AuthParams
      Write-Information "Database copied: $SourceApplication.$SourceDatabase -> $DestinationApplication.$DestinationDatabase"
   }
   catch {
      Write-Error "Failed to copy database: $_"
   }
}