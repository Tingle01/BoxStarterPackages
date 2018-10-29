Param(
	[Parameter(Mandatory = $true)]
    	[string] $AdminUsername,
	[Parameter(Mandatory = $true)]
    	[string] $AdminPassword,
    	[Parameter(Mandatory = $true)]
    	[string] $RDPUsername,
	[Parameter(Mandatory = $true)]
    	[string] $RDPPassword

)

###################################################################################################

#
# PowerShell configurations
#

# NOTE: Because the $ErrorActionPreference is "Stop", this script will stop on first failure.
#       This is necessary to ensure we capture errors inside the try-catch-finally block.
$ErrorActionPreference = "Stop"

# Ensure we set the working directory to that of the script.
pushd $PSScriptRoot

###################################################################################################

#
# Handle all errors in this script.
#
    
	Write-Host "User Login: $AdminUsername, RDP Login: $RDPUsername"
trap
{
    # NOTE: This trap will handle all errors. There should be no need to use a catch below in this
    #       script, unless you want to ignore a specific error.
    $message = $error[0].Exception.Message
    if ($message)
    {
        Write-Host -Object "ERROR: $message" -ForegroundColor Red
    }
    
    # IMPORTANT NOTE: Throwing a terminating error (using $ErrorActionPreference = "Stop") still
    # returns exit code zero from the PowerShell script when using -File. The workaround is to
    # NOT use -File when calling this script and leverage the try-catch-finally block and return
    # a non-zero exit code from the catch block.
    Write-Host 'Artifact failed to apply.'
    exit -1
}

###################################################################################################

#
# Main execution block.
#

  try
     {
	    #Create New User
      NET USER "$RDPUsername" "$RDPPassword" /ADD
      NET LOCALGROUP "Administrators" "$RDPUsername" /add
      NET LOCALGROUP "Remote Desktop Users" "$RDPUsername" /add
      Write-Host "Created User $RDPUsername and added to Groups old way @ $(Get-Date)"
	    
      #Set-up AutoRun
      #Registry path declaration
      $RegPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
      $RegROPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce"

      #setting registry values
      Set-ItemProperty $RegPath "AutoAdminLogon" -Value "1" -type String  
      Set-ItemProperty $RegPath "DefaultUsername" -Value "$RDPUsername" -type String  
      Set-ItemProperty $RegPath "DefaultPassword" -Value "$RDPPassword" -type String
      Set-ItemProperty $RegPath "AutoLogonCount" -Value "5" -type DWord
      Set-ItemProperty $RegROPath "(Default)" -Value "C:\RDPSetup\RDPSetup.bat" -type String
	    Write-Host "Set-up Autorun @ $(Get-Date)"
            
	    #Block Network Discovery
	    reg add "HKLM\SYSTEM\CurrentControlSet\Control\Network\NewNetworkWindowOff" /f
	    Write-Host "Blocking Network Discovery"
	
	    #Create Startup Script
	    $RDPPath = "C:\RDPSetup"
	    New-Item $RDPPath -type directory -force
	    New-Item "$RDPPath\RDPSetup.bat" -type file -force -value "@echo off
	    TIMEOUT 120
	    start /min powershell -executionpolicy bypass $RDPPath\RDPSetup.ps1 -AdminUsername $AdminUsername -AdminPassword $AdminPassword"
	    
	    #Copy Files required
	    Copy-Item .\RDPSetup.ps1 -Destination $RDPPath
	    Copy-Item .\RDPConf.exe -Destination $RDPPath
	    Copy-Item .\RDPWInst.exe -Destination $RDPPath
	    #Copy-Item .\Install.bat -Destination $RDPPath
	    Write-Host "Created Start-up script for user $RDPUsername @ $(Get-Date)" 
	    
	    $winVerString = (Get-WmiObject Win32_OperatingSystem).Caption
	    Write-Output "Detected Windows Version: $winVerString"
	    
      #Install RDP Wrap
	    Write-Host "Installing Workaround @ $(Get-Date)"
	    #& .\install.bat
	    Start-Process -FilePath ".\RDPWInst.exe" -ArgumentList "-i -o" -Verb runas -Wait
	    Write-Host "Start 180 seconds sleep @ $(Get-Date)"
	    Start-Sleep -Seconds 180
	    Write-Host "Artifact Installed @ $(Get-Date)"
      }

finally
{
  popd
}
