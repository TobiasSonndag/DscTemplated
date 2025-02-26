# Return true an first: if the specified parameter has any of the specified values in validateset in the specified script
function Test-ValidateSetValue {
    param (
        [string]$ScriptPath,
        [string]$ParameterName = "runOnOtherNode",
        [string[]]$ValidateSetValue = @("isDomainControllerMainNode","isServerSccmMainNode")
    )
    
    if (-not (Test-Path -Path $ScriptPath)) {
        Write-Host "Script not found: $ScriptPath"
        return $false
    }

    # Read the script content
    $scriptContent = Get-Content -Path $ScriptPath -Raw

    # Parse the script content into an AST
    $scriptAst = [System.Management.Automation.Language.Parser]::ParseInput($scriptContent, [ref]$null, [ref]$null)

    # Find the parameter definitions in the AST
    $paramBlocks = $scriptAst.FindAll({ $args[0] -is [System.Management.Automation.Language.ParameterAst] }, $true)

    # return true on first find
    foreach ($paramBlock in $paramBlocks.Where({ $_.Name.VariablePath.UserPath -eq $ParameterName })) {
        foreach ($item in $validateSetValue.Where({ $paramBlock.Attributes.PositionalArguments.Value -contains $_ })) {
            return $true
        }
    }
    return $false
}