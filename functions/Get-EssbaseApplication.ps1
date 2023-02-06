<#
   .SYNOPSIS
      Get a list of Applications from Essbase.
   .DESCRIPTION
      Get a list of Applications from Essbase with the specified visibilty.
   .PARAMETER RestURL <string>
      The base URL for the REST API interface. Example: 'https://your.domain.com/essbase/rest/v1'
   .PARAMETER Application <string>
      Gets the details of the specified application.
   .PARAMETER Filter <string>
      Filters the results.
   .PARAMETER Offset <int>
      Excludes the first $Offset from the results.
   .PARAMETER Limit <int>
      Limits the number of results.
   .PARAMETER Visibility <string>
      ALL shows every application. HIDDEN shows only hidden (Shadow Copy) applications. REGULAR shows all other applications.
      *** Using this changes the results from an object to a simply array of application names ***
   .PARAMETER WebSession <WebRequestSession>
      A Web Request Session that contains authentication and header information for the connection.
   .PARAMETER Credentials <pscredential>
      PowerShell credentials that contain authentication information for the connection.
   .INPUTS
      None
   .OUTPUTS
      System.Object
   .EXAMPLE
      Get-EssbaseApplication -RestURL 'https://your.domain.com/essbase/rest/v1' -Visibility ALL -WebSession $MyWebSession
   .EXAMPLE
      Get-EssbaseApplication -RestURL 'https://your.domain.com/essbase/rest/v1' -Visibility REGULAR -Credential $MyCredentials
   .NOTES
      Created by : Shayne Scovill
   .LINK
      https://github.com/Shayne55434/RESTBase
#>
function Get-EssbaseApplication {
   [CmdletBinding()]
   Param(
      [Parameter(Mandatory, Position=0)]
      [ValidateNotNullOrEmpty()]
      [string]$RestURL,
      
      [Parameter(ValueFromPipeline)]
      [ValidateNotNullOrEmpty()]
      [string]$Application,
      
      [Parameter()]
      [ValidateNotNullOrEmpty()]
      [string]$Filter,
      
      [Parameter()]
      [ValidateNotNullOrEmpty()]
      [int]$Offset,
      
      [Parameter()]
      [ValidateNotNullOrEmpty()]
      [int]$Limit,
      
      [Parameter(HelpMessage='ALL shows every application. HIDDEN shows only hidden (Shadow Copy) applications. REGULAR shows all other applications.')]
      [ValidateSet('ALL', 'HIDDEN', 'REGULAR')]
      [string]$Visibility,
      
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
   
   # Warn on any invalid parameters
   if ($Application -and ($Visibility -or $Filter -or $Offset -or $Limit)) {
      Write-Warning 'Application should not be used with other arguments (Visibility, Filter, Offset, or Limit). Application will take precedence.'
   }
   elseif ($Visibility) {
      Write-Warning 'Using Visibility will return an array of names rather than an object.'
      
      if ($Filter -or $Offset -or $Limit) {
         Write-Warning 'Visibility should not be used with other arguments (Filter, Offset, or Limit). Visibility will take precedence.'
      }
   }

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
   
   # Create the URI to be used
   $URI = "$RestURL/applications"
   $ApplicationResults = $null
   if ($Application) {
      $URI += "/$Application"
      Write-Verbose "Getting application details..."
   }
   elseif ($Visibility) {
      $URI += "/actions/name/$($Visibility)"
      Write-Verbose "Getting a list of application names..."
   }
   else {
      Write-Verbose "Getting application details..."
      $URI += '?'
      
      if ($Filter) {
         $URI += '&filter=' + $Filter
      }
      if ($Offset) {
         $URI += '&offset=' + $Offset
      }
      if ($Limit) {
         $URI += '&limit=' +$Limit
      }
   }
   
   [hashtable]$htbInvokeParameters = @{
      Method = 'Get'
      Uri = $URI
      Headers = @{
         accept = 'Application/JSON'
      }
   } + $htbAuthentication
   
   try {
      Write-Verbose "URI: $($URI)."
      $ApplicationResults = Invoke-RestMethod @htbInvokeParameters
      
      # If an application is not specified, the results are returned inside an object named "items".
      # To maintain consistancy, we'll only store the contents of this object.
      if (-not ($Application) -and -not($Visibility)) {
         [object]$ApplicationResults = $ApplicationResults.items
      }
   }
   catch {
      Write-Error "Failed to get applications. $($_)"
   }
   
   return $ApplicationResults
}