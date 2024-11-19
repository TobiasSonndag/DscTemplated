Configuration DSC {

    param (
        [string]$Environment
    )

    # Import the module that contains the File resource.
    Import-DscResource -Module PsDesiredStateConfiguration
    Import-DscResource -Module ActiveDirectoryDsc
    Import-DscResource -Module SqlServerDsc
    
    Node $ConfigurationData.AllNodes.NodeName {
        
        #iterate through each object on the node to be created using a template
        Write-Host "Node: $($Node.NodeName)"
        foreach ($Object in $Node.PSObject.Properties.Value.Where({$_.Template})) {
            foreach ($Item in $Object) {
                . $PSScriptRoot\$Environment\Templates\$($Item.Template).ps1
                #Clone the object to remove the template property for parameter splat
                $parameters = $Item.Clone()
                $parameters.Remove('Template')
                . $($Item.Template) -NodeName $Node.NodeName -Domain $Node.Domain @parameters
            }
        }

        #Create Active Directory Groups for all databases
        #Done directly on the domain controller to avoid using credentials
        If ($Node.isMainDomainController) {
            foreach ($DatabaseHost in $ConfigurationData.AllNodes.Where({$_.Databases})) {
                foreach ($Database in $DatabaseHost.Databases.Where({$DatabaseHost.Domain -eq $Node.Domain})) {
                    . $PSScriptRoot\$Environment\Templates\$($Database.Template).ps1
                    . $($Database.Template) -NodeName $Node.NodeName -Domain $Node.Domain -Name $Database.Name -DatabaseNodeName $DatabaseHost.NodeName  -Ensure $Database.Ensure
                }
            }
        }

        #run special config in NodeConfigs. Allows for one of configs to be run on a node that need no template
        if (Test-Path "$PSScriptRoot\$Environment\NodeConfigs\$($Node.NodeName).ps1") {
            . $PSScriptRoot\$Environment\NodeConfigs\$($Node.NodeName).ps1
            . SpecialConfig -NodeName $Node.NodeName
        }
    }
}