<#
   .SYNOPSIS
      (Re)executes a job
   .DESCRIPTION
      Execute an Essbase job with given parameters or re-execute a previously run job.
   .PARAMETER RestURL <string>
      The base URL for the REST API interface. Example: 'https://your.domain.com/essbase/rest/v1'
   .PARAMETER Application <string>
      The name of the Application to be promoted to.
   .PARAMETER Database <string>
      The name of the Shadow Application to be promoted.
   .PARAMETER JobType <string>
      The name of the job to be executed. <importExcel|dataload|dimbuild|calc|clear|importExcel|exportExcel|lcmExport|lcmImport|clearAggregation|buildAggregation|asoBufferDataLoad|asoBufferCommit|exportData|mdxScript
   .PARAMETER Parameters <hashtable>
      Parameters to be passed along with the job. See here for details: https://docs.oracle.com/en/database/other-databases/essbase/21/essrt/op-jobs-post.html
   .PARAMETER WebSession <WebRequestSession>
      A Web Request Session that contains authentication and header information for the connection.
   .PARAMETER Credentials <pscredential>
      PowerShell credentials that contain authentication information for the connection.
   .INPUTS
      None
   .OUTPUTS
      None
   .EXAMPLE
      Invoke-EssbaseJob -RestURL 'https://your.domain.com/essbase/rest/v1' -Application 'Test' -Database 'myDB' -JobType 'calc' -WebSession $MyWebSession
   .EXAMPLE
      Invoke-EssbaseJob -RestURL 'https://your.domain.com/essbase/rest/v1' -Application 'Test' -Database 'myDB' -Credential $MyCredentials
   .NOTES
      Created by : Shayne Scovill
   .LINK
      https://github.com/Shayne55434/RESTBase
#>
function Invoke-EssbaseJob() {
   [CmdletBinding()]
   param(
      [Parameter(Mandatory, Position=0)]
      [ValidateNotNullOrEmpty()]
      [string]$RestURL,
      
      [Parameter()]
      [ValidateNotNullOrEmpty()]
      [int]$JobID,
      
      [Parameter(Mandatory, ParameterSetName='NewJob')]
      [ValidateNotNullOrEmpty()]
      [string]$Application,
      
      [Parameter(Mandatory, ParameterSetName='NewJob')]
      [ValidateNotNullOrEmpty()]
      [string]$Database,
      
      [Parameter(Mandatory, ParameterSetName='NewJob')]
      [ValidateNotNullOrEmpty()]
      [string]$JobType,
      
      [Parameter(Mandatory, ParameterSetName='NewJob')]
      [ValidateNotNullOrEmpty()]
      [hashtable]$Parameters,
      
      [Parameter()]
      [ValidateNotNullOrEmpty()]
      [switch]$Wait,
      
      [Parameter(ParameterSetName='NewJob')]
      [Parameter(Mandatory, ParameterSetName='WebSession')]
      [ValidateNotNullOrEmpty()]
      [Microsoft.PowerShell.Commands.WebRequestSession]$WebSession,
      
      [Parameter(ParameterSetName='NewJob')]
      [Parameter(Mandatory, ParameterSetName='Credential')]
      [ValidateNotNullOrEmpty()]
      [pscredential]$Credential,
      
      [Parameter(ParameterSetName='NewJob')]
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
   
   if ($JobID) {
      [hashtable]$htbInvokeParameters = @{
         Method = 'Post'
         Uri = "$RestURL/jobs/$JobID"
         ContentType = 'Application/JSON'
         Headers = @{
            accept = 'Application/JSON'
         }
      }
   }
   else {
      [hashtable]$htbInvokeParameters = @{
         Method = 'Post'
         Uri = "$RestURL/jobs"
         ContentType = 'Application/JSON'
         Body = @{
            application = $Application
            db = $Database
            jobtype = $JobType
            parameters = $Parameters
         } | ConvertTo-Json
         Headers = @{
            accept = 'Application/JSON'
         }
      }
   }
   $htbInvokeParameters += $htbAuthentication
   
   try {
      # Invoke Job
      [object]$objJobResults = Invoke-RestMethod @htbInvokeParameters
      Write-Verbose $objJobResults
      
      if ($Wait.IsPresent) {
         # Wait for the job to complete
         Write-Host 'Job in progress.' -NoNewLine
         do {
            Write-Host '.' -NoNewLine
            [object]$objJobDetails = Get-EssbaseJob -RestURL $RestURL -JobID $objJobResults.job_ID @htbAuthentication
            Start-Sleep -Seconds 2
         } while ($objJobDetails.statusMessage -eq 'In Progress')
         Write-Host '.'
         
         return $objJobDetails
      }
      else {
         return $objJobResults
      }
   }
   catch {
      Write-Error "Failed to execute the job. $($_)"
      Pause
   }
}