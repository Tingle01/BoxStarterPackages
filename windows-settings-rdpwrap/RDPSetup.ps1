Param(
    	[Parameter(Mandatory = $true)]
    	[string] $AdminUsername,
	[Parameter(Mandatory = $true)]
    	[string] $AdminPassword
)
Start-Sleep -seconds 60
$logsFolder = "C:\RDPSetup"
$Date = Get-Date -f yyyyMMdd_HHmm
Start-Transcript -Path "$logsFolder\RDPSetup.log"

Function Installer ($Installer)
  {
    $obj = new-object -ComObject WScript.Shell
    $obj.SendKeys($Installer)
  } 

  # Set ignore cert errors on RDP
  $RegPath = "HKLM:\SOFTWARE\Microsoft\Terminal Server Client"
  Set-ItemProperty $RegPath "AuthenticationLevelOverride" -Value "0" -type DWord

  # open Remote Desktop with 'local\administrator'
  stop-process -processname MicrosoftEdge -Force -ErrorAction SilentlyContinue
  Start-Sleep -Seconds 10
  $hostname = "127.0.0.2"
  
  Write-Host "starting connection to '$hostname' using '$hostname\SageAdmin' credentials!"
  cmdkey /delete:"$hostname" # probably not needed, just clears the credentials
  cmdkey /generic:"$hostname" /user:"$AdminUsername" /pass:"$AdminPassword"
  Start-Process "$env:windir\system32\mstsc.exe" -ArgumentList "/v:$hostname /w:1280 /h:1024"
  
  try
  {
    #Maximise RDP
    Start-Sleep -Seconds 5
    write-output "send key: % x"
    Installer {"% x"}
  }
  catch
  {
    write-host "Error!!!!"
    Pause
  }

  Write-Host "RDP done!"
