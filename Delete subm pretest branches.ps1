try {
	
	function Delete-Branches {
		param (
			[string]$folder,
			[string]$remote,
			[string]$pattern
		)
		
		Push-Location $folder
		
		git fetch $remote
		
		$branch_del = @()
		foreach ($branch in git branch -r --list "$remote/$pattern") {
			$branch = $branch.Trim().SubString($remote.Length+1)
			if ($branch.EndsWith('960')) { continue }
			if ($branch.EndsWith('962')) { continue }
			if ($branch.EndsWith('1159')) { continue }
			if ($branch.EndsWith('1215')) { continue }
			if ($branch.EndsWith('1223')) { continue }
			Write-Host "Deleting branch: $branch"
			$branch_del += $branch
		}
		git push $remote --delete $branch_del
		
		Pop-Location
	}
	
	
	
	Delete-Branches '.\DataScraping\Reps\OpenCL-Docs\' 'SunSerega' 'pretest/*'
	Delete-Branches '.\DataScraping\Reps\OpenGL-Registry\' 'SunSerega' 'pretest/*'
	Delete-Branches '.' 'origin' 'subm-pretest/*'
	
	
	
}
catch {
	Write-Host "An error occurred:"
	Write-Host $_
	#pause
	exit 1
}
pause