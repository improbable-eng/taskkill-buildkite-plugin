# A script to kill processes that have files open in the current working directory (recursively)
#
# It does this by using [handle](https://docs.microsoft.com/en-us/sysinternals/downloads/handle)
# to find all processes of a particular name which have file locks on our build (project) directory.
# We can then attempt to kill each of these processes if any exist.
#
# The expected usage is as follows:
#   powershell -NoProfile -NonInteractive purge.ps1 -Dir C:\my-directory
param(
  [String] $Dir = $(pwd).Path,
  [String[]] $Whitelist = ('explorer.exe', 'handle64.exe')
)

pslist -t -accepteula -nobanner

if (Test-Path -Path $Dir) {
	$absDir = Resolve-Path $Dir -ErrorAction Stop
} else {
	Write-Output "Skipping: Directory $($Dir) does not exist, no file-handles can exist."
	exit 0
}
Write-Output "Finding handles in $absDir"
$OUT=$(handle64 -accepteula -nobanner $absDir)

$processMap = @{}
ForEach ($line in $OUT -split "`r`n")
{
	$Result = $([regex]::Match("$line", "(.*?)\s+pid: (.*) type"))
	if ($Result.Success)
	{
		$image = $Result.Groups[1].Value
		$ppid = $Result.Groups[2].Value
		$processMap.$ppid = $image
	}
}

if ($processMap.Count -eq 0)
{
    Write-Output "No handles found."
}
else
{
	$processMap | Format-Table

	Write-Output "Whitelisted: $Whitelist"
	foreach($ppid in $processMap.keys)
	{
		$imageName = $processMap.$ppid
		if (! $Whitelist.Contains($imageName)){
			Write-Output "Killing $ppid"
			taskkill /f /t /pid $ppid
		}
	}
}
