function Get-EssbaseFile {
   <#
      .SYNOPSIS
         List files from Essbase file system.
      .DESCRIPTION
         Retrieves a list of files and folders from specified paths in the Essbase file system. Supports filtering by name and type.
      .PARAMETER RestUrl
         The base URL for the REST API (e.g., 'https://your.domain.com/essbase/rest/v1').
      .PARAMETER Path
         File system path(s) to list. Supports pipeline input. Example: '/applications/MyApp/MyDB'
      .PARAMETER Filter
         Filter files by name pattern.
      .PARAMETER Type
         Filter by file type.
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
         Get-EssbaseFile -RestUrl 'https://your.domain.com/essbase/rest/v1' -Path '/applications/MyApp/MyDB' -WebSession $Session
      .EXAMPLE
         '/applications/App1/DB1', '/applications/App2/DB2' | Get-EssbaseFile -RestUrl 'https://your.domain.com/essbase/rest/v1' -Filter 'err_' -Credential $Cred
      .NOTES
         Created by: Shayne Scovill
      .LINK
         https://docs.oracle.com/en/database/other-databases/essbase/21/essrt/op-files-path-get.html
   #>
   
   [CmdletBinding()]
   param(
      [Parameter(Mandatory, Position = 0)]
      [ValidateNotNullOrEmpty()]
      [string]$RestUrl,
      
      [Parameter(Mandatory, ValueFromPipeline)]
      [ValidateNotNullOrEmpty()]
      [string[]]$Path,
      
      [Parameter()]
      [ValidateNotNullOrEmpty()]
      [string]$Filter,
      
      [Parameter()]
      [ValidateNotNullOrEmpty()]
      [string]$Type,
      
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
      $Files = @()
   }
   process {
      foreach ($FilePath in $Path) {
         $QueryParams = @()
         if ($Filter) {$QueryParams += "filter=$([System.Web.HttpUtility]::UrlEncode($Filter))"}
         if ($Type) {$QueryParams += "type=$([System.Web.HttpUtility]::UrlEncode($Type))"}
         
         $Uri = "$RestUrl/files$FilePath"
         if ($QueryParams) {
            $Uri += "?$($QueryParams -join '&')"
         }
         
         try {
            Write-Verbose "Retrieving files from: $FilePath"
            $Response = Invoke-EssbaseRequest -Method Get -Uri $Uri @AuthParams
            
            # Extract items array for consistency
            if ($Response.items) {
               $Files += $Response.items
            }
            else {
               $Files += $Response
            }
         }
         catch {
            Write-Error "Failed to get files from '$FilePath': $_"
         }
      }
   }
   
   end {
      return $Files
   }
}