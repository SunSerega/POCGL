


param ($temp_dir)

if ($temp_dir -eq $null) {
	throw "Temp dir not specified"
}

# https://www.intel.com/content/www/us/en/developer/articles/technical/intel-cpu-runtime-for-opencl-applications-with-sycl-support.html
# TODO newer version doesn't detect (AMD?) CPUs anymore...
$url = 'https://registrationcenter-download.intel.com/akdlm/IRC_NAS/0e6849e6-2c56-480b-afcf-be8331d5c4f6-opencl/w_opencl_runtime_p_2024.1.0.968.exe'
$driver_file_name = [IO.Path]::GetFileNameWithoutExtension($url)
Write-Host "driver_file_name = $driver_file_name"

$igfx = Join-Path $temp_dir 'igfx'
Write-Host "igfx = $igfx"
$igfx_exe = "${igfx}.exe"
Write-Host "igfx_exe = $igfx_exe"
$igfx_log = "${igfx}.install.log"
Write-Host "igfx_log = $igfx_log"
$igfx_msi = "${igfx}\${driver_file_name}.msi"
Write-Host "igfx_msi = $igfx_msi"

Write-Host "Downloading installer wrap"
Invoke-WebRequest -Uri $url -OutFile $igfx_exe

Write-Host "Running 7z to unpack the wrap"
7z x $igfx_exe -o"$igfx" -y

Write-Host "Checking .msi exists:" (Test-Path -PathType Leaf $igfx_msi)

Write-Host "Running .msi"
# Running .msi file directly doesn't create a log file, but this somehow does
$result = Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$igfx_msi`" /quiet /l*v `"$igfx_log`"" -Wait -PassThru
write-host "ExitCode from msiexec:" ($result.ExitCode)

if ([IO.File]::Exists($igfx_log)) {
	Write-Host "MSI Log:"
	Get-Content $igfx_log
} else {
	Write-Host "MSI Log file wasn't created"
}


