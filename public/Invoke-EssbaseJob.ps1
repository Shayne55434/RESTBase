function Invoke-EssbaseJob {
   <#
      .SYNOPSIS
         Execute or re-execute an Essbase job.
      .DESCRIPTION
         Executes a new Essbase job with specified parameters or re-executes a previously run job by ID.
      .PARAMETER RestUrl
         The base URL for the REST API (e.g., 'https://your.domain.com/essbase/rest/v1').
      .PARAMETER JobId
         Job ID to re-execute.
      .PARAMETER Application
         Application name for the job (required for new jobs).
      .PARAMETER Database
         Database name for the job (required for new jobs).
      .PARAMETER JobType
         Job type: importExcel, dataload, dimbuild, calc, clear, exportExcel, lcmExport, lcmImport, clearAggregation, buildAggregation, asoBufferDataLoad, asoBufferCommit, exportData, mdxScript.
      .PARAMETER Parameters
         Hashtable of job-specific parameters.
      .PARAMETER Wait
         Wait for job completion and return final status.
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
         Invoke-EssbaseJob -RestUrl 'https://your.domain.com/essbase/rest/v1' -Application 'App' -Database 'DB' -JobType 'calc' -Parameters @{script='CALC ALL'} -WebSession $Session
      .EXAMPLE
         Invoke-EssbaseJob -RestUrl 'https://your.domain.com/essbase/rest/v1' -JobId 12345 -Wait -Credential $Cred
      .NOTES
         Created by: Shayne Scovill
      .LINK
         https://docs.oracle.com/en/database/other-databases/essbase/21/essrt/op-jobs-post.html
   #>
   
   [CmdletBinding()]
   param(
      [Parameter(Mandatory, Position = 0)]
      [ValidateNotNullOrEmpty()]
      [string]$RestUrl,
      
      [Parameter()]
      [ValidateNotNullOrEmpty()]
      [int]$JobId,
      
      [Parameter(Mandatory, ParameterSetName = 'NewJob')]
      [ValidateNotNullOrEmpty()]
      [string]$Application,
      
      [Parameter(Mandatory, ParameterSetName = 'NewJob')]
      [ValidateNotNullOrEmpty()]
      [string]$Database,
      
      [Parameter(Mandatory, ParameterSetName = 'NewJob')]
      [ValidateNotNullOrEmpty()]
      [string]$JobType,
      
      [Parameter(Mandatory, ParameterSetName = 'NewJob')]
      [ValidateNotNullOrEmpty()]
      [hashtable]$Parameters,
      
      [Parameter()]
      [switch]$Wait,
      
      [Parameter(ParameterSetName = 'NewJob')]
      [Parameter(Mandatory, ParameterSetName = 'Credential')]
      [ValidateNotNullOrEmpty()]
      [pscredential]$Credential,
      
      [Parameter(ParameterSetName = 'NewJob')]
      [Parameter(Mandatory, ParameterSetName = 'AuthToken')]
      [ValidateNotNullOrEmpty()]
      [string]$AuthToken,
      
      [Parameter(ParameterSetName = 'NewJob')]
      [Parameter(Mandatory, ParameterSetName = 'WebSession')]
      [ValidateNotNullOrEmpty()]
      [Microsoft.PowerShell.Commands.WebRequestSession]$WebSession,
      
      [Parameter(ParameterSetName = 'NewJob')]
      [Parameter(Mandatory, ParameterSetName = 'Username')]
      [ValidateNotNullOrEmpty()]
      [string]$Username
   )
   
   $AuthParams = Resolve-AuthenticationParameter -Credential $Credential -WebSession $WebSession -Username $Username -AuthToken $AuthToken
   
   if ($JobId) {
      $Uri = "$RestUrl/jobs/$JobId"
      $Body = $null
      Write-Verbose "Re-executing job ID: $JobId"
   }
   else {
      $Uri = "$RestUrl/jobs"
      $Body = @{
         application = $Application
         db          = $Database
         jobtype     = $JobType
         parameters  = $Parameters
      }
      Write-Verbose "Executing new job: $JobType on $Application.$Database"
   }
   
   try {
      $JobResults = Invoke-EssbaseRequest -Method Post -Uri $Uri -Body $Body @AuthParams
      Write-Verbose "Job submitted: $($JobResults.job_ID)"
      
      if ($Wait.IsPresent) {
         Write-Host "Job in progress" -NoNewline
         do {
            Write-Host "." -NoNewline
            $JobDetails = Get-EssbaseJob -RestUrl $RestUrl -JobId $JobResults.job_ID @AuthParams
            Start-Sleep -Seconds 2
         } while ($JobDetails.statusMessage -eq 'In Progress')
         Write-Host ""
         
         Write-Information "Job completed with status: $($JobDetails.statusMessage)"
         return $JobDetails
      }
      else {
         return $JobResults
      }
   }
   catch {
      Write-Error "Failed to execute job: $_"
   }
}