<#
   .SYNOPSIS
      Returns a Web Request Session
   .DESCRIPTION
      Returns a Web Request Session that can be stored and used to authenticate and pass header information for subsequent Essbase functions.
   .PARAMETER RestURL <string>
      The base URL for the REST API interface. Example: 'https://your.domain.com/essbase/rest/v1'
   .PARAMETER SessionName <string[]>
      A Web Request Session that contains authentication and header information for the connection. Accepts value(s) from Pipeline.
   .PARAMETER Credentials <pscredential>
      PowerShell credentials that contain authentication information for the connection.
   .INPUTS
      System.String[]
   .OUTPUTS
      System.Object
   .EXAMPLE
      $WebSession = Get-EssbaseWebSession -RestURL 'https://your.domain.com/essbase/rest/v1' -SessionName 'MyWebSession' -Credential $MyCredentials
   .NOTES
      Created by : Shayne Scovill
   .LINK
      https://github.com/Shayne55434/RESTBase
#>
function Get-EssbaseWebSession {
   [CmdletBinding()]
   Param(
      [Parameter(Mandatory, Position=0)]
      [ValidateNotNullOrEmpty()]
      [string]$RestURL,
      
      [Parameter(Mandatory, ValueFromPipeline)]
      [ValidateNotNullOrEmpty()]
      [string[]]$SessionName,
      
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
      else {
         [pscredential]$Credential = Get-Credential -Message 'Please enter your Essbase password' -UserName $Username
         $htbAuthentication.Add('Credential', $Credential)
         Write-Verbose 'Using provided username and password.'
      }
      [array]$arrNames = @()
   }
   process {
      foreach($name in $SessionName) {
         [hashtable]$htbInvokeParameters = @{
            Method = 'Get'
            Uri = "$RestURL/about"
            Credential = $Credential
            SessionVariable = $name
            Headers = @{
               accept = 'Application/JSON'
            }
         }
         
         try {
            $null = Invoke-RestMethod @htbInvokeParameters
            $arrNames += $name
            Write-Verbose "Web session '$name' created."
         }
         catch {
            Write-Error "Could not connect. $($_)"
         }
      }
   }
   end {
      return ($arrNames | ForEach-Object {Get-Variable -Name $_ -ValueOnly})
   }
}