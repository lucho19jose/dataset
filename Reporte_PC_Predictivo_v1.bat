@echo off
setlocal EnableDelayedExpansion
title Reporte de Sistema - Version Predictiva v2.0
color 1f
cls

REM ============================================================
REM   SCRIPT DE REPORTE PARA PREDICCION DE FALLOS
REM   Version: 2.0 - Incluye datos SMART, Eventos, Metricas
REM   Autor: IT Department
REM ============================================================

set "OUTFILE=Reporte_%COMPUTERNAME%.txt"

echo ========================================================
echo   GENERANDO REPORTE PREDICTIVO (CMD + POWERSHELL)
echo   Incluye: SMART, Eventos, Metricas de Salud
echo ========================================================

REM --- 1. ENCABEZADO ---
echo [1/10] Creando encabezado...
echo REPORTE GENERADO EL: %DATE% %TIME% > "%OUTFILE%"
echo USUARIO: %USERNAME% >> "%OUTFILE%"
echo EQUIPO: %COMPUTERNAME% >> "%OUTFILE%"
echo. >> "%OUTFILE%"

REM --- 2. SISTEMA OPERATIVO ---
echo [2/10] Obteniendo version de Windows...
echo ======================================================== >> "%OUTFILE%"
echo               SISTEMA OPERATIVO >> "%OUTFILE%"
echo ======================================================== >> "%OUTFILE%"
systeminfo | findstr /B /C:"Nombre del sistema" /C:"Versi" /C:"Fabricante del sistema" /C:"Modelo el sistema" /C:"Tipo de sistema" >> "%OUTFILE%"
echo. >> "%OUTFILE%"

REM --- 3. METRICAS DE SALUD DEL SISTEMA (NUEVO) ---
echo [3/10] Obteniendo metricas de salud...
echo ======================================================== >> "%OUTFILE%"
echo               METRICAS DE SALUD DEL SISTEMA >> "%OUTFILE%"
echo ======================================================== >> "%OUTFILE%"

echo --- Fecha de Instalacion de Windows --- >> "%OUTFILE%"
powershell -NoProfile -Command "$os = Get-CimInstance Win32_OperatingSystem; $installDate = $os.InstallDate; $uptime = (Get-Date) - $os.LastBootUpTime; Write-Output \"Fecha Instalacion: $installDate\"; Write-Output \"Dias desde instalacion: $([math]::Round(((Get-Date) - $installDate).TotalDays))\"; Write-Output \"Ultimo reinicio: $($os.LastBootUpTime)\"; Write-Output \"Uptime actual (dias): $([math]::Round($uptime.TotalDays, 2))\"" >> "%OUTFILE%"
echo. >> "%OUTFILE%"

echo --- Espacio en Disco --- >> "%OUTFILE%"
powershell -NoProfile -Command "Get-CimInstance Win32_LogicalDisk -Filter \"DriveType=3\" | Select-Object DeviceID, @{N='Total_GB';E={[math]::Round($_.Size/1GB,2)}}, @{N='Libre_GB';E={[math]::Round($_.FreeSpace/1GB,2)}}, @{N='Usado_Pct';E={[math]::Round((($_.Size - $_.FreeSpace)/$_.Size)*100,1)}} | Format-Table -AutoSize | Out-String -Width 4096" >> "%OUTFILE%"

echo --- Temperatura y Estado Termico --- >> "%OUTFILE%"
powershell -NoProfile -Command "try { $temp = Get-CimInstance MSAcpi_ThermalZoneTemperature -Namespace root/wmi -ErrorAction Stop | Select-Object @{N='Temperatura_C';E={[math]::Round(($_.CurrentTemperature - 2732) / 10, 1)}}; if($temp) { $temp | Format-Table } else { Write-Output 'No disponible via WMI' } } catch { Write-Output 'Sensor termico no accesible (requiere admin o no soportado)' }" >> "%OUTFILE%"
echo. >> "%OUTFILE%"

REM --- 4. HARDWARE DETALLADO ---
echo [4/10] Analizando Hardware (CPU, RAM, Discos)...
echo ======================================================== >> "%OUTFILE%"
echo               HARDWARE DETALLADO >> "%OUTFILE%"
echo ======================================================== >> "%OUTFILE%"

echo --- Procesador --- >> "%OUTFILE%"
powershell -NoProfile -Command "Get-CimInstance Win32_Processor | Select-Object Name, MaxClockSpeed, NumberOfCores, NumberOfLogicalProcessors | Format-List | Out-String -Width 4096" >> "%OUTFILE%"

echo --- Placa Base y BIOS --- >> "%OUTFILE%"
powershell -NoProfile -Command "Get-CimInstance Win32_BaseBoard | Select-Object Manufacturer, Product, SerialNumber | Format-List | Out-String" >> "%OUTFILE%"
powershell -NoProfile -Command "Get-CimInstance Win32_BIOS | Select-Object SMBIOSBIOSVersion, SerialNumber, @{N='BIOS_Date';E={$_.ReleaseDate}} | Format-List | Out-String" >> "%OUTFILE%"

echo --- Memoria RAM --- >> "%OUTFILE%"
powershell -NoProfile -Command "Get-CimInstance Win32_PhysicalMemory | Select-Object BankLabel, @{N='Capacity_GB';E={[math]::Round($_.Capacity/1GB, 2)}}, Speed, Manufacturer, PartNumber | Format-Table -AutoSize | Out-String -Width 4096" >> "%OUTFILE%"

echo --- Resumen RAM --- >> "%OUTFILE%"
powershell -NoProfile -Command "$ram = Get-CimInstance Win32_PhysicalMemory; $total = [math]::Round(($ram | Measure-Object -Property Capacity -Sum).Sum/1GB, 2); $slots = $ram.Count; $speeds = ($ram | Select-Object -Unique Speed).Speed -join ', '; $manufacturers = ($ram | Select-Object -Unique Manufacturer).Manufacturer -join ', '; Write-Output \"Total RAM: $total GB\"; Write-Output \"Slots usados: $slots\"; Write-Output \"Velocidades: $speeds MHz\"; Write-Output \"Fabricantes: $manufacturers\"; if(($ram | Select-Object -Unique Speed).Count -gt 1) { Write-Output 'ALERTA: RAM con velocidades mixtas' }; if(($ram | Select-Object -Unique Manufacturer).Count -gt 1) { Write-Output 'ALERTA: RAM de diferentes fabricantes' }" >> "%OUTFILE%"
echo. >> "%OUTFILE%"

echo --- Discos Fisicos --- >> "%OUTFILE%"
powershell -NoProfile -Command "Get-CimInstance Win32_DiskDrive | Select-Object Model, InterfaceType, @{N='Size_GB';E={[math]::Round($_.Size/1GB, 2)}}, Status, MediaType | Format-Table -AutoSize | Out-String -Width 4096" >> "%OUTFILE%"

REM --- 5. DATOS SMART DE DISCOS (CRITICO PARA PREDICCION) ---
echo [5/10] Obteniendo datos SMART de discos...
echo ======================================================== >> "%OUTFILE%"
echo               DATOS SMART DE DISCOS >> "%OUTFILE%"
echo ======================================================== >> "%OUTFILE%"
echo (Datos criticos para prediccion de fallos de disco) >> "%OUTFILE%"
echo. >> "%OUTFILE%"

REM Metodo 1: Via WMI (limitado pero sin dependencias)
echo --- Estado de Salud via WMI --- >> "%OUTFILE%"
powershell -NoProfile -Command "Get-CimInstance -Namespace root\wmi -ClassName MSStorageDriver_FailurePredictStatus -ErrorAction SilentlyContinue | Select-Object InstanceName, PredictFailure, Reason | Format-Table -AutoSize | Out-String -Width 4096" >> "%OUTFILE%"

echo --- Informacion de Confiabilidad de Disco --- >> "%OUTFILE%"
powershell -NoProfile -Command "Get-PhysicalDisk -ErrorAction SilentlyContinue | Select-Object FriendlyName, MediaType, HealthStatus, OperationalStatus, @{N='Size_GB';E={[math]::Round($_.Size/1GB,2)}}, SpindleSpeed | Format-Table -AutoSize | Out-String -Width 4096" >> "%OUTFILE%"

echo --- Datos SMART Detallados (si disponible) --- >> "%OUTFILE%"
powershell -NoProfile -Command "try { Get-PhysicalDisk | Get-StorageReliabilityCounter -ErrorAction Stop | Select-Object DeviceId, Temperature, Wear, ReadErrorsTotal, ReadErrorsCorrected, ReadErrorsUncorrected, WriteErrorsTotal, WriteErrorsCorrected, WriteErrorsUncorrected, PowerOnHours, StartStopCycleCount | Format-List | Out-String -Width 4096 } catch { Write-Output 'StorageReliabilityCounter no disponible en este sistema' }" >> "%OUTFILE%"
echo. >> "%OUTFILE%"

REM --- 6. EVENTOS CRITICOS DEL SISTEMA (CLAVE PARA PREDICCION) ---
echo [6/10] Analizando eventos criticos (ultimos 30 dias)...
echo ======================================================== >> "%OUTFILE%"
echo               EVENTOS CRITICOS (ULTIMOS 30 DIAS) >> "%OUTFILE%"
echo ======================================================== >> "%OUTFILE%"
echo (Estos datos son fundamentales para prediccion de fallos) >> "%OUTFILE%"
echo. >> "%OUTFILE%"

echo --- Resumen de Eventos Criticos --- >> "%OUTFILE%"
powershell -NoProfile -Command "$startDate = (Get-Date).AddDays(-30); $events = @{}; $events['BSOD_Kernel_Power'] = (Get-WinEvent -FilterHashtable @{LogName='System'; Id=41; StartTime=$startDate} -ErrorAction SilentlyContinue | Measure-Object).Count; $events['Disk_Errors'] = (Get-WinEvent -FilterHashtable @{LogName='System'; Id=7,9,11,15,55; StartTime=$startDate} -ErrorAction SilentlyContinue | Measure-Object).Count; $events['Memory_Errors'] = (Get-WinEvent -FilterHashtable @{LogName='System'; Id=1101,1102; StartTime=$startDate} -ErrorAction SilentlyContinue | Measure-Object).Count; $events['App_Crashes'] = (Get-WinEvent -FilterHashtable @{LogName='Application'; Id=1000,1001,1002; StartTime=$startDate} -ErrorAction SilentlyContinue | Measure-Object).Count; $events['System_Errors'] = (Get-WinEvent -FilterHashtable @{LogName='System'; Level=2; StartTime=$startDate} -ErrorAction SilentlyContinue | Measure-Object).Count; $events['Critical_Events'] = (Get-WinEvent -FilterHashtable @{LogName='System'; Level=1; StartTime=$startDate} -ErrorAction SilentlyContinue | Measure-Object).Count; foreach($key in $events.Keys) { Write-Output \"$key : $($events[$key])\" }" >> "%OUTFILE%"
echo. >> "%OUTFILE%"

echo --- Ultimos 10 Errores Criticos del Sistema --- >> "%OUTFILE%"
powershell -NoProfile -Command "Get-WinEvent -FilterHashtable @{LogName='System'; Level=1,2} -MaxEvents 10 -ErrorAction SilentlyContinue | Select-Object TimeCreated, Id, LevelDisplayName, @{N='Message';E={$_.Message.Substring(0, [Math]::Min(100, $_.Message.Length)) + '...'}} | Format-Table -AutoSize | Out-String -Width 4096" >> "%OUTFILE%"

echo --- Ultimos 5 BSOD (Kernel-Power 41) --- >> "%OUTFILE%"
powershell -NoProfile -Command "Get-WinEvent -FilterHashtable @{LogName='System'; Id=41} -MaxEvents 5 -ErrorAction SilentlyContinue | Select-Object TimeCreated, @{N='BugCheck';E={$_.Properties[0].Value}} | Format-Table -AutoSize | Out-String -Width 4096" >> "%OUTFILE%"

echo --- Errores de Disco Recientes --- >> "%OUTFILE%"
powershell -NoProfile -Command "Get-WinEvent -FilterHashtable @{LogName='System'; Id=7,9,11,15,55} -MaxEvents 10 -ErrorAction SilentlyContinue | Select-Object TimeCreated, Id, @{N='Message';E={$_.Message.Substring(0, [Math]::Min(80, $_.Message.Length))}} | Format-Table -AutoSize | Out-String -Width 4096" >> "%OUTFILE%"
echo. >> "%OUTFILE%"

REM --- 7. ESTADO DE ACTUALIZACIONES ---
echo [7/10] Verificando estado de actualizaciones...
echo ======================================================== >> "%OUTFILE%"
echo               ESTADO DE ACTUALIZACIONES >> "%OUTFILE%"
echo ======================================================== >> "%OUTFILE%"

echo --- Ultimas 10 Actualizaciones Instaladas --- >> "%OUTFILE%"
powershell -NoProfile -Command "Get-HotFix | Sort-Object InstalledOn -Descending | Select-Object -First 10 HotFixID, Description, InstalledOn | Format-Table -AutoSize | Out-String -Width 4096" >> "%OUTFILE%"

echo --- Dias desde ultima actualizacion --- >> "%OUTFILE%"
powershell -NoProfile -Command "$lastUpdate = (Get-HotFix | Sort-Object InstalledOn -Descending | Select-Object -First 1).InstalledOn; if($lastUpdate) { $days = [math]::Round(((Get-Date) - $lastUpdate).TotalDays); Write-Output \"Ultima actualizacion: $lastUpdate\"; Write-Output \"Dias sin actualizar: $days\"; if($days -gt 60) { Write-Output 'ALERTA: Mas de 60 dias sin actualizaciones' } } else { Write-Output 'No se pudo determinar la ultima actualizacion' }" >> "%OUTFILE%"
echo. >> "%OUTFILE%"

REM --- 8. TARJETA GRAFICA ---
echo [8/10] Obteniendo info de GPU...
echo ======================================================== >> "%OUTFILE%"
echo               TARJETA GRAFICA >> "%OUTFILE%"
echo ======================================================== >> "%OUTFILE%"
powershell -NoProfile -Command "Get-CimInstance Win32_VideoController | Select-Object Name, DriverVersion, @{N='DriverDate';E={$_.DriverDate}}, CurrentHorizontalResolution, CurrentVerticalResolution, @{N='VRAM_GB';E={[math]::Round($_.AdapterRAM/1GB,2)}} | Format-List | Out-String" >> "%OUTFILE%"

REM --- 9. RED E INTERNET ---
echo [9/10] Obteniendo configuracion de Red...
echo. >> "%OUTFILE%"
echo ======================================================== >> "%OUTFILE%"
echo               RED Y COMUNICACIONES >> "%OUTFILE%"
echo ======================================================== >> "%OUTFILE%"
ipconfig /all >> "%OUTFILE%"

REM --- 10. USUARIOS ---
echo ======================================================== >> "%OUTFILE%"
echo               USUARIOS LOCALES >> "%OUTFILE%"
echo ======================================================== >> "%OUTFILE%"
net user >> "%OUTFILE%"
echo. >> "%OUTFILE%"
echo --- Administradores --- >> "%OUTFILE%"
net localgroup Administradores >> "%OUTFILE%"

REM --- 11. SOFTWARE ---
echo [10/10] Listando programas instalados...
echo. >> "%OUTFILE%"
echo ======================================================== >> "%OUTFILE%"
echo               SOFTWARE INSTALADO >> "%OUTFILE%"
echo ======================================================== >> "%OUTFILE%"
echo (Generado via PowerShell Registry) >> "%OUTFILE%"
powershell -NoProfile -Command "Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*, HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object { $_.DisplayName -ne $null } | Select-Object DisplayName, DisplayVersion, Publisher, InstallDate | Sort-Object DisplayName | Format-Table -AutoSize | Out-String -Width 4096" >> "%OUTFILE%"

REM --- 12. RESUMEN EJECUTIVO PARA ML ---
echo. >> "%OUTFILE%"
echo ======================================================== >> "%OUTFILE%"
echo               RESUMEN PARA ANALISIS PREDICTIVO >> "%OUTFILE%"
echo ======================================================== >> "%OUTFILE%"
echo (Datos estructurados para importar a modelo ML) >> "%OUTFILE%"
echo. >> "%OUTFILE%"

powershell -NoProfile -Command "$summary = [ordered]@{}; $summary['EQUIPO'] = $env:COMPUTERNAME; $summary['FECHA_REPORTE'] = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'; $os = Get-CimInstance Win32_OperatingSystem; $summary['DIAS_INSTALACION'] = [math]::Round(((Get-Date) - $os.InstallDate).TotalDays); $summary['UPTIME_DIAS'] = [math]::Round(((Get-Date) - $os.LastBootUpTime).TotalDays, 2); $cpu = Get-CimInstance Win32_Processor; $summary['CPU_CORES'] = $cpu.NumberOfCores; $summary['CPU_GEN'] = if($cpu.Name -match 'i[3579]-(\d+)') { $matches[1].Substring(0,2) } else { 'N/A' }; $ram = Get-CimInstance Win32_PhysicalMemory; $summary['RAM_TOTAL_GB'] = [math]::Round(($ram | Measure-Object -Property Capacity -Sum).Sum/1GB, 2); $summary['RAM_SLOTS'] = $ram.Count; $summary['RAM_MIXED_SPEED'] = if(($ram | Select-Object -Unique Speed).Count -gt 1) { 1 } else { 0 }; $summary['RAM_MIXED_VENDOR'] = if(($ram | Select-Object -Unique Manufacturer).Count -gt 1) { 1 } else { 0 }; $disk = Get-CimInstance Win32_LogicalDisk -Filter \"DeviceID='C:'\"; $summary['DISCO_C_USADO_PCT'] = [math]::Round((($disk.Size - $disk.FreeSpace)/$disk.Size)*100, 1); $startDate = (Get-Date).AddDays(-30); $summary['BSOD_30D'] = (Get-WinEvent -FilterHashtable @{LogName='System'; Id=41; StartTime=$startDate} -ErrorAction SilentlyContinue | Measure-Object).Count; $summary['DISK_ERRORS_30D'] = (Get-WinEvent -FilterHashtable @{LogName='System'; Id=7,9,11,15,55; StartTime=$startDate} -ErrorAction SilentlyContinue | Measure-Object).Count; $summary['APP_CRASHES_30D'] = (Get-WinEvent -FilterHashtable @{LogName='Application'; Id=1000,1001,1002; StartTime=$startDate} -ErrorAction SilentlyContinue | Measure-Object).Count; $summary['CRITICAL_EVENTS_30D'] = (Get-WinEvent -FilterHashtable @{LogName='System'; Level=1; StartTime=$startDate} -ErrorAction SilentlyContinue | Measure-Object).Count; $summary['SYSTEM_ERRORS_30D'] = (Get-WinEvent -FilterHashtable @{LogName='System'; Level=2; StartTime=$startDate} -ErrorAction SilentlyContinue | Measure-Object).Count; $lastUpdate = (Get-HotFix | Sort-Object InstalledOn -Descending -ErrorAction SilentlyContinue | Select-Object -First 1).InstalledOn; $summary['DIAS_SIN_UPDATE'] = if($lastUpdate) { [math]::Round(((Get-Date) - $lastUpdate).TotalDays) } else { -1 }; try { $health = Get-PhysicalDisk | Select-Object -First 1; $summary['DISK_HEALTH'] = $health.HealthStatus; $reliability = $health | Get-StorageReliabilityCounter -ErrorAction Stop; $summary['DISK_POWER_ON_HOURS'] = $reliability.PowerOnHours; $summary['DISK_TEMPERATURE'] = $reliability.Temperature; $summary['DISK_WEAR'] = $reliability.Wear } catch { $summary['DISK_HEALTH'] = 'N/A'; $summary['DISK_POWER_ON_HOURS'] = -1; $summary['DISK_TEMPERATURE'] = -1; $summary['DISK_WEAR'] = -1 }; Write-Output '--- DATOS CSV (copiar a Excel) ---'; $header = ($summary.Keys -join ','); $values = ($summary.Values -join ','); Write-Output $header; Write-Output $values; Write-Output ''; Write-Output '--- DATOS DETALLADOS ---'; foreach($key in $summary.Keys) { Write-Output \"$key = $($summary[$key])\" }" >> "%OUTFILE%"

REM --- FINALIZAR ---
echo.
echo ========================================================
echo   REPORTE PREDICTIVO COMPLETADO EXITOSAMENTE
echo ========================================================
echo.
echo Archivo guardado: %OUTFILE%
echo.
echo NUEVOS DATOS INCLUIDOS:
echo   - Datos SMART de discos
echo   - Eventos criticos (BSOD, errores disco, crashes)
echo   - Metricas de salud del sistema
echo   - Resumen CSV para importar a ML
echo.
pause
