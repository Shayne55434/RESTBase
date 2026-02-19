# RESTBase

PowerShell module for administering Oracle Essbase through REST API calls.

## Overview

RESTBase provides task-focused commands for common Essbase administration workflows:

- Create and manage authenticated sessions
- Get and manage applications and databases
- Upload, download, and remove files
- Run jobs and inspect job status/report output
- Perform shadow copy/promote workflows
- Start and stop applications

## Requirements

- PowerShell 5.1+ or PowerShell 7+
- Access to an Oracle Essbase REST endpoint
- Credentials with appropriate Essbase permissions

## Install

Import directly from source:

```powershell
Import-Module .\RESTBase.psd1 -Force
```

Verify available commands:

```powershell
Get-Command -Module RESTBase
```

## Module Structure

- `RESTBase.psd1` – module manifest
- `RESTBase.psm1` – module entry point
- `public/` – exported user-facing commands
- `private/` – internal/private helpers

## Exported Commands

### Session

- `Disconnect-EssbaseSession`
- `Get-EssbaseSession`
- `Get-EssbaseWebSession`

### Applications and Databases

- `Get-EssbaseApplication`
- `Remove-EssbaseApplication`
- `Copy-EssbaseApplication`
- `Start-EssbaseApplication`
- `Stop-EssbaseApplication`
- `Get-EssbaseDatabase`
- `Remove-EssbaseDatabase`
- `Copy-EssbaseDatabase`

### Files

- `Get-EssbaseFile`
- `Out-EssbaseFile`
- `Remove-EssbaseFile`
- `New-MultiFileUpload`

### Jobs and Reports

- `Invoke-EssbaseJob`
- `Get-EssbaseJob`
- `Get-EssbaseReport`

### Shadow Operations

- `New-ShadowCopy`
- `Invoke-ShadowPromote`

## Quick Start

```powershell
Import-Module .\RESTBase.psd1 -Force

# List module commands
Get-Command -Module RESTBase

# View command help
Get-Help Get-EssbaseApplication -Detailed
```

## Development Notes

- Public command scripts are located in `public/`.
- Keep functions aligned with `FunctionsToExport` in `RESTBase.psd1`.
- Use standard PowerShell help so examples are discoverable via `Get-Help`.

## License

MIT (see module manifest copyright block and repository license details).
