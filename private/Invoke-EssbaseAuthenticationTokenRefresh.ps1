function Invoke-EssbaseAuthenticationTokenRefresh {
   <#
      .SYNOPSIS
         Refreshes an Oracle Identity Domain OAuth authentication token.
      .DESCRIPTION
         Uses a refresh token to obtain a new access token from Oracle Identity Domain.
      .PARAMETER IdentityDomainUrl
         The base URL for the Oracle Identity Domain.
      .PARAMETER ClientId
         OAuth client ID.
      .PARAMETER ClientSecret
         OAuth client secret.
      .PARAMETER RefreshToken
         Refresh token to use for obtaining a new access token. Defaults to script-scoped variable.
      .OUTPUTS
         System.String (Access token)
      .NOTES
         Created by: Shayne Scovill
   #>
   
   [CmdletBinding()]
   param(
      [string]$IdentityDomainUrl,
      [string]$ClientId,
      [string]$ClientSecret,
      [string]$RefreshToken = $script:RefreshToken
   )
   
   try {
      $Base64 = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes("$($ClientId):$($ClientSecret)"))
      $RestParams = @{
         Uri         = "${IdentityDomainUrl}/oauth2/v1/token"
         Method      = 'Post'
         ContentType = 'application/x-www-form-urlencoded; charset=utf-8'
         Headers     = @{Authorization = "Basic $Base64"}
         Body        = @{
            grant_type    = 'refresh_token'
            refresh_token = $RefreshToken
            client_id     = $ClientId
         }
      }
      
      $TokenResponse = Invoke-WebRequest @RestParams -ErrorAction Stop
   }
   catch {
      throw "Token refresh request failed: $($_)"
   }
   
   if ($TokenResponse.StatusCode -eq 200) {
      $AuthToken = $TokenResponse.Content | ConvertFrom-Json | Select-Object -ExpandProperty access_token
      return $AuthToken
   }
   else {
      throw "Failed to refresh authentication token. Status Code: $($TokenResponse.StatusCode)"
   }
}