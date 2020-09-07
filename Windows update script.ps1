#Importowanie modułu windows update
import-module PSWindowsUpdate

#Importowanie modułu wyskakujących okienek
[System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")

#Report do WSUS
Write-Host "Reportowanie do WSUS"
cmd /c "wuauclt /r /DetectNow"
 
#Sprawdzanie czy potrzebny jest restart
Write-Host "Sprawdzanie czy potrzebny jest restart"

function Test-PendingReboot
{
 if (Get-ChildItem "HKLM:\Software\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending" -EA Ignore) { return $true }
 if (Get-Item "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired" -EA Ignore) { return $true }
#if (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager" -Name PendingFileRenameOperations -EA Ignore) { return $true }
  
 try 
 { 
   $util = [wmiclass]"\\.\root\ccm\clientsdk:CCM_ClientUtilities"
   $status = $util.DetermineIfRebootPending()
   
   if(($status -ne $null) -and $status.RebootPending)
   {
		return $true
   }
 }
 catch
 {
	Write-Host "Złapano wyjątek"
 }

 return $false
}

#Uruchamianie aktualizacji dopóty nie bedzie wymagany restart komputera

for($i=0; $i -lt 20; $i++)
{
	if (!(Test-PendingReboot))
	{
        clear
		cmd.exe /c "start UsoClient StartScan"
		Write-Host "Skanuje"
		cmd.exe /c "start UsoClient StartDownload"
		Write-Host "Pobieram"
		cmd.exe /c "start UsoClient StartInstall"
		Write-Host "Instaluje"

        get-WUInstall -AcceptAll -Install -IgnoreReboot
        Write-Host "get-WUInstall"

		Write-Host "Licznik wynosi: $i"
		Start-Sleep -s 10
	}
}


#Instalacja aktualizacji i restart komputera
if (Test-PendingReboot)
	{
$msgBoxInput =  [System.Windows.Forms.MessageBox]::Show($this, 'Wymagany jest restart komputera, proszę zapisać i zamknąć wszystkie programy. Czy można kontynuować?','Aktualizacja systemu Windows','YesNo','Error')
	
switch  ($msgBoxInput) 
{
    'Yes' 
	{
		Start-Process -FilePath .\ShutdownWithUpdates.exe -ArgumentList "/r /f" 
    }
	
    'No' 
	{
		Add-Type -AssemblyName System.Windows.Forms
		[System.Windows.Forms.MessageBox]::Show($this, 'System ponowi próbę za godzine.','Aktualizacja systemu Windows',0,[System.Windows.Forms.MessageBoxIcon]::Exclamation)
		exit
    }
}
	}

#Report do WSUS
Write-Host "Reportowanie do WSUS"
cmd /c "wuauclt /r /DetectNow"

