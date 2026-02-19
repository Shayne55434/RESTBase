function New-ShadowCopy {
   <#
      .SYNOPSIS
         Creates a Shadow Copy Application.
      .DESCRIPTION
         Creates a Shadow Copy of an existing Application. Essbase 21c or greater is required to utilize Shadow Copies.
      .PARAMETER RestUrl
         The base URL for the REST API (e.g., 'https://your.domain.com/essbase/rest/v1').
      .PARAMETER PrimaryApplication
         The name of the Application to be copied.
      .PARAMETER ShadowApplication
         The name of the Shadow Application to be created.
      .PARAMETER RunInBackground
         Schedule 'Shadow Copy' as a Job.
      .PARAMETER Timeout
         Time interval (in seconds) to wait for any active write-operations to complete.
      .PARAMETER HideShadow
         Hiding a Shadow Copy prevents anyone from seeing the application.
      .PARAMETER DeleteExisting
         If used, the existing Shadow Application will be forcefully deleted before being recreated/copied from the Primary Application.
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
         New-ShadowCopy -RestUrl 'https://your.domain.com/essbase/rest/v1' -PrimaryApplication 'App' -ShadowApplication 'AppShadow' -WebSession $Session
      .EXAMPLE
         New-ShadowCopy -RestUrl $Url -PrimaryApplication 'App' -ShadowApplication 'Shadow' -Credential $Cred -HideShadow -DeleteExisting -RunInBackground
      .NOTES
         Created by: Shayne Scovill
      .LINK
         https://docs.oracle.com/en/database/other-databases/essbase/21/essrt/op-applications-actions-shadowcopy-post.html
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
      
      [Parameter(HelpMessage = 'Run as a job.')]
      [switch]$RunInBackground,
      
      [Parameter()]
      [int]$Timeout = 0,
      
      [Parameter(HelpMessage = 'Hiding a Shadow Copy prevents anyone from seeing the application, but it also prevents running the compare against it.')]
      [switch]$HideShadow,
      
      [Parameter(HelpMessage = 'If used, the existing Shadow Application will be forcefully deleted before being recreated/copied from the Primary Application.')]
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
         Write-Verbose "Deleting existing shadow application '$ShadowApplication'"
         $null = Remove-EssbaseApplication -RestUrl $RestUrl -Name $ShadowApplication -Force @AuthParams -ErrorAction SilentlyContinue
      }
      catch {
         Write-Verbose "Shadow application '$ShadowApplication' does not exist or could not be deleted"
      }
   }
   
   if (-not($Timeout)) {
      $Timeout = 0
   }
   
   $Body = @{
      primaryAppName               = $PrimaryApplication
      shadowAppName                = $ShadowApplication
      hideShadow                   = $HideShadow.IsPresent
      waitForOngoingUpdatesInSecs  = $Timeout
      runInBackground              = $RunInBackground.IsPresent
   }
   
   $Uri = "$RestUrl/applications/actions/shadowCopy"
   
   try {
      if ($PSCmdlet.ShouldProcess($PrimaryApplication, "Create Shadow Copy")) {
         Write-Verbose "Creating shadow copy of '$PrimaryApplication' as '$ShadowApplication'"
         $JobResults = Invoke-EssbaseRequest -Method Post -Uri $Uri -Body $Body @AuthParams
         
         if ($RunInBackground.IsPresent) {
            $JobId = $JobResults.job_ID
            Write-Verbose "Shadow copy job started: $JobId"
            Write-Host "Shadow copy in progress" -NoNewline
            
            do {
               Write-Host "." -NoNewline
               Start-Sleep -Seconds 2
               $JobDetails = Get-EssbaseJob -RestUrl $RestUrl -JobId $JobId @AuthParams
            } while ($JobDetails.statusMessage -eq 'In Progress')
            
            Write-Host ""
            
            if ($JobDetails.statusMessage -match 'Failed') {
               Write-Error "Shadow copy job failed: $($JobDetails.jobOutputInfo.errorMessage)"
            }
            else {
               Write-Information "Shadow copy completed with status: $($JobDetails.statusMessage)"
               return $JobDetails
            }
         }
         else {
            Write-Verbose "Shadow copy created successfully"
            return $JobResults
         }
      }
   }
   catch {
      Write-Error "Failed to create shadow copy of '$PrimaryApplication': $_"
   }
}