Configuration DSC {

    param (
        [string]$Environment,
        [string]$EnvironmentPath,
        [string]$TemplatePath,
        [string]$Path
    )

    # Import the module that contains the File resource.
    Import-DscResource -Module PsDesiredStateConfiguration
    Import-DscResource -Module ActiveDirectoryDsc
    Import-DscResource -Module SqlServerDsc

    # dot source Test-ValidateSetValue function
    . $Path\pipelines\scripts\Test-ValidateSetValue.ps1
    
    Node $ConfigurationData.AllNodes.NodeName {
        
        # iterate through each object on the node to be created using a template
        foreach ($Object in $Node.PSObject.Properties.Value.Where({$_.Template})) {
            foreach ($Item in $Object) {
                . $TemplatePath\$($Item.Template).ps1
                
                # Clone the object to remove the template property for parameter splat
                $parameters = $Item.Clone()
                $parameters.Remove('Template')

                # Checking if config file exists for the template and execute it
                if (Test-Path "$EnvironmentPath\TemplateConfig\$(($item.Template) + "Config").ps1") {
                    Write-Host "Processing on $($Node.NodeName) : $($item.Template)Config"
                    $parameters = . "$EnvironmentPath\TemplateConfig\$(($item.Template) + "Config").ps1" -NodeName $Node.NodeName -Domain $Node.Domain @parameters
                }

                Write-Host "Processing on $($Node.NodeName) : $($item.Template)"
                . $($Item.Template) -NodeName $Node.NodeName -Domain $Node.Domain @parameters
            }
        }

        # if node should also run configuration from other nodes, iterate through each object of other nodes to be created using a template that has parameter runOnOtherNode set
        # done directly on node to avoid using credentials in the configuration data
        # Allows for cross node configurations and still using a single template
        If ($Node.runOnOtherNode) {

            # iterate through all nodes to find nodes that use templates (Using $Global: as it becomes unavailable in the foreach loop)
            foreach ($OtherNode in $Global:ConfigurationData.AllNodes.Where({$_.PSObject.Properties.Value.Where({$_.Template})})) {
                
                # iterate through each object on the other node that uses a template and is in the same domain
                foreach ($Object in $OtherNode.PSObject.Properties.Value.Where({$_.Template -and $OtherNode.Domain -eq $Node.Domain})) {
                    # Set variables for next foreach
                    $ActualNodeName = $Node.NodeName
                    $OtherNodeName = $OtherNode.NodeName

                    # iterate through each item in the object that has runOnOtherNode set to a value that matches $Node.runOnOtherNode
                    foreach ($item in $Object.Where({Test-ValidateSetValue -ScriptPath "$TemplatePath\$($_.Template).ps1" -ParameterName "runOnOtherNode" -ValidateSetValue $Node.runOnOtherNode})) {
                        
                        # dot source the template
                        . $TemplatePath\$($Item.Template).ps1
                        
                        #Clone the item object to remove the template property for parameter splat, adding .OtherNode
                        $parameters = $item.Clone()
                        $parameters.Remove('Template')
                        $parameters.OtherNode = $OtherNodeName

                        # Checking if config file exists for the template and execute it
                        if (Test-Path "$EnvironmentPath\TemplateConfig\$(($item.Template) + "Config").ps1") {
                            Write-Host "Processing on $($Node.NodeName) : $($item.Template)Config"
                            $parameters = . "$EnvironmentPath\TemplateConfig\$(($item.Template) + "Config").ps1" -NodeName $Node.NodeName -Domain $Node.Domain @parameters
                        }
                        
                        #run the template with the parameter splat
                        Write-Host "Processing on $ActualNodeName from other node $OtherNodeName : $($item.Template)"
                        . $($item.Template) -NodeName $ActualNodeName -Domain $Node.Domain @parameters -runOnOtherNode $Node.runOnOtherNode
                    }
                }
            }
        }

        # if special config file in NodeConfigs exists for this node, run it. Allows for one-of configs to be run on a node that need no template
        if (Test-Path "$EnvironmentPath\NodeConfigs\$($Node.NodeName).ps1") {
            . $EnvironmentPath\NodeConfigs\$($Node.NodeName).ps1
            Write-Host "Processing on $($Node.NodeName) : SpecialConfig"
            . SpecialConfig -NodeName $Node.NodeName
        }
    }
}