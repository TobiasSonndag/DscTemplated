param (
    [string]$resourcePath = "$PSScriptRoot\temp\",
    [string]$Environment = 'prod', 
    [string]$zipFolderPath = "$PSScriptRoot\src\env\$Environment\DSC\Resources",
    [string[]]$Modules = @(
        'PsDesiredStateConfiguration',
        'SqlServerDsc',
        'ActiveDirectoryDsc',
        'DnsServerDsc'
    )
)

# Delete temp if existing
if (Test-Path -Path $resourcePath) {
    Remove-Item -Path $resourcePath -Recurse -Force
}

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
        # Setting up SMB Pull Server artifacts according to https://learn.microsoft.com/en-us/powershell/dsc/pull-server/pullserversmb?view=dsc-1.1#placing-configurations-and-resources
        
        # Save the module
        Save-Module -Name $Module -Path $resourcePath -Repository PSGallery -Force

        # Get the module version
        $moduleVersion = $(Get-InstalledModule -Name $Module | Sort-Object Version -Descending | Select-Object -First 1).Version.ToString()

        # Define paths
        $moduleSourcePath = Join-Path -Path $resourcePath -ChildPath $Module
        $moduleVersionPath = Join-Path -Path $moduleSourcePath -ChildPath $moduleVersion
        $zipFilePath = Join-Path -Path $zipFolderPath -ChildPath "${Module}_${moduleVersion}.zip"

        # Remove the version folder and restructure
        #Move-Item -Path (Join-Path -Path $moduleVersionPath -ChildPath "DscResources") -Destination $dscResourcePath
        Get-ChildItem -Path $moduleVersionPath -Recurse -Force | Move-Item -Destination $moduleSourcePath -Force

        Remove-Item -Path $moduleVersionPath -Force

        # Compress the module into a zip file
        if (Test-Path -Path $zipFilePath) {
            Remove-Item -Path $zipFilePath -Force
        }
        # Compress-Archive -Path "$moduleSourcePath\*" -DestinationPath $zipFilePath #Does not include hidden .xml file - fix ongoing https://github.com/PowerShell/Microsoft.PowerShell.Archive/issues/66
        # Workaround: Use .NET ZipFile class https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.archive/compress-archive?view=powershell-7.4#description
        [System.IO.Compression.ZipFile]::CreateFromDirectory($moduleSourcePath, $zipFilePath, [System.IO.Compression.CompressionLevel]::Optimal, $false)
        # Create a checksum file as it is required by the SMB Pull Server
        New-DSCCheckSum $zipFilePath -Force

        Write-Output "Packaged $Module version $moduleVersion into $zipFilePath"
    }
}

# Delete temp
if (Test-Path -Path $resourcePath) {
    Remove-Item -Path $resourcePath -Recurse -Force
}

Write-Output "All DSC resources have been downloaded, restructured, and zipped."