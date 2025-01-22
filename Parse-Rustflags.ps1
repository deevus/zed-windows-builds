$rustflags = $args

if ($rustflags.Length -eq 0) {
	Write-Host "No rustflags provided"
	exit 0
}

$config_path = ".cargo/config.toml"

New-Item -Path $config_path -Force | Out-Null

"[target.'cfg(all())']" | Out-File -FilePath $config_path -Append | Out-Null

"rustflags = [" | Out-File -FilePath $config_path -Append -NoNewLine | Out-Null
foreach ($flag in $rustflags) {
	$line = """${flag}"", "
	$line | Out-File -FilePath $config_path -Append -NoNewLine | Out-Null
}
"]" | Out-File -FilePath $config_path -Append | Out-Null
