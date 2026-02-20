function Format-EssbaseOutput {
   <#
      .SYNOPSIS
         Formats Essbase API response objects with PascalCased properties and converted timestamps.
      .PARAMETER InputObject
         The object to format.
      .OUTPUTS
         Formatted object with PascalCased properties and epoch times converted to Local and UTC.
   #>
   
   [CmdletBinding()]
   param(
      [Parameter(ValueFromPipeline)]
      [object[]]$InputObject
   )
   
   begin {
      $MemberFormattingMap = [ordered]@{
         'name'                = @{Name = 'Name'; Expression = {$_.name}}
         'status'              = @{Name = 'Status'; Expression = {$_.status}}
         'description'         = @{Name = 'Description'; Expression = {$_.description}}
         'fullPath'            = @{Name = 'FullPath'; Expression = {$_.fullPath}}
         'type'                = @{Name = 'Type'; Expression = {$_.type}}
         'owner'               = @{Name = 'Owner'; Expression = {$_.owner}}
         'role'                = @{Name = 'Role'; Expression = {$_.role}}
         'appVariablesSetting' = @(
            @{Name = 'ShowVariables'; Expression = {$_.appVariablesSetting.showVariables}},
            @{Name = 'UpdateVariables'; Expression = {$_.appVariablesSetting.updateVariables}}
         )
         'dbVariablesSetting'  = @(
            @{Name = 'ShowDBVariables'; Expression = {$_.dbVariablesSetting.showDBVariables}},
            @{Name = 'UpdateDBVariables'; Expression = {$_.dbVariablesSetting.updateDBVariables}}
         )
         'connectedUsersCount' = @{Name = 'ConnectedUsersCount'; Expression = {$_.connectedUsersCount}}
         'creationTime'        = @(
            @{Name = 'CreationTime'; Expression = {((Get-Date '1970-01-01') + [TimeSpan]::FromMilliseconds($_.creationTime)).ToLocalTime()}},
            @{Name = 'CreationTimeUtc'; Expression = {((Get-Date '1970-01-01') + [TimeSpan]::FromMilliseconds($_.creationTime))}}
         )
         'modifiedBy'          = @{Name = 'ModifiedBy'; Expression = {$_.modifiedBy}}
         'modifiedTime'        = @(
            @{Name = 'ModifiedTime'; Expression = {((Get-Date '1970-01-01') + [TimeSpan]::FromMilliseconds($_.modifiedTime)).ToLocalTime()}},
            @{Name = 'ModifiedTimeUtc'; Expression = {((Get-Date '1970-01-01') + [TimeSpan]::FromMilliseconds($_.modifiedTime))}}
         )
         'startTime'           = @(
            @{Name = 'StartTime'; Expression = {((Get-Date '1970-01-01') + [TimeSpan]::FromMilliseconds($_.startTime)).ToLocalTime()}},
            @{Name = 'StartTimeUtc'; Expression = {((Get-Date '1970-01-01') + [TimeSpan]::FromMilliseconds($_.startTime))}}
         )
         'permissions'         = @{Name = 'Permissions'; Expression = {$_.permissions -join ';'}}
         'startStopAppAllowed' = @{Name = 'StartStopAppAllowed'; Expression = {$_.startStopAppAllowed}}
         'startStopDBAllowed'  = @{Name = 'StartStopDBAllowed'; Expression = {$_.startStopDBAllowed}}
         'inspectAppAllowed'   = @{Name = 'InspectAppAllowed'; Expression = {$_.inspectAppAllowed}}
         'inspectDBAllowed'    = @{Name = 'InspectDBAllowed'; Expression = {$_.inspectDBAllowed}}
         'links'               = @{Name = 'Links'; Expression = {$_.links | Where-Object {$_.method -eq 'GET'} | Select-Object -ExpandProperty href -Unique -ErrorAction Ignore}}
         'application'         = @{Name = 'Application'; Expression = {$_.application}}
         'applicationRole'     = @{Name = 'ApplicationRole'; Expression = {$_.applicationRole}}
      }
   }
   process {
      if (-not $InputObject) {
         Write-Warning 'No input object provided to format.'
         return
      }
      foreach ($Object in $InputObject) {
         $SelectProperties = @()
         $ObjectMembers = $Object | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name -Unique
         $MissingFormatting = $ObjectMembers | Where-Object {$_ -notin $MemberFormattingMap.Keys}
         
         if ($MissingFormatting) {
            Write-Warning "No specific formatting defined for member(s): $($MissingFormatting -join ', ')."
            $SelectProperties += $MissingFormatting
         }
         
         foreach ($Key in $MemberFormattingMap.Keys) {
            # $Key = 'fullPath'
            if ($Key -in $ObjectMembers) {
               $SelectProperties += $MemberFormattingMap[$Key]
            }
         }
         
         $Object | Select-Object -Property $SelectProperties
      }
   }
}