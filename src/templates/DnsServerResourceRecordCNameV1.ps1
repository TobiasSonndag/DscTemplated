Configuration DnsServerResourceRecordCNameV1
{
    param (
        [string]$NodeName,
        [string]$Name,
        [string]$OtherNode = $NodeName,
        [string]$Domain,
        [string]$Ensure,
        [int]$EstimatedTimeSaved = 1,
        [ValidateSet('isDomainControllerMainNode')]
        [string]$runOnOtherNode,
        [string]$HostNameAlias = $OtherNode
    )

    # Import the module that contains the File resource.
    Import-DscResource -Module PsDesiredStateConfiguration

    Node $NodeName
    {
        switch ($runOnOtherNode) {
            'isDomainControllerMainNode' {
                # Code for domain controller main node
                Script $Name { # Custom Script resource to create or remove a CNAME record as there is a bug in the DnsServerDsc module in PowerShell 7 https://github.com/dsccommunity/DnsServerDsc/issues/268
                    GetScript = {
                            $Result = $(Get-DnsServerResourceRecord -ZoneName $using:Domain -Name $using:Name -ErrorAction SilentlyContinue)
                            return $Result
                    }
                    TestScript = {
                        $record = $(Get-DnsServerResourceRecord -ZoneName $using:Domain -Name $using:Name -ErrorAction SilentlyContinue)
                        if ($using:Ensure -eq 'Present') {
                            return $($record -and $record.RecordType -eq 'CName' -and $record.RecordData.HostNameAlias -eq "$using:HostNameAlias.")
                        } elseif ($using:Ensure -eq 'Absent') {
                            return $(-not $record)
                        } else {
                            throw "Invalid value for Ensure: $using:Ensure. Use 'Present' or 'Absent'."
                        }
                    }
                    SetScript = {
                        if ($using:Ensure -eq 'Present') {
                            Add-DnsServerResourceRecordCName -ZoneName $using:Domain -Name $using:Name -HostNameAlias $using:HostNameAlias
                        } elseif ($using:Ensure -eq 'Absent') {
                            Remove-DnsServerResourceRecord -ZoneName $using:Domain -Name $using:Name -RRType CName -Force
                        } else {
                            throw "Invalid value for Ensure: $using:Ensure. Use 'Present' or 'Absent'."
                        }
                    }
                }
            }
            Default {
                # Code for actual node
                # Not needed here
            }
        }
    }
}