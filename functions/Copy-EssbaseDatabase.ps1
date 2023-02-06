<#
   .SYNOPSIS
      Copy a Database.
   .DESCRIPTION
      Creates a copy of an existing Database in a specified Application. If the database already exists, 'DeleteExisting' must be used or the copy will fail.
   .PARAMETER RestURL <string>
      The base URL for the REST API interface. Example: 'https://your.domain.com/essbase/rest/v1'
   .PARAMETER SourceApplication <string>
      String value of the Application where the database to be copied resides.
   .PARAMETER SourceDatabase <string>
      String value of the Database name to be copied.
   .PARAMETER DestinationApplication <string>
      String value of the Application name where the specified database is to be copied.
   .PARAMETER DestinationDatabase <string>
      String value of the Database name to be created.
   .PARAMETER DeleteExisting <switch>
      If used, the Destination Database will be deleted before being copied from the Source Database.
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
      Copy-EssbaseDatabase -RestURL 'https://your.domain.com/essbase/rest/v1' -SourceApplication 'Test' -SourceDatabase 'MyDatabase' -DestinationApplication 'Test' -DestinationDatabase 'MyDatabaseCopy' -WebSession $MyWebSession -DeleteExisting
   .EXAMPLE
      Copy-EssbaseDatabase -RestURL 'https://your.domain.com/essbase/rest/v1' -SourceApplication 'Test' -SourceDatabase 'MyDatabase' -DestinationApplication 'Test' -DestinationDatabase 'MyDatabaseCopy' -Credential $MyCredentials
   .NOTES
      Created by : Shayne Scovill
   .LINK
      https://github.com/Shayne55434/RESTBase
#>
function Copy-EssbaseDatabase  {
   [CmdletBinding()]
   param(
      [Parameter(Mandatory, Position=0)]
      [ValidateNotNullOrEmpty()]
      [string]$RestURL,
      
      [Parameter(Mandatory)]
      [ValidateNotNullOrEmpty()]
      [string]$SourceApplication,
      
      [Parameter(Mandatory)]
      [ValidateNotNullOrEmpty()]
      [string]$SourceDatabase,
      
      [Parameter(Mandatory)]
      [ValidateNotNullOrEmpty()]
      [string]$DestinationApplication,
      
      [Parameter(Mandatory)]
      [ValidateNotNullOrEmpty()]
      [string]$DestinationDatabase,
      
      [Parameter(HelpMessage='If used, the Destination Database will be deleted before being copied from the Source Database.')]
      [ValidateNotNullOrEmpty()]
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
   
   [hashtable]$htbInvokeParameters = @{
      Method = 'Post'
      Uri = "$RestURL/applications/$($SourceApplication)/databases/actions/copy"
      Body = @{
         from = $SourceDatabase
         to = @{
            application = $DestinationApplication
            database = $DestinationDatabase
         }
      } | ConvertTo-Json
      ContentType = 'Application/JSON'
      Headers = @{
         accept = 'Application/JSON'
      }
   } + $htbAuthentication
   
   if ($DeleteExisting.IsPresent) {
      try {
         Write-Verbose "Deleting database '$DestinationDatabase'."
         $null = Remove-EssbaseDatabase -RestURL $RestURL @htbAuthentication -Application $DestinationApplication -Name $DestinationDatabase -Confirm
      }
      catch {
         Write-Error "Unable to delete $DestinationDatabase. $($_)"
      }
   }
   
   try {
      $null = Invoke-RestMethod @htbInvokeParameters
   }
   catch {
      Write-Error $($_)
   }
}