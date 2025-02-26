# Logging to SQL database for MuggleMagicMetrics
#region ############# Parameters and variable initialization ############################## #BOOKMARK: Script Parameters

function Write-PowerShellDscUsageLog {
    [CmdletBinding()]
    Param (
        [Parameter()][string]$SqlConnectionString = "Server=db-InfraMgmtDb;Database=InfraMgmtDb;Integrated Security=True;Connect Timeout=60",
        [Parameter()][string]$Environment,
        [Parameter()][string]$TemplatePath
    )
    #endregion ########## Parameters and variable initialization ###########################################################

    #Iterate through each node
    foreach ($Node in $ConfigurationData.AllNodes) {
        # Iterate through each object on the node to be created using a template
        foreach ($Object in $Node.PSObject.Properties.Value.Where({ $_.Template })) {
            foreach ($Item in $Object) {
                # Output processing message
                Write-Host "Processing on $($Node.NodeName) : $($Item.Template)"

                # Insert the parameters into the SQL database
                
                $minuteCounter = Get-ParameterDefaultValue -ScriptPath "$TemplatePath\$($item.Template).ps1" -ParameterName 'EstimatedTimeSaved'
                try {
                    Write-Output "Writing to SQL Database InfraMgmtDb"
                    
                    # Create and open SQL connection
                    $conn = New-Object System.Data.SqlClient.SQLConnection
                    $conn.ConnectionString = $sqlConnectionString
                    $conn.Open()
                    
                    # Define the SQL query with conditional insert
                    $query = @"
IF NOT EXISTS (
    SELECT 1
    FROM [Write-PowerShellDscUsageLog]
    WHERE Name = '$($Item.Name)'
        AND Template = '$($Item.Template -replace "V\d+$", "")'
        AND Ensure = '$($Item.Ensure)'
        AND NodeName = '$($Node.NodeName)'
)
BEGIN
    INSERT INTO [Write-PowerShellDscUsageLog] (Name, Template, Ensure, NodeName, EstimatedTimeSaved, Date)
    VALUES ('$($Item.Name)', '$($Item.Template -replace "V\d+$", "")', '$($Item.Ensure)', '$($Node.NodeName)', $minuteCounter, GETDATE());
END
"@

                    # Create and execute SQL command
                    $command = [System.Data.SqlClient.SqlCommand]::new($query, $conn)
                    $command.ExecuteNonQuery()
                    
                    # Close the connection
                    $conn.Close()
                    
                    Write-Output "Wrote to SQL Database InfraMgmtDb"
                }
                catch {
                    Write-Output "WARNING: Could not write to SQL Database InfraMgmtDb $($Error[0].Exception.Message)"
                }

            }
        }
    }

}