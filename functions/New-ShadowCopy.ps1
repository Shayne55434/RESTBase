<#
   .SYNOPSIS
      Creates a Shadow Copy Application.
   .DESCRIPTION
      Creates a Shadow Copy of an existing Application. Essbase 21c or greater is required to utilize Shadow Copies.
   .PARAMETER RestURL <string>
      The base URL for the REST API interface. Example: 'https://your.domain.com/essbase/rest/v1'
   .PARAMETER PrimaryApplication <string>
      The name of the  Application to be promoted to.
   .PARAMETER ShadowApplication <string>
      The name of the Shadow Application to be promoted.
   .PARAMETER RunInBackground <switch>
      Schedule 'Shadow Copy' as a Job.
   .PARAMETER Timeout <int>
      Time interval (in seconds) to wait for any active write-operations to complete.
   .PARAMETER HideShadow <switch>
      Hiding a Shadow Copy prevents anyone from seeing the application.
   .PARAMETER DeleteExisting <switch>
      If used, the existing Shadow Application will be forcefully deleted before being recreated/copied from the Primary Application.
   .PARAMETER WebSession <WebRequestSession>
      A Web Request Session that contains authentication and header information for the connection.
   .PARAMETER Credential <pscredential>
      PowerShell credentials that contain authentication information for the connection.
   .PARAMETER Username <string>
      If used, you will be prompted to enter your password.
   .INPUTS
      None
   .OUTPUTS
      None
   .EXAMPLE
      New-ShadowCopy -RestURL 'https://your.domain.com/essbase/rest/v1' -PrimaryApplication 'MyApp' -ShadowApplication 'MyShadowApp' -WebSession $MyWebSession
   .EXAMPLE
      New-ShadowCopy -RestURL 'https://your.domain.com/essbase/rest/v1' -PrimaryApplication 'MyApp' -ShadowApplication 'MyShadowApp' -Credential $MyCredentials -HideShadow -DeleteExisting -RunInBackground
   .NOTES
      Created by : Shayne Scovill
   .LINK
      https://github.com/Shayne55434/RESTBase
#>
function New-ShadowCopy {
   [CmdletBinding(SupportsShouldProcess)]
   param(
      [Parameter(Mandatory, Position=0)]
      [ValidateNotNullOrEmpty()]
      [string]$RestURL,
      
      [Parameter(Mandatory)]
      [ValidateNotNullOrEmpty()]
      [string]$PrimaryApplication,
      
      [Parameter(Mandatory)]
      [ValidateNotNullOrEmpty()]
      [string]$ShadowApplication,
      
      [Parameter(HelpMessage='Run as a job.')]
      [switch]$RunInBackground,
      
      [Parameter()]
      [ValidateNotNullOrEmpty()]
      [int]$Timeout,
      
      [Parameter(HelpMessage='Hiding a Shadow Copy prevents anyone from seeing the application, but it also prevents running the compare against it.')]
      [switch]$HideShadow,
      
      [Parameter(HelpMessage='If used, the existing Shadow Application will be forcefully deleted before being recreated/copied from the Primary Application.')]
      [switch]$DeleteExisting,
      
      [Parameter(Mandatory, ParameterSetName='WebSession')]
      [ValidateNotNullOrEmpty()]
      [Microsoft.PowerShell.Commands.WebRequestSession]$WebSession,
      
      [Parameter(Mandatory, ParameterSetName='Credential')]
      [ValidateNotNullOrEmpty()]
      [pscredential]$Credential,
      
      [Parameter(Mandatory, ParameterSetName='Username')]
      [ValidateNotNullOrEmpty()]
      [string]$Username
   )
   
   # Decipher which authentication type is being used
   [hashtable]$htbAuthentication = @{}
   if ($Credential) {
      $htbAuthentication.Add('Credential', $Credential)
      Write-Verbose 'Using provided credentials.'
   }
   elseif ($WebSession) {
      $htbAuthentication.Add('WebSession', $WebSession)
      Write-Verbose 'Using provided Web Session variable.'
   }
   else {
      [pscredential]$Credential = Get-Credential -Message 'Please enter your Essbase password' -UserName $Username
      $htbAuthentication.Add('Credential', $Credential)
      Write-Verbose 'Using provided username and password.'
   }
   
   if ($DeleteExisting.IsPresent) {
      try {
         Write-Verbose "Deleting '$ShadowApplication'."
         # Ignore errors here, since if the application exists, the creation of the Shadow copy will fail.
         # If it does not exist, then this step is pointless and no need to show the error.
         $null = Remove-EssbaseApplication -RestURL $RestURL @htbAuthentication -Name $ShadowApplication -Force -Confirm -ErrorAction SilentlyContinue
      }
      catch {
         Write-Error "Could not delete '$ShadowApplication'. $($_)"
      }
   }
   
   if (-not($Timeout)) {
      $Timeout = 0
   }
   [hashtable]$htbInvokeParameters = @{
      Method = 'Post'
      Uri = "$RestURL/applications/actions/shadowCopy"
      ContentType = 'Application/JSON'
      Body = @{
         primaryAppName= $PrimaryApplication
         shadowAppName = $ShadowApplication
         hideShadow = $HideShadow.IsPresent
         waitForOngoingUpdatesInSecs = $Timeout
         runInBackground = $RunInBackground.IsPresent
      } | ConvertTo-Json
      Headers = @{
         accept = 'Application/JSON'
      }
   }
   $htbInvokeParameters += $htbAuthentication
   
   try {
      if ($PSCmdlet.ShouldProcess("$PrimaryApplication", "Create Shadow Copy")) {
         [object]$objJobResults = Invoke-RestMethod @htbInvokeParameters
         
         # If RunInBackground is selected, wait for the job to complete and report the final Status
         if ($RunInBackground.IsPresent) {
            Write-Debug "Job_ID: $($objJobResults.job_ID); appName: $($objJobResults.appName); dbName: $($objJobResults.dbName); jobType: $($objJobResults.jobType); statusMessage: $($objJobResults.statusMessage);"
            [string]$strProgressCharacter = '.'
            do {
               Write-Progress -CurrentOperation ("Executing job '$($objJobResults.job_ID) - $($objJobResults.jobType)'." ) ("Waiting for the job to complete$strProgressCharacter")
               [object]$objJobDetails = Get-EssbaseJob -RestURL $RestURL -JobID $objJobResults.job_ID @htbAuthentication
               Start-Sleep -Seconds 2
               $strProgressCharacter += '.'
            } while ($objJobDetails.statusMessage -eq 'In Progress')
            Write-Progress -CurrentOperation ("Executing job '$($objJobResults.job_ID) - $($objJobResults.jobType)'.") -Completed "Done waiting for the job to complete."
            
            if($objJobDetails.statusMessage -match 'Failed') {
               Write-Error "The job has failed. $($objJobDetails.jobOutputInfo.errorMessage)."
            }
            else {
               Write-Verbose "Job has completed. Status: $($objJobDetails.statusMessage)."
            }
         }
      }
   }
   catch {
      Write-Error "Unable to create shadow copy of '$PrimaryApplication'. $($_)"
   }
}