param (
    [string]$Environment = 'prod',                                      # Environment to build (Examples, Production, etc)
    [string]$EnvironmentPath = "$PSScriptRoot\src\env\$Environment",    # Environment path 
    [string]$TemplatePath = "$PSScriptRoot\src\templates",              # Templates path 
    [string]$OutputPath = "$EnvironmentPath\DSC",                       # Output path for MOF files
    $ErrorActionPreference = 'Stop'                                     # Set global error action
)

# Import all helper functions from the HelperFunctions directory
Get-ChildItem -Path "$PSScriptRoot\pipelines\scripts\*.ps1" | ForEach-Object { . $_.FullName }

# Delete Pre-existing MOFS in our DSC base folder
Get-ChildItem $OutputPath -Recurse -Include '*.mof', '*.mof.error', '*.mof.checksum' | Remove-Item -Force

# Build Configuration Data and MOF files
Write-Output "$EnvironmentPath\Nodes"
$ConfigurationData = New-ConfigurationData -Environment $Environment -Path "$EnvironmentPath\Nodes"
. DSC -Path $PSScriptRoot -Environment $Environment -EnvironmentPath $EnvironmentPath -TemplatePath $TemplatePath -ConfigurationData $ConfigurationData -OutputPath $OutputPath

# Rename MOF files to ConfigurationID for SMB Pull Server (Mandatory)
foreach ($Node in $ConfigurationData.AllNodes.Where({$_.ConfigurationID})) {
        $source = "$OutputPath\$($Node.NodeName).mof"
        $dest = "$OutputPath\$($Node.ConfigurationID).mof"
        if (Test-Path $source) {
            Move-Item -Path $source -Destination $dest -Force
            New-DSCCheckSum $dest -Force
        }
}

# Log PowerShell DSC Usage if environment is prod
if ($Environment -eq 'prod') {
    Write-PowerShellDscUsageLog -Environment $Environment -TemplatePath $TemplatePath
}