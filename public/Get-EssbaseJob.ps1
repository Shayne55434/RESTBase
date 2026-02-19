<#
   .SYNOPSIS
      Get Job Details.
   .DESCRIPTION
      Get details of specified job ID(s).
   .PARAMETER RestURL <string>
      The base URL for the REST API interface. Example: 'https://your.domain.com/essbase/rest/v1'
   .PARAMETER JobID <string[]>
      String Array of Job ID(s). Accepts value from Pipeline.
   .PARAMETER WebSession <WebRequestSession>
      A Web Request Session that contains authentication and header information for the connection.
   .PARAMETER Credential <pscredential>
      PowerShell credentials that contain authentication information for the connection.
   .INPUTS
      System.String[]
   .OUTPUTS
      System.Object
   .EXAMPLE
      Get-EssbaseJob -RestURL 'https://your.domain.com/essbase/rest/v1' -JobID '20', '21' -WebSession $MyWebsession
   .EXAMPLE
      Get-EssbaseJob -RestURL 'https://your.domain.com/essbase/rest/v1' -Username 'Myuser@somewhere.com' -Limit 5
   .EXAMPLE
      '20', '21' | Get-EssbaseJob -RestURL 'https://your.domain.com/essbase/rest/v1' -Credential $MyCredentials
   .NOTES
      Created by : Shayne Scovill
   .LINK
      https://github.com/Shayne55434/RESTBase
#>
function Get-EssbaseJob {
   [CmdletBinding()]
   Param(
      [Parameter(Mandatory, Position=0)]
      [ValidateNotNullOrEmpty()]
      [string]$RestURL,
      
      [Parameter(ValueFromPipeline)]
      [ValidateNotNullOrEmpty()]
      [string[]]$JobID,
      
      [Parameter()]
      [ValidateNotNullOrEmpty()]
      [string]$Filter,
      
      [Parameter()]
      [ValidateNotNullOrEmpty()]
      [string]$OrderBy,
      
      [Parameter()]
      [ValidateNotNullOrEmpty()]
      [switch]$Asc,
      
      [Parameter()]
      [ValidateNotNullOrEmpty()]
      [int]$Offset,
      
      [Parameter()]
      [ValidateNotNullOrEmpty()]
      [int]$Limit,
      
      [Parameter()]
      [ValidateNotNullOrEmpty()]
      [switch]$SystemJobs,
      
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
   
   begin {
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
      [array]$Results = @()
      
      # Create the URI to be used
      $URI = "$RestURL/jobs/<jobid>?"
      
      if ($Filter) {
         $URI += '&keyword=' + $Filter
      }
      if ($OrderBy -or $Asc.IsPresent) {
         if (-not($OrderBy)) {
            $OrderBy = 'job_ID'
         }
         $URI += '&orderBy=' + $OrderBy
         
         if ($Asc.IsPresent) {
            $URI += ':asc'
         }
         else {
            $URI += ':desc'
         }
      }
      if ($Offset) {
         $URI += '&offset=' + $Offset
      }
      if ($Limit) {
         $URI += '&limit=' +$Limit
      }
      if ($SystemJobs.IsPresent) {
         $URI += '&systemjobs=true'
      }
   }
   process {
      if ($JobID) {
         foreach ($job in $JobID) {
            [hashtable]$htbInvokeParameters = @{
               Method = 'Get'
               Uri = $URI.Replace('<jobid>', $job)
               Headers = @{
                  accept = 'Application/JSON'
               }
            } + $htbAuthentication
            
            try{
               Write-Debug "Uri: $($htbInvokeParameters.Uri)"
               Write-Verbose 'Getting details for job $job.'
               $Results += Invoke-RestMethod @htbInvokeParameters
            }
            catch {
               Write-Error "Failed to get job details. $($_)"
            }
         }
      }
      else {
         [hashtable]$htbInvokeParameters = @{
            Method = 'Get'
            Uri = $URI.Replace('<jobid>', '')
            Headers = @{
               accept = 'Application/JSON'
            }
         } + $htbAuthentication
         
         try{
            Write-Debug "Uri: $($htbInvokeParameters.Uri)"
            Write-Verbose 'Getting jobs.'
            $Results = (Invoke-RestMethod @htbInvokeParameters).items
         }
         catch {
            Write-Error "Failed to get jobs. $($_)"
         }
      }
   }
   end {
      return $Results
   }
}