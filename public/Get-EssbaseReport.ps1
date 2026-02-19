function Get-EssbaseReport {
   <#
      .SYNOPSIS
         Execute an Essbase report and retrieve results.
      .DESCRIPTION
         Executes an existing report on the Essbase server and returns the results. Can save to file or return as object.
      .PARAMETER RestUrl
         The base URL for the REST API (e.g., 'https://your.domain.com/essbase/rest/v1').
      .PARAMETER Application
         Application name containing the report.
      .PARAMETER Database
         Database name containing the report.
      .PARAMETER ReportName
         Report name(s) to execute (without .rep extension). Supports pipeline input.
      .PARAMETER LockForUpdate
         Lock database for update during report execution.
      .PARAMETER OutFile
         File path to save report results.
      .PARAMETER PassThru
         Return report content even when saving to file.
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
         Get-EssbaseReport -RestUrl 'https://your.domain.com/essbase/rest/v1' -Application 'MyApp' -Database 'MyDB' -ReportName 'Budget' -WebSession $Session
      .EXAMPLE
         Get-EssbaseReport -RestUrl 'https://your.domain.com/essbase/rest/v1' -Application 'MyApp' -Database 'MyDB' -ReportName 'Sales' -OutFile 'C:\report.txt' -PassThru -Credential $Cred
      .NOTES
         Created by: Shayne Scovill
      .LINK
         https://docs.oracle.com/en/database/other-databases/essbase/21/essrt/op-applications-application-databases-database-executereport-get.html
   #>
   
   [CmdletBinding()]
   param(
      [Parameter(Mandatory, Position = 0)]
      [ValidateNotNullOrEmpty()]
      [string]$RestUrl,
      
      [Parameter(Mandatory)]
      [ValidateNotNullOrEmpty()]
      [string]$Application,
      
      [Parameter(Mandatory)]
      [ValidateNotNullOrEmpty()]
      [string]$Database,
      
      [Parameter(Mandatory, ValueFromPipeline)]
      [ValidateNotNullOrEmpty()]
      [string[]]$ReportName,
      
      [Parameter()]
      [switch]$LockForUpdate,
      
      [Parameter()]
      [ValidateNotNullOrEmpty()]
      [string]$OutFile,
      
      [Parameter()]
      [ValidateScript({$null -ne $OutFile -and $OutFile -ne ''})]
      [switch]$PassThru,
      
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
   }
   process {
      foreach ($Report in $ReportName) {
         # Remove .rep extension if present
         $Report = $Report.TrimEnd('.rep')
         # $Report = [System.IO.Path]::GetFileNameWithoutExtension($Report)
         
         $Uri = "$RestUrl/applications/$Application/databases/$Database/executeReport?filename=$([System.Web.HttpUtility]::UrlEncode($Report))&lockForUpdate=$($LockForUpdate.IsPresent)"
         
         try {
            Write-Verbose "Executing report: $Report"
            
            if ($OutFile) {
               Write-Verbose "Saving report results to: $OutFile"
               $Results = Invoke-EssbaseRequest -Method Get -Uri $Uri -OutFile $OutFile @AuthParams
               
               if ($PassThru.IsPresent) {
                  return (Get-Content -Path $OutFile -Raw)
               }
            }
            else {
               $Results = Invoke-EssbaseRequest -Method Get -Uri $Uri @AuthParams
               return $Results
            }
         }
         catch {
            Write-Error "Failed to execute report '$Report': $_"
         }
      }
   }
}