function Remove-EssbaseFile {
   <#
      .SYNOPSIS
         Delete files from Essbase file system.
      .DESCRIPTION
         Deletes one or more files from the Essbase file system.
      .PARAMETER RestUrl
         The base URL for the REST API (e.g., 'https://your.domain.com/essbase/rest/v1').
      .PARAMETER FullPath
         Full file path(s) to delete. Supports pipeline input. Example: '/applications/MyApp/MyDB/file.txt'
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
         None
      .EXAMPLE
         Remove-EssbaseFile -RestUrl 'https://your.domain.com/essbase/rest/v1' -FullPath '/applications/MyApp/MyDB/file.txt' -WebSession $Session -Confirm
      .EXAMPLE
         Get-EssbaseFile -RestUrl 'https://your.domain.com/essbase/rest/v1' -Path '/applications/App/DB' -Filter 'err_' | Remove-EssbaseFile -RestUrl 'https://your.domain.com/essbase/rest/v1' -Credential $Cred
      .NOTES
         Created by: Shayne Scovill
      .LINK
         https://docs.oracle.com/en/database/other-databases/essbase/21/essrt/op-files-path-delete.html
   #>
   [CmdletBinding(SupportsShouldProcess)]
   param(
      [Parameter(Mandatory, Position = 0)]
      [ValidateNotNullOrEmpty()]
      [string]$RestUrl,
      
      [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
      [ValidateNotNullOrEmpty()]
      [string[]]$FullPath,
      
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
      foreach ($FilePath in $FullPath) {
         $Uri = "$RestUrl/files$FilePath"
         
         if ($PSCmdlet.ShouldProcess("File: $FilePath", "Delete file")) {
            try {
               Write-Verbose "Deleting file: $FilePath"
               $null = Invoke-EssbaseRequest -Method Delete -Uri $Uri @AuthParams
               Write-Information "File '$FilePath' deleted successfully."
            }
            catch {
               Write-Error "Failed to delete file '$FilePath': $_"
            }
         }
      }
   }
}