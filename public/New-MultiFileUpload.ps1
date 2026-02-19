function New-MultiFileUpload {
   <#
      .SYNOPSIS
         Initialize a multipart file upload to Essbase.
      .DESCRIPTION
         Creates a multipart upload session for uploading large files to Essbase. Returns an upload ID for subsequent chunk uploads.
      .PARAMETER RestUrl
         The base URL for the REST API (e.g., 'https://your.domain.com/essbase/rest/v1').
      .PARAMETER Path
         Essbase file system path where the file will be uploaded (e.g., '/applications/App/DB/file.txt').
      .PARAMETER Credential
         PowerShell credential object for authentication.
      .PARAMETER AuthToken
         Bearer token for authentication.
      .PARAMETER WebSession
         Existing web session for authentication.
      .PARAMETER Username
         Username for interactive credential prompt.
      .PARAMETER Overwrite
         Overwrite existing file with the same name.
      .INPUTS
         System.String
      .OUTPUTS
         System.String (Upload ID)
      .EXAMPLE
         $UploadId = New-MultiFileUpload -RestUrl 'https://your.domain.com/essbase/rest/v1' -Path '/applications/App/DB/data.txt' -WebSession $Session -Overwrite
      .EXAMPLE
         $Ids = '/applications/App/DB/file1.txt', '/applications/App/DB/file2.txt' | New-MultiFileUpload -RestUrl $Url -Credential $Cred
      .NOTES
         Created by: Shayne Scovill
      .LINK
         https://docs.oracle.com/en/database/other-databases/essbase/21/essrt/op-files-upload-create-post.html
   #>

   [CmdletBinding()]
   param(
      [Parameter(Mandatory, Position = 0)]
      [ValidateNotNullOrEmpty()]
      [string]$RestUrl,
      
      [Parameter(Mandatory, ValueFromPipeline)]
      [ValidateNotNullOrEmpty()]
      [string[]]$Path,
      
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
      $Results = @()
   }
   process {
      foreach ($FilePath in $Path) {
         $EncodedPath = [System.Web.HttpUtility]::UrlEncode($FilePath)
         $Uri = "$RestUrl/files/upload-create?path=$EncodedPath"
         
         if ($Overwrite.IsPresent) {
            $Uri += "&overwrite=true"
            Write-Verbose "Overwrite enabled for '$FilePath'"
         }
         
         try {
            $Response = Invoke-EssbaseRequest -Method Post -Uri $Uri @AuthParams
            Write-Verbose "Created upload session for '$FilePath': $($Response.id)"
            $Results += $Response
         }
         catch {
            Write-Error "Failed to create multipart upload for '$FilePath': $_"
         }
      }
   }
   end {
      return $Results
   }
}