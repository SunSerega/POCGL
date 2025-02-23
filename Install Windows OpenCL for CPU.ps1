


param ($temp_dir)

if ($temp_dir -eq $null) {
	throw "Temp dir not specified"
}

$igfx = Join-Path $temp_dir 'igfx'

# https://www.intel.com/content/www/us/en/developer/articles/technical/intel-cpu-runtime-for-opencl-applications-with-sycl-support.html
Invoke-WebRequest -Uri 'https://registrationcenter-download.intel.com/akdlm/IRC_NAS/d9883ab0-0e26-47fd-9612-950b95460d72/w_opencl_runtime_p_2024.2.0.980.exe' -OutFile '$igfx.exe'

7z x "$igfx.exe" -o"$igfx" -y

& "$igfx\w_opencl_runtime_p_2024.1.0.968.msi" /quiet


