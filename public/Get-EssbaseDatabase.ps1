function Get-EssbaseDatabase {
   <#
      .SYNOPSIS
         Get Essbase database information.
      .DESCRIPTION
         Retrieves database information from one or more Essbase applications. Can return all databases in an application or specific database details.
      .PARAMETER RestUrl
         The base URL for the REST API (e.g., 'https://your.domain.com/essbase/rest/v1').
      .PARAMETER Application
         Application name(s) to query. Supports pipeline input.
      .PARAMETER Name
         Specific database name to retrieve details for.
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
         System.Object
      .EXAMPLE
         Get-EssbaseDatabase -RestUrl 'https://your.domain.com/essbase/rest/v1' -Application 'MyApp' -WebSession $Session
      .EXAMPLE
         'App1', 'App2' | Get-EssbaseDatabase -RestUrl 'https://your.domain.com/essbase/rest/v1' -Credential $Cred
      .EXAMPLE
         Get-EssbaseDatabase -RestUrl 'https://your.domain.com/essbase/rest/v1' -Application 'MyApp' -Name 'MyDB' -AuthToken $Token
      .NOTES
         Created by: Shayne Scovill
      .LINK
         https://docs.oracle.com/en/database/other-databases/essbase/21/essrt/op-applications-application-databases-get.html
   #>
   
   [CmdletBinding()]
   param(
      [Parameter(Mandatory, Position = 0)]
      [ValidateNotNullOrEmpty()]
      [string]$RestUrl,
      
      [Parameter(Mandatory, ValueFromPipeline)]
      [ValidateNotNullOrEmpty()]
      [string[]]$Application,
      
      [Parameter()]
      [ValidateNotNullOrEmpty()]
      [string]$Name,
      
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
      $Results = @()
   }
   process {
      foreach ($AppName in $Application) {
         $Uri = "$RestUrl/applications/$AppName/databases"
         if ($Name) {
            $Uri += "/$Name"
         }
         
         try {
            Write-Verbose "Retrieving databases from application: $AppName"
            $Response = Invoke-EssbaseRequest -Method Get -Uri $Uri @AuthParams
            
            # Extract items array for consistency when listing multiple databases
            if (-not $Name -and $Response.items) {
               $Results += $Response.items
            }
            else {
               $Results += $Response
            }
         }
         catch {
            Write-Error "Failed to get databases from application '$AppName': $_"
         }
      }
   }
   end {
      return $Results
   }
}