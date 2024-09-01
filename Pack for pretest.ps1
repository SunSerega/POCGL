try {
	
	
	
	function Get-RepoChoise {
		while ($true) {
			$choice = Read-Host 'Repo ("CL"/"GL")'
			if ($choice -eq 'CL') {
				return 'OpenCL-Docs'
			}
			if ($choice -eq 'GL') {
				return 'OpenGL-Registry'
			}
			Write-Host 'Invalid input'
		}
	}
	
	function Get-PRNum {
		while ($true) {
			$choice = Read-Host 'PR num'
			if ($choice -match '^\d+$') {
				return $choice
			}
			Write-Host 'Invalid input'
		}
	}
	
	$repo = Get-RepoChoise
	$pr_num = Get-PRNum
	
	while ($true) {
		& '.\PackAll-1 PullUpstream + Pack.bat' "PullUpstreamBranch=${repo}:pretest/${pr_num}"
		
		while ($true) {
			$choice = Read-Host '(e)xit / (r)epeat'
			if ($choice -eq 'e') {
				exit 0
			}
			if ($choice -eq 'r') {
				break
			}
			Write-Host 'Invalid input'
		}
		
	}
	
	
	
}
catch {
	Write-Host "An error occurred:"
	Write-Host $_
	pause
	exit 1
}