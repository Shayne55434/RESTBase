function Get-EssbaseAuthenticationToken {
   <#
      .SYNOPSIS
         Obtains an OAuth2 authentication token for the Essbase REST API using the device code flow.
      .DESCRIPTION
         This function requests a device code from the Essbase Identity Domain, prompts the user to authenticate
         using the provided device code, and then exchanges the device code for an access token and refresh token.
      .PARAMETER IdentityDomainUrl
         The base URL of the Essbase Identity Domain (e.g., https://idp.example.com).
      .PARAMETER ClientId
         The OAuth2 client ID registered in the Essbase Identity Domain.
      .PARAMETER ClientSecret
         The OAuth2 client secret associated with the Client ID.
      .PARAMETER RefreshTokenVariable
         The name of the script-scoped variable to store the refresh token. Default is 'RefreshToken'.
      .OUTPUTS
         Returns the OAuth2 access token as a string.
      .EXAMPLE
         $AuthToken = Get-EssbaseAuthenticationToken -IdentityDomainUrl 'https://idp.example.com' -ClientId 'my-client-id' -ClientSecret 'my-client-secret'
         Obtains an authentication token using the specified Identity Domain URL, Client ID, and Client Secret
      .NOTES
         Created by: Shayne Scovill
   #>
   
   [CmdletBinding(SupportsShouldProcess)]
   param(
      [string]$IdentityDomainUrl,
      [string]$ClientId,
      [string]$ClientSecret,
      [string]$RefreshTokenVariable = 'RefreshToken'
   )
   
   # Request device code
   try {
      $Base64 = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes("$($ClientId):$($ClientSecret)"))
      $RestParams = @{
         Uri         = "${IdentityDomainUrl}/oauth2/v1/device"
         Method      = 'Post'
         ContentType = 'application/x-www-form-urlencoded;charset=utf-8'
         Body        = @{
            response_type = 'device_code'
            scope         = 'urn:opc:idm:__myscopes__  offline_access'
            client_id     = $ClientId
         }
      }
      
      $RequestCodeResponse = Invoke-WebRequest @RestParams -ErrorAction Stop
   }
   catch {
      throw "Device code request failed: $($_)"
   }
   
   if ($RequestCodeResponse.StatusCode -eq 200) {
      $VerificationUri = ($RequestCodeResponse.Content | ConvertFrom-Json).verification_uri
      $DeviceCode = ($RequestCodeResponse.Content | ConvertFrom-Json).device_code
      $UserCode = ($RequestCodeResponse.Content | ConvertFrom-Json).user_code
      
      # Clear-Host
      $ClipboardMessage = ''
      Set-Clipboard -Value $UserCode -ErrorAction SilentlyContinue
      if ((Get-Clipboard -ErrorAction SilentlyContinue) -eq $UserCode) {
         $ClipboardMessage = '(copied to the clipboard) '
      }
      
      Write-Host "`r`nComplete the following steps to authenticate with the Essbase REST API:" -ForegroundColor Green
      Write-Host "`t 1. Navigate to the following URL: " -NoNewline; Write-Host $VerificationUri -ForegroundColor Yellow
      Write-Host "`t 2. If not already, log into Essbase"
      Write-Host "`t 3. Paste the following device code $($ClipboardMessage)when prompted: " -NoNewline; Write-Host $UserCode -ForegroundColor Yellow
      Write-Host ''
      
      if ($PSCmdlet.ShouldContinue('Default Browser', 'Open verification URL')) {
         Start-Process $VerificationUri
      }
      $null = Read-Host -Prompt 'Press Enter after you have completed the verification process'
   }
   else {
      throw "Failed to request device code. Status Code: $($RequestCodeResponse.StatusCode)"
   }
   
   # Request tokens
   try {
      $RestParams = @{
         Uri         = "${IdentityDomainUrl}/oauth2/v1/token"
         Method      = 'Post'
         ContentType = 'application/x-www-form-urlencoded; charset=utf-8'
         Headers     = @{Authorization = "Basic $Base64"}
         Body        = @{
            grant_type  = 'urn:ietf:params:oauth:grant-type:device_code'
            device_code = $DeviceCode
            client_id   = $ClientId
         }
      }
      $TokenResponse = Invoke-WebRequest @RestParams -ErrorAction Stop
   }
   catch {
      throw "Token request failed: $($_)"
   }
   
   if ($TokenResponse.StatusCode -eq 200) {
      $AuthToken = $TokenResponse.Content | ConvertFrom-Json | Select-Object -ExpandProperty access_token
      $RefreshToken = $TokenResponse.Content | ConvertFrom-Json | Select-Object -ExpandProperty refresh_token
      
      # Store the refresh token in a script-scoped variable for potential future use
      Set-Variable -Name $RefreshTokenVariable -Value $RefreshToken -Scope Script -Force
      
      return $AuthToken
   }
   else {
      throw "Failed to authenticate. Status Code: $($TokenResponse.StatusCode)"
   }
}