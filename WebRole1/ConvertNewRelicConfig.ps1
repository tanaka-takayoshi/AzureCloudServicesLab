param(
    [string]$OriginalPath,
    [string]$SavePath,
    [string]$NRLicenseKey,
    [string]$NRAppName,
    [string]$NREnabled = "true"
)

[xml]$x = Get-Content $OriginalPath -Encoding UTF8
$x.configuration.application.name=$NRAppName
$x.configuration.service.SetAttribute("licenseKey", $NRLicenseKey)
$x.configuration.SetAttribute("agentEnabled", $NREnabled)
$x.Save($SavePath)