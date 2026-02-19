function Invoke-EssbaseRequest {
   <#
      .SYNOPSIS
         Invoke a REST request to the Essbase API with consistent error handling.
      .DESCRIPTION
         Internal helper function that standardizes REST API calls across all module functions.
      .PARAMETER Method
         HTTP method (Get, Post, Put, Delete, etc).
      .PARAMETER Uri
         The REST API endpoint URI.
      .PARAMETER Body
         JSON body for POST/PUT requests.
      .PARAMETER OutFile
         File path to save response content.
      .PARAMETER Credential
         PowerShell credential object.
      .PARAMETER WebSession
         Existing web session object.
      .OUTPUTS
         System.Object
   #>
   
   [CmdletBinding()]
   param(
      [Parameter(Mandatory)]
      [ValidateSet('Get', 'Post', 'Put', 'Delete', 'Patch')]
      [string]$Method,
      
      [Parameter(Mandatory)]
      [ValidateNotNullOrEmpty()]
      [string]$Uri,
      
      [Parameter()]
      [object]$Body,
      
      [Parameter()]
      [string]$OutFile,
      
      [Parameter()]
      [pscredential]$Credential,
      
      [Parameter()]
      [string]$AuthToken,
      
      [Parameter()]
      [Microsoft.PowerShell.Commands.WebRequestSession]$WebSession,
      
      [Parameter()]
      [string]$SessionVariable
   )
   
   $InvokeParams = @{
      Method      = $Method
      Uri         = $Uri
      Headers     = @{
         Accept = 'application/json'
      }
      ErrorAction = 'Stop'
   }
   
   if ($Body) {
      $InvokeParams.Body = $Body | ConvertTo-Json -Depth 10
      $InvokeParams.ContentType = 'application/json'
   }
   
   if ($OutFile) {
      $InvokeParams.OutFile = $OutFile
   }
   
   if ($Credential) {
      $InvokeParams.Credential = $Credential
   }
   elseif ($WebSession) {
      $InvokeParams.WebSession = $WebSession
      
      # Check if session has expired
      $SessionExpiryMs = $WebSession.Cookies.GetCookies($Uri) | Where-Object {$_.Name -eq 'sessionExpiry'} | Select-Object -ExpandProperty Value
      if ($SessionExpiryMs) {
         $SessionExpiry = ((Get-Date '1970-01-01') + [TimeSpan]::FromMilliseconds($SessionExpiryMs)).ToLocalTime()
         
         if ($SessionExpiry -lt (Get-Date)) {
            throw "The provided web session expired on $($SessionExpiry.ToString('MM/dd/yyyy h:mm:ss tt')). Please re-authenticate."
         }
      }
   }
   elseif ($AuthToken) {
      $InvokeParams.Headers.Authorization = "Bearer $AuthToken"
   }
   
   if ($SessionVariable) {
      $InvokeParams.SessionVariable = $SessionVariable
   }
   
   try {
      $ProgressPreference = 'SilentlyContinue'
      # Opted for Invoke-WebRequest over Invoke-RestMethod to capture headers for session expiry
      $Response = Invoke-WebRequest @InvokeParams
      
      # Extract and log session expiry if available
      $ExpiryValue = ($Response.Headers.'Set-Cookie' | ForEach-Object {$_.Split(';')} | Where-Object {$_ -match 'sessionExpiry'}) -replace 'sessionExpiry=', ''
      if ($ExpiryValue) {
         $SessionExpiry = ((Get-Date '1970-01-01') + [TimeSpan]::FromMilliseconds([int64]$ExpiryValue)).ToLocalTime()
         $TimeRemaining = New-TimeSpan -End $SessionExpiry
         
         Write-Verbose "Current session expires on: $($SessionExpiry.ToString('MM/dd/yyyy h:mm:ss tt')) ($($TimeRemaining.ToString('hh\:mm\:ss')) remaining)"
      }
      
      # Store session variable in script scope for reuse
      if ($SessionVariable) {
         $WebSession = Get-Variable -Name $SessionVariable -ValueOnly -ErrorAction SilentlyContinue
         if ($WebSession) {
            Set-Variable -Name $SessionVariable -Value $WebSession -Scope Script -Force
            Write-Verbose "Web session stored in script variable: `$$SessionVariable"
         }
      }
      
      return $Response.Content | ConvertFrom-Json
   }
   catch {
      $ErrorMessage = $_.Exception.Message
      if ($_.Exception.Response) {
         try {
            $StreamReader = [System.IO.StreamReader]::new($_.Exception.Response.GetResponseStream())
            $ErrorBody = $StreamReader.ReadToEnd()
            $StreamReader.Dispose()
            if ($ErrorBody) {
               $ErrorMessage = "$ErrorMessage - $ErrorBody"
            }
         }
         catch {
            # Ignore parsing errors
         }
      }
      Write-Error "REST API request failed: $ErrorMessage"
   }
   finally {
      $ProgressPreference = 'Continue'
   }
}