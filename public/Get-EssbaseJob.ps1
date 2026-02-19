function Get-EssbaseJob {
   <#
      .SYNOPSIS
         Get Essbase job details.
      .DESCRIPTION
         Retrieves job information from Essbase, optionally filtered by job ID, keyword, or other criteria.
      .PARAMETER RestUrl
         The base URL for the REST API (e.g., 'https://your.domain.com/essbase/rest/v1').
      .PARAMETER JobId
         Specific job ID(s) to retrieve. Supports pipeline input.
      .PARAMETER Filter
         Keyword filter for job search.
      .PARAMETER OrderBy
         Field to order results by (e.g., 'job_ID').
      .PARAMETER Asc
         Sort results in ascending order. Default is descending.
      .PARAMETER Offset
         Number of results to skip (for pagination).
      .PARAMETER Limit
         Maximum number of results to return.
      .PARAMETER SystemJobs
         Include system jobs in results.
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
         Get-EssbaseJob -RestUrl 'https://your.domain.com/essbase/rest/v1' -JobId '20', '21' -WebSession $Session
      .EXAMPLE
         Get-EssbaseJob -RestUrl 'https://your.domain.com/essbase/rest/v1' -Limit 5 -OrderBy 'job_ID' -Asc -Credential $Cred
      .EXAMPLE
         '20', '21' | Get-EssbaseJob -RestUrl 'https://your.domain.com/essbase/rest/v1' -AuthToken $Token
      .NOTES
         Created by: Shayne Scovill
      .LINK
         https://docs.oracle.com/en/database/other-databases/essbase/21/essrt/op-jobs-get.html
   #>
   
   [CmdletBinding()]
   param(
      [Parameter(Mandatory, Position = 0)]
      [ValidateNotNullOrEmpty()]
      [string]$RestUrl,
      
      [Parameter(ValueFromPipeline)]
      [ValidateNotNullOrEmpty()]
      [string[]]$JobId,
      
      [Parameter()]
      [ValidateNotNullOrEmpty()]
      [string]$Filter,
      
      [Parameter()]
      [ValidateNotNullOrEmpty()]
      [string]$OrderBy,
      
      [Parameter()]
      [switch]$Asc,
      
      [Parameter()]
      [ValidateNotNullOrEmpty()]
      [int]$Offset,
      
      [Parameter()]
      [ValidateNotNullOrEmpty()]
      [int]$Limit,
      
      [Parameter()]
      [switch]$SystemJobs,
      
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
      
      # Build query parameters
      $QueryParams = @()
      if ($Filter) {$QueryParams += "keyword=$([System.Web.HttpUtility]::UrlEncode($Filter))"}
      if ($OrderBy) {
         $SortDirection = if ($Asc.IsPresent) {'asc'} else {'desc'}
         $QueryParams += "orderBy=$([System.Web.HttpUtility]::UrlEncode($OrderBy)):$SortDirection"
      }
      if ($Offset) {$QueryParams += "offset=$Offset"}
      if ($Limit) {$QueryParams += "limit=$Limit"}
      if ($SystemJobs.IsPresent) {$QueryParams += "systemjobs=true"}
   }
   process {
      if ($JobId) {
         foreach ($Job in $JobId) {
            $Uri = "$RestUrl/jobs/$Job"
            if ($QueryParams) {
               $Uri += "?$($QueryParams -join '&')"
            }
            
            try {
               Write-Verbose "Retrieving job details for: $Job"
               $Results += Invoke-EssbaseRequest -Method Get -Uri $Uri @AuthParams
            }
            catch {
               Write-Error "Failed to get job details for '$Job': $_"
            }
         }
      }
      else {
         $Uri = "$RestUrl/jobs"
         if ($QueryParams) {
            $Uri += "?$($QueryParams -join '&')"
         }
         
         try {
            Write-Verbose "Retrieving job list from: $Uri"
            $Response = Invoke-EssbaseRequest -Method Get -Uri $Uri @AuthParams
            
            if ($Response.items) {
               $Results = $Response.items
            }
            else {
               $Results = $Response
            }
         }
         catch {
            Write-Error "Failed to get jobs: $_"
         }
      }
   }
   end {
      return $Results
   }
}