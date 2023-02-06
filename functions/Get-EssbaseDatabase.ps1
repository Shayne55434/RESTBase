<#
   .SYNOPSIS
      Get database information for specified Application/Database
   .DESCRIPTION
      Get database information for specified Application/Database
   .PARAMETER RestURL <string>
      The base URL for the REST API interface. Example: 'https://your.domain.com/essbase/rest/v1'
   .PARAMETER Application <string[]>
      String Array value of the Application name for which to get a list of databases. Accepts value from Pipeline.
   .PARAMETER Database <string>
      String value of the Database name for which to get information.
   .PARAMETER WebSession <WebRequestSession>
      A Web Request Session that contains authentication and header information for the connection.
   .PARAMETER Credentials <pscredential>
      PowerShell credentials that contain authentication information for the connection.
   .INPUTS
      System.String[]
   .OUTPUTS
      System.Object
   .EXAMPLE
      Get-EssbaseDatabase -RestURL 'https://your.domain.com/essbase/rest/v1' -Application 'Test1' -WebSession $MyWebSession
   .EXAMPLE
      'Test1', 'Test2' | Get-EssbaseDatabase -RestURL 'https://your.domain.com/essbase/rest/v1' -Credential $MyCredentials
   .EXAMPLE
      Get-EssbaseDatabase -RestURL 'https://your.domain.com/essbase/rest/v1' -Application @('Test1','Test2') -Database 'myDB' -Username 'MyUsername'
   .NOTES
      Created by : Shayne Scovill
   .LINK
      https://github.com/Shayne55434/RESTBase
#>
function Get-EssbaseDatabase {
   [CmdletBinding()]
   param(
      [Parameter(Mandatory, Position=0)]
      [ValidateNotNullOrEmpty()]
      [string]$RestURL,
      
      [Parameter(Mandatory, ValueFromPipeline)]
      [ValidateNotNullOrEmpty()]
      [string[]]$Application,
      
      [Parameter()]
      [ValidateNotNullOrEmpty()]
      [string]$Database,
      
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
      elseif ($WebSession)  {
         $htbAuthentication.Add('WebSession', $WebSession)
         Write-Verbose 'Using provided Web Session variable.'
      }
      else {
         [pscredential]$Credential = Get-Credential -Message 'Please enter your Essbase password' -UserName $Username
         $htbAuthentication.Add('Credential', $Credential)
         Write-Verbose 'Using provided username and password.'
      }
      $arrResults = @()
   }
   process {
      foreach ($app in $Application) {
         $URI = "$RestURL/applications/$($app)/databases/$($Database)"
         
         [hashtable]$htbInvokeParameters = @{
            Method = 'Get'
            Uri = $URI
            ContentType = 'Application/JSON'
            Headers = @{
               accept = 'Application/JSON'
            }
         }  + $htbAuthentication
         
         try {
            Write-Verbose "Getting databases for '$app'."
            $results = Invoke-RestMethod @htbInvokeParameters
            
            # If a database is not specified, the results are returned inside an object named "items".
            # To maintain consistancy, we'll only store the contents of this object.
            if (-not ($Database)) {
               $results = $results.items
            }
            
            $arrResults += $results
         }
         catch {
            Write-Error $($_)
         }
      }
   }
   end {
      return $arrResults
   }
}