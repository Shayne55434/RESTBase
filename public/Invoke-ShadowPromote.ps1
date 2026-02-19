function Invoke-ShadowPromote {
   <#
      .SYNOPSIS
         Promotes a Shadow Copy Application to a Primary Application.
      .DESCRIPTION
         Promotes a Shadow Copy Application to the specified Primary Application.
      .PARAMETER RestUrl
         The base URL for the REST API (e.g., 'https://your.domain.com/essbase/rest/v1').
      .PARAMETER PrimaryApplication
         The name of the Application to be promoted to.
      .PARAMETER ShadowApplication
         The name of the Shadow Application to be promoted.
      .PARAMETER RunInBackground
         Schedule 'Shadow Promote' as a Job.
      .PARAMETER Timeout
         Time interval (in seconds) to wait before forcefully unloading/stopping an application, if it is performing ongoing requests.
         If a graceful unload process fails or takes longer than permitted by this timeout, Essbase forcefully terminates the application.
      .PARAMETER StartApplication
         The Primary application cannot be in the stopped state when promoting a Shadow Copy. Using this switch will attempt to start the application.
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
         Invoke-ShadowPromote -RestUrl 'https://your.domain.com/essbase/rest/v1' -PrimaryApplication 'App' -ShadowApplication 'AppShadow' -WebSession $Session
      .EXAMPLE
         Invoke-ShadowPromote -RestUrl $Url -PrimaryApplication 'App' -ShadowApplication 'Shadow' -Credential $Cred -StartApplication -RunInBackground
      .NOTES
         Created by: Shayne Scovill
      .LINK
         https://docs.oracle.com/en/database/other-databases/essbase/21/essrt/op-applications-actions-shadowpromote-post.html
   #>
   
   [CmdletBinding(SupportsShouldProcess)]
   param(
      [Parameter(Mandatory, Position = 0)]
      [ValidateNotNullOrEmpty()]
      [string]$RestUrl,
      
      [Parameter(Mandatory)]
      [ValidateNotNullOrEmpty()]
      [string]$PrimaryApplication,
      
      [Parameter(Mandatory)]
      [ValidateNotNullOrEmpty()]
      [string]$ShadowApplication,
      
      [Parameter()]
      [switch]$StartApplication,
      
      [Parameter()]
      [switch]$RunInBackground,
      
      [Parameter()]
      [int]$Timeout = 0,
      
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
   
   if ($StartApplication.IsPresent) {
      try {
         Write-Verbose "Starting '$ShadowApplication'"
         $null = Start-EssbaseApplication -RestUrl $RestUrl -Application $ShadowApplication @AuthParams
      }
      catch {
         Write-Error "Failed to start '$ShadowApplication': $_"
      }
   }
   
   if (-not($Timeout)) {
      $Timeout = 0
   }
   
   $Body = @{
      shadowAppName            = $ShadowApplication
      primaryAppName           = $PrimaryApplication
      timeoutToForceUnloadApp  = $Timeout
      runInBackground          = $RunInBackground.IsPresent
   }
   
   $Uri = "$RestUrl/applications/actions/shadowPromote"
   
   try {
      if ($PSCmdlet.ShouldProcess($PrimaryApplication, "Promote '$ShadowApplication'")) {
         Write-Verbose "Promoting '$ShadowApplication' to '$PrimaryApplication'"
         $JobResults = Invoke-EssbaseRequest -Method Post -Uri $Uri -Body $Body @AuthParams
         
         if ($RunInBackground.IsPresent) {
            $JobId = $JobResults.job_ID
            Write-Verbose "Shadow promote job started: $JobId"
            Write-Host "Shadow promote in progress" -NoNewline
            
            do {
               Write-Host "." -NoNewline
               Start-Sleep -Seconds 2
               $JobDetails = Get-EssbaseJob -RestUrl $RestUrl -JobId $JobId @AuthParams
            } while ($JobDetails.statusMessage -eq 'In Progress')
            
            Write-Host ""
            
            if ($JobDetails.statusMessage -match 'Failed') {
               Write-Error "Shadow promote job failed: $($JobDetails.jobOutputInfo.errorMessage)"
            }
            else {
               Write-Information "Shadow promote completed with status: $($JobDetails.statusMessage)"
               return $JobDetails
            }
         }
         else {
            Write-Verbose "Shadow promote completed successfully"
            return $JobResults
         }
      }
      else {
         Write-Verbose 'Operation cancelled.'
      }
   }
   catch {
      Write-Error "Failed to promote '$ShadowApplication' to '$PrimaryApplication': $_"
   }
}