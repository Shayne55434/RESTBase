   <#
      .SYNOPSIS
         Upload file(s) to Essbase.
      .DESCRIPTION
         Upload file(s) to Essbase applications and databases.
      .PARAMETER RestUrl
         The base URL for the REST API (e.g., 'https://your.domain.com/essbase/rest/v1').
      .PARAMETER Application
         Name of the Application to upload the file to.
      .PARAMETER Database
         Name of the Database to upload the file to.
      .PARAMETER FilePath
         Full path to the local file to be uploaded. Accepts pipeline input.
      .PARAMETER Credential
         PowerShell credential object for authentication.
      .PARAMETER AuthToken
         Bearer token for authentication.
      .PARAMETER WebSession
         Existing web session for authentication.
      .PARAMETER Username
         Username for interactive credential prompt.
      .PARAMETER Overwrite
         Overwrite existing files with the same name.
      .INPUTS
         System.String[]
      .OUTPUTS
         None
      .EXAMPLE
         Out-EssbaseFile -RestUrl 'https://your.domain.com/essbase/rest/v1' -Application 'App' -Database 'DB' -FilePath 'C:\data.txt' -WebSession $Session -Overwrite
      .EXAMPLE
         'C:\data.txt', 'C:\rules.rul' | Out-EssbaseFile -RestUrl 'https://your.domain.com/essbase/rest/v1' -Application 'App' -Database 'DB' -Credential $Cred
      .NOTES
         Created by: Shayne Scovill
      .LINK
         https://docs.oracle.com/en/database/other-databases/essbase/21/essrt/op-files-applications-application-databases-database-filename-put.html
   #>
function Out-EssbaseFile {
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
      [ValidateScript({ Test-Path -Path $_ })]
      [string[]]$FilePath,
      
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
      [string]$Username,
      
      [Parameter()]
      [switch]$Overwrite
   )
   
   begin {
      $AuthParams = Resolve-AuthenticationParameter -Credential $Credential -WebSession $WebSession -Username $Username -AuthToken $AuthToken
   }
   
   process {
      foreach ($File in $FilePath) {
         $FileIsReadOnly = $false
         $FileName = (Get-Item -Path $File).Name
         
         $Uri = "$RestUrl/files/applications/$Application/$Database/$FileName"
         if ($Overwrite.IsPresent) {
            $Uri += "?overwrite=true"
            Write-Verbose "Overwriting '$FileName' if it exists."
         }
         
         # Remove ReadOnly attribute temporarily (PS 5.1 limitation with Invoke-RestMethod)
         if ((Get-ItemProperty -Path $File).IsReadOnly) {
            $FileIsReadOnly = $true
            Set-ItemProperty -Path $File -Name IsReadOnly -Value $false
            Write-Debug "Removed Read-Only attribute from $File."
         }
         
         try {
            $null = Invoke-EssbaseRequest -Method Put -Uri $Uri -InFile $File @AuthParams
            Write-Verbose "Uploaded '$FileName' to $Application/$Database"
         }
         catch {
            Write-Error "Failed to upload '$File' to '$Application/$Database': $_"
         }
         finally {
            # Restore ReadOnly attribute if it was set
            if ($FileIsReadOnly) {
               Set-ItemProperty -Path $File -Name IsReadOnly -Value $true
               Write-Debug "Restored Read-Only attribute to $File."
            }
         }
      }
   }
}