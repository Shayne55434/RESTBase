function Get-EssbaseWebSession {
   <#
      .SYNOPSIS
         Returns a Web Request Session
      .DESCRIPTION
         Returns a Web Request Session that can be stored and used to authenticate and pass header information for subsequent Essbase functions.
      .PARAMETER RestUrl <string>
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
         $WebSession = Get-EssbaseWebSession -RestUrl 'https://your.domain.com/essbase/rest/v1' -SessionName 'MyWebSession' -Credential $MyCredentials
      .NOTES
         Created by : Shayne Scovill
      .LINK
         https://github.com/Shayne55434/RESTBase
   #>
   
   [CmdletBinding()]
   param(
      [Parameter(Mandatory, Position = 0)]
      [ValidateNotNullOrEmpty()]
      [string]$RestUrl,
      
      [Parameter(Mandatory, ParameterSetName = 'Credential')]
      [ValidateNotNullOrEmpty()]
      [pscredential]$Credential,
      
      [Parameter(Mandatory, ParameterSetName = 'AuthToken')]
      [ValidateNotNullOrEmpty()]
      [string]$AuthToken,
      
      [Parameter(Mandatory, ParameterSetName = 'WebSession')]
      [ValidateNotNullOrEmpty()]
      [Microsoft.PowerShell.Commands.WebRequestSession]$WebSession,
      
      [Parameter(Mandatory, ParameterSetName = 'UserName')]
      [ValidateNotNullOrEmpty()]
      [string]$UserName
   )
   
   begin {
      # Decipher which authentication type is being used
      $AuthParams = Resolve-AuthenticationParameter -Credential $Credential -WebSession $WebSession -UserName $UserName -AuthToken $AuthToken
   }
   process {
      try {
         $null = Invoke-EssbaseRequest -Method Get -Uri "$RestUrl/about" @AuthParams -SessionVariable 'Session' -ErrorAction Stop
         
         return $Session
      }
      catch {
         Write-Error "Could not connect. $($_)"
      }
   }
}