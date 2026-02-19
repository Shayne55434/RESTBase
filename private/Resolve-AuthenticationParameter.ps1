function Resolve-AuthenticationParameter {
   <#
      .SYNOPSIS
         Resolve authentication parameters into credential or web session.
      .DESCRIPTION
         Internal helper that standardizes authentication parameter resolution across functions.
      .OUTPUTS
         System.Collections.Hashtable
   #>
   
   [CmdletBinding()]
   param(
      [Parameter()]
      [pscredential]$Credential,
      
      [Parameter()]
      [string]$AuthToken,
      
      [Parameter()]
      [Microsoft.PowerShell.Commands.WebRequestSession]$WebSession,
      
      [Parameter()]
      [string]$Username
   )
   
   $AuthenticationParams = @{}
   
   if ($Credential) {
      $AuthenticationParams['Credential'] = $Credential
      Write-Verbose 'Using provided credentials.'
   }
   elseif ($WebSession) {
      $AuthenticationParams['WebSession'] = $WebSession
      Write-Verbose 'Using provided web session.'
   }
   elseif ($AuthToken) {
      $AuthenticationParams['AuthToken'] = $AuthToken
      Write-Verbose 'Using provided authentication token.'
   }
   else {
      $CredentialParameters = @{
         Message = 'Enter Essbase credentials'
      }
      if ($Username) {$CredentialParameters.UserName = $Username}
      $Credential = Get-Credential @CredentialParameters
      $AuthenticationParams['Credential'] = $Credential
      Write-Verbose 'Using interactive credentials.'
   }
   
   return $AuthenticationParams
}