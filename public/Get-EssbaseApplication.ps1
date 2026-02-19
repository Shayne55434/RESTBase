function Get-EssbaseApplication {
   <#
      .SYNOPSIS
         Get a list of Essbase applications.
      .DESCRIPTION
         Retrieves application information from the Essbase server. Can return all applications,
         specific application details, or filtered results.
      .PARAMETER RestUrl
         The base URL for the REST API (e.g., 'https://your.domain.com/essbase/rest/v1').
      .PARAMETER Name
         Specific application name to retrieve details for.
      .PARAMETER Visibility
         Filter results by visibility: ALL, HIDDEN (Shadow Copies), or REGULAR (non-hidden).
      .PARAMETER Filter
         Search keyword to filter results.
      .PARAMETER Offset
         Number of results to skip (for pagination).
      .PARAMETER Limit
         Maximum number of results to return.
      .PARAMETER Credential
         PowerShell credential object for authentication.
      .PARAMETER WebSession
         Existing web session for authentication.
      .PARAMETER Username
         Username for interactive credential prompt.
      .INPUTS
         System.String
      .OUTPUTS
         System.Object
      .EXAMPLE
         Get-EssbaseApplication -RestUrl 'https://your.domain.com/essbase/rest/v1' -Credential $Cred
      .EXAMPLE
         Get-EssbaseApplication -RestUrl 'https://your.domain.com/essbase/rest/v1' -Name 'MyApp' -WebSession $Session
      .EXAMPLE
         Get-EssbaseApplication -RestUrl 'https://your.domain.com/essbase/rest/v1' -Visibility HIDDEN -Username 'user@domain.com'
      .EXAMPLE
         Get-EssbaseApplication -RestUrl 'https://your.domain.com/essbase/rest/v1' -AuthToken $Token
      .NOTES
         Created by: Shayne Scovill
      .LINK
         https://docs.oracle.com/en/database/other-databases/essbase/21/essrt/op-applications-get.html
   #>
   
   [CmdletBinding()]
   param(
      [Parameter(Mandatory, Position = 0)]
      [ValidateNotNullOrEmpty()]
      [string]$RestUrl,
      
      [Parameter(ValueFromPipeline)]
      [ValidateNotNullOrEmpty()]
      [string]$Name,
      
      [Parameter()]
      [ValidateSet('ALL', 'HIDDEN', 'REGULAR')]
      [string]$Visibility,
      
      [Parameter()]
      [ValidateNotNullOrEmpty()]
      [string]$Filter,
      
      [Parameter()]
      [ValidateNotNullOrEmpty()]
      [int]$Offset,
      
      [Parameter()]
      [ValidateNotNullOrEmpty()]
      [int]$Limit,
      
      [Parameter()]
      [switch]$Tree,
      
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
      $SelectProperties = @(
         @{Name = 'Name'; Expression = {$_.name}},
         @{Name = 'Status'; Expression = {$_.status}},
         @{Name = 'Description'; Expression = {$_.description}},
         @{Name = 'Type'; Expression = {$_.type}},
         @{Name = 'Owner'; Expression = {$_.owner}},
         @{Name = 'ShowVariables'; Expression = {$_.appVariablesSetting.showVariables}},
         @{Name = 'UpdateVariables'; Expression = {$_.appVariablesSetting.updateVariables}},
         @{Name = 'ConnectedUsersCount'; Expression = {$_.connectedUsersCount}},
         @{Name = 'CreationTime'; Expression = {((Get-Date '1970-01-01') + [TimeSpan]::FromMilliseconds($_.creationTime)).ToLocalTime()}},
         @{Name = 'CreationTimeUtc'; Expression = {((Get-Date '1970-01-01') + [TimeSpan]::FromMilliseconds($_.creationTime))}},
         @{Name = 'InspectAppAllowed'; Expression = {$_.inspectAppAllowed}},
         @{Name = 'ModifiedBy'; Expression = {$_.modifiedBy}},
         @{Name = 'ModifiedTime'; Expression = {((Get-Date '1970-01-01') + [TimeSpan]::FromMilliseconds($_.modifiedTime)).ToLocalTime()}},
         @{Name = 'ModifiedTimeUtc'; Expression = {((Get-Date '1970-01-01') + [TimeSpan]::FromMilliseconds($_.modifiedTime))}},
         # @{Name = 'Role'; Expression = {$_.role}}, # Only applicable when retrieving a list of applications, not a single application
         @{Name = 'StartStopAppAllowed'; Expression = {$_.startStopAppAllowed}},
         @{Name = 'Links'; Expression = {$_.links | Where-Object {$_.method -eq 'GET'} | Select-Object -ExpandProperty href -Unique -ErrorAction Ignore}}
      )
   }
   process {
      $Uri = "$RestUrl/applications"
      $QueryParams = @()
      
      if ($Tree.IsPresent) {
         $Uri += '/actions/tree'
      }
      elseif ($Visibility) {
         $Uri += "/actions/name/$Visibility"
      }
      elseif ($Name) {
         $Uri += "/$Name"
      }
      else {
         if ($Filter) {$QueryParams += "filter=$([System.Web.HttpUtility]::UrlEncode($Filter))"}
         if ($Offset) {$QueryParams += "offset=$Offset"}
         if ($Limit) {$QueryParams += "limit=$Limit"}
         
         if ($QueryParams) {
            $Uri += "?$($QueryParams -join '&')"
         }
      }
      
      Write-Verbose "Retrieving applications from: $Uri"
      
      $Response = Invoke-EssbaseRequest -Method Get -Uri $Uri @AuthParams
      
      $FormattedResponse = if ($null -ne $Response.items) {
         $Items = @($Response.items)
         
         if ($Tree.IsPresent) {
            $Items | ForEach-Object {
               [PSCustomObject]@{
                  Name      = $_.name
                  Databases = $_.databases.name
               }
            }
         }
         else {
            $HasRole = ($Items | Where-Object {$_.PSObject.Properties.Name -contains 'role'}).Count -gt 0
            if ($HasRole -and -not ($SelectProperties.Name -contains 'Role')) {
               $SelectProperties += @{Name = 'Role'; Expression = {$_.role}}
            }
            
            $Items | Select-Object -Property $SelectProperties
         }
      }
      elseif ($null -ne $Response.name) {
         $Response | Select-Object -Property $SelectProperties
      }
      else {
         $Response
      }
      
      return $FormattedResponse
   }
}