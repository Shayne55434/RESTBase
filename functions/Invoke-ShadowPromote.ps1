<#
   .SYNOPSIS
      Promotes a Shadow Copy Application to a Primary Application.
   .DESCRIPTION
      Promotes a Shadow Copy Application to the specified Primary Application.
   .PARAMETER RestURL <string>
      The base URL for the REST API interface. Example: 'https://your.domain.com/essbase/rest/v1'
   .PARAMETER PrimaryApplication <string>
      The name of the  Application to be promoted to.
   .PARAMETER ShadowApplication <string>
      The name of the Shadow Application to be promoted.
   .PARAMETER RunInBackground <switch>
      Schedule 'Shadow Promote' as a Job.
   .PARAMETER Timeout <int>
      Time interval (in seconds) to wait before forcefully unloading/stopping an application, if it is performing ongoing requests.
      If a graceful unload process fails or takes longer than permitted by this timeout, Essbase forcefully terminates the application.
   .PARAMETER StartApplication <switch>
      The Primary application cannot be in the stopped state when promoting a Shadow Copy. Using this switch will attempt to start the application.
   .PARAMETER WebSession <WebRequestSession>
      A Web Request Session that contains authentication and header information for the connection.
   .PARAMETER Credentials <pscredential>
      PowerShell credentials that contain authentication information for the connection.
   .PARAMETER Username <string>
      If used, you will be prompted to enter your password.
   .INPUTS
      None
   .OUTPUTS
      None
   .EXAMPLE
      Invoke-ShadowPromote -RestURL 'https://your.domain.com/essbase/rest/v1' -PrimaryApplication 'Test' -ShadowApplication 'Test_Shadow' -WebSession $MyWebSession
   .EXAMPLE
      Invoke-ShadowPromote -RestURL 'https://your.domain.com/essbase/rest/v1' -PrimaryApplication 'Test' -ShadowApplication 'Test_Shadow' -Credential $MyCredentials
   .NOTES
      Created by : Shayne Scovill
   .LINK
      https://github.com/Shayne55434/RESTBase
#>
function Invoke-ShadowPromote {
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
      
      [Parameter()]
      [ValidateNotNullOrEmpty()]
      [switch]$StartApplication,
      
      [Parameter()]
      [switch]$RunInBackground,
      
      [Parameter()]
      [ValidateNotNullOrEmpty()]
      [int]$Timeout,
      
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
   
   if (-not($Timeout)) {
      $Timeout = 0
   }
   [hashtable]$htbInvokeParameters = @{
      Method = 'Post'
      Uri = "$RestURL/applications/actions/shadowPromote"
      ContentType = 'Application/JSON'
      Body = @{
         shadowAppName= $ShadowApplication
         primaryAppName = $PrimaryApplication
         timeoutToForceUnloadApp = $Timeout
         runInBackground = $RunInBackground.IsPresent
      } | ConvertTo-Json
      Headers = @{
         accept = 'Application/JSON'
      }
   } + $htbAuthentication
   
   if ($StartApplication.IsPresent) {
      try {
         Write-Verbose "Starting $ShadowApplication."
         $null = Start-EssbaseApplication -RestURL $RestURL @htbAuthentication -Application $ShadowApplication
      }
      catch {
         Write-Error "Unable to start $ShadowApplication. $($_)"
      }
   }
   
   try {
      if ($PSCmdlet.ShouldProcess("$PrimaryApplication" , "Promote '$ShadowApplication'")) {
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
      else {
         Write-Verbose 'Operation cancelled.'
      }
   }
   catch {
      Write-Error "Unable to promote '$ShadowApplication' to '$PrimaryApplication'. $($_)"
   }
}