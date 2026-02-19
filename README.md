# RESTBase

PowerShell module for administering Oracle Essbase via REST API.

## Features

- Session management (create, retrieve, disconnect)
- Application lifecycle (create, copy, start, stop, delete)
- Database operations (create, copy, delete)
- File management (upload, download, delete)
- Job execution and monitoring
- Shadow copy/promote workflows
- Report execution

## Requirements

- PowerShell 5.1+ or PowerShell 7+
- Network access to Essbase REST API endpoint
- Valid Essbase credentials with appropriate permissions

## Installation

Clone the repository and import the module:

```powershell
Import-Module .\RESTBase.psd1 -Force
Get-Command -Module RESTBase
```

## Quick Start

```powershell
Import-Module .\RESTBase.psd1 -Force

# Get help for any command
Get-Help Get-EssbaseApplication -Full

# Retrieve all applications
Get-EssbaseApplication -RestUrl 'https://your.domain.com/essbase/rest/v1' -Credential $Cred

# Start an application
Start-EssbaseApplication -RestUrl 'https://...' -Name 'MyApp' -Credential $Cred
```

## Module Structure

```
RESTBase/
├── RESTBase.psd1         # Module manifest
├── RESTBase.psm1         # Module loader
├── public/               # Exported functions
│   ├── Get-EssbaseApplication.ps1
│   ├── Start-EssbaseApplication.ps1
│   ├── Stop-EssbaseApplication.ps1
│   └── ... (other commands)
└── private/              # Internal helpers
    ├── Invoke-EssbaseRequest.ps1
    └── Resolve-AuthenticationParameter.ps1
```

## Authentication

All functions support three authentication methods:

1. **Credential Object** (Recommended for automation)
   ```powershell
   $Cred = Get-Credential
   Get-EssbaseApplication -RestUrl '...' -Credential $Cred
   ```

2. **Web Session** (Recommended for performance)
   ```powershell
   $Session = Get-EssbaseWebSession -RestUrl '...' -Credential $Cred
   Get-EssbaseApplication -RestUrl '...' -WebSession $Session
   ```

3. **Interactive** (Default if no auth provided)
   ```powershell
   Get-EssbaseApplication -RestUrl '...' -Username 'user@domain.com'
   # You'll be prompted for password
   ```

## API Documentation

All functions reference the official Oracle Essbase REST API documentation:
https://docs.oracle.com/en/database/other-databases/essbase/21/essrt/

## Examples

### Applications

```powershell
# List all applications
Get-EssbaseApplication -RestUrl '...' -Credential $Cred

# Get specific application
Get-EssbaseApplication -RestUrl '...' -Name 'MyApp' -Credential $Cred

# Start/stop applications
Start-EssbaseApplication -RestUrl '...' -Name 'MyApp' -Credential $Cred
Stop-EssbaseApplication -RestUrl '...' -Name 'MyApp' -Credential $Cred

# Copy application
Copy-EssbaseApplication -RestUrl '...' -Source 'MyApp' -Destination 'MyAppBackup' -Credential $Cred
```

### Databases

```powershell
# List databases in application
Get-EssbaseDatabase -RestUrl '...' -Application 'MyApp' -Credential $Cred

# Copy database
Copy-EssbaseDatabase -RestUrl '...' \
  -Source Application 'MyApp' \
  -SourceDatabase 'MyDB' \
  -DestinationApplication 'MyApp' \
  -DestinationDatabase 'MyDBCopy' \
  -Credential $Cred
```

### Files

```powershell
# List files in application/database
Get-EssbaseFile -RestUrl '...' -Path '/applications/MyApp/MyDB' -Credential $Cred

# Upload file
Out-EssbaseFile -RestUrl '...' \
  -Application 'MyApp' \
  -Database 'MyDB' \
  -FilePath 'C:\MyFile.txt' \
  -Credential $Cred
```

## Performance Considerations

For best performance in scripts:

1. **Use web sessions** instead of credentials to avoid repeated authentication
2. **Batch operations** where possible
3. **Use filters and limits** to reduce data transfer
4. **Enable verbose logging** during troubleshooting: `$VerbosePreference = 'Continue'`

## License

MIT License - See module manifest for details.

## Support

For issues and contributions, visit: https://github.com/Shayne55434/RESTBase
