#requires -version 2

# Copyright 2019 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

<#
.SYNOPSIS
  Script to perform several operations on the cocoon agent. It will be run
  from a cron job at a 5 mins interval.
.DESCRIPTION
  The script is intended for the following operations:
    * Start agent if it is not running.
    * Check if there is a new version of the agent then update and restart.
    * Cleanup host state. Killing stuck processes or rebooting if required.

  Only the first operation will be implemented at this time.
.INPUTS
  None
.OUTPUTS
  Log file stored in C:\Users\flutter\agent_manager.log
  Log file stored in C:\Users\flutter\agent_stderr.log
  Log file stored in C:\Users\flutter\agent_stdout.log
.NOTES
  Version:        0.1
  Creation Date:  11/05/2019
  Purpose/Change: Initial agent manager development.

.EXAMPLE
  Schtasks /create /tn "Agent Manager" /sc MINUTE /mo 5 /tr "PowerShell c:\Users\flutter\cocoon\devicelab\agent_manager.ps1"
#>

#---------------------------------------------------------[Initialisations]--------------------------------------------------------

#----------------------------------------------------------[Declarations]----------------------------------------------------------

$AgentFolder = 'C:\Users\flutter\cocoon\agent'
$LogFile = 'C:\Users\flutter\agent_manager.log'
$StdErr = 'C:\Users\flutter\agent_stderr.log'
$StdOut = 'C:\Users\flutter\agent_stdout.log'


#-----------------------------------------------------------[Functions]------------------------------------------------------------

function Restart-Agent {
    <#
         .SYNOPSIS
             Starts Cocoon agent if it is not running yet.

         .EXAMPLE
             RestartAgent.
    #>
    $Process = Get-Process | Where-Object ProcessName -match '^dart*'
    if (!$Process) {
        Write-Host 'Restarting Agent'
        Set-Location $AgentFolder
        $DartBinaryPath = 'C:\tools\dart-sdk\bin\dart'
        $Arguments = 'bin\agent.dart ci'
        Start-Process $DartBinaryPath -ArgumentList $Arguments -RedirectStandardOutput $StdOut `
            -RedirectStandardError $StdErr -Verbose
    }
}

#-----------------------------------------------------------[Execution]------------------------------------------------------------

Start-Transcript -path $LogFile -append
Restart-Agent
Stop-Transcript

