param (
    [string]$resourcePath = "$PSScriptRoot\temp\",
    [string]$Environment = 'Examples', 
    [string]$zipFolderPath = "$PSScriptRoot\$Environment\DSC\Resources",
    [string[]]$Modules = @(
        'PsDesiredStateConfiguration',
        'SqlServerDsc',
        'ActiveDirectoryDsc',
        'DnsServerDsc'
    )
)

# Ensure the resource path and zip folder path exist
if (-Not (Test-Path -Path $resourcePath)) {
    New-Item -Path $resourcePath -ItemType Directory
}
if (-Not (Test-Path -Path $zipFolderPath)) {
    New-Item -Path $zipFolderPath -ItemType Directory
}

foreach ($Module in $Modules) {
    try {
        Get-InstalledModule -Name $Module -ErrorAction Stop
    } catch {
        Write-Output "Installing $Module"
        Install-Module -Name $Module -Force -Repository PSGallery
    }
    if (-Not ($Module -eq 'PsDesiredStateConfiguration')) {
        # Save the module
        Save-Module -Name $Module -Path $resourcePath -Repository PSGallery -Force

        # Get the module version
        $moduleVersion = $(Get-InstalledModule -Name $Module | Sort-Object Version -Descending | Select-Object -First 1).Version.ToString()

        # Define paths
        $moduleSourcePath = Join-Path -Path $resourcePath -ChildPath $Module
        $moduleVersionPath = Join-Path -Path $moduleSourcePath -ChildPath $moduleVersion
        $dscResourcePath = Join-Path -Path $moduleSourcePath -ChildPath "DscResources"
        $zipFilePath = Join-Path -Path $zipFolderPath -ChildPath "${Module}_${moduleVersion}.zip"

        # Remove the version folder and restructure
            Move-Item -Path (Join-Path -Path $moduleVersionPath -ChildPath "DscResources") -Destination $dscResourcePath
        
        Remove-Item -Path $moduleVersionPath -Recurse -Force

        # Compress the module into a zip file
        if (Test-Path -Path $zipFilePath) {
            Remove-Item -Path $zipFilePath -Force
        }
        Compress-Archive -Path "$moduleSourcePath\*" -DestinationPath $zipFilePath

        Write-Output "Packaged $Module version $moduleVersion into $zipFilePath"
    }
}

# Delete temp
if (Test-Path -Path $resourcePath) {
    Remove-Item -Path $resourcePath -Recurse -Force
}

Write-Output "All DSC resources have been downloaded, restructured, and zipped."
