Configuration DatabaseTemplateV7
{
    param (
        [string]$NodeName,
        [string]$Name,
        [string]$OtherNode = $NodeName,
        [string]$Domain,
        [string]$Ensure,
        [int]$EstimatedTimeSaved = 15,
        [ValidateSet('isDomainControllerMainNode','')]
        [string]$runOnOtherNode,
        [string]$DatabaseHost,
        [string]$OuPath,
        [string]$SqlLoginDomainName,
        [string]$AdGroupPrefix
    )

    # Import the module that contains the File resource.
    Import-DscResource -Module PsDesiredStateConfiguration
    Import-DscResource -Module ActiveDirectoryDsc
    Import-DscResource -Module SqlServerDsc

    Node $NodeName
    {
        switch ($runOnOtherNode) {
            'isDomainControllerMainNode' {
                # Code for domain controller main node
                ADGroup "${AdGroupPrefix}Read" {
                    GroupName        = "${AdGroupPrefix}Read"
                    Description      = "Read access to $Name on $DatabaseHost"
                    Ensure           = $Ensure
                    GroupScope       = 'DomainLocal'
                    Category         = 'Security'
                    Path             = $OuPath
                }
                ADGroup "${AdGroupPrefix}RW" {
                    GroupName        = "${AdGroupPrefix}RW"
                    Description      = "Read / Write access to $Name on $DatabaseHost"
                    Ensure           = $Ensure
                    GroupScope       = 'DomainLocal'
                    Category         = 'Security'
                    Path             = $OuPath
                }
                ADGroup "${AdGroupPrefix}DBO" {
                    GroupName        = "${AdGroupPrefix}DBO"
                    Description      = "DBO access to $Name on $DatabaseHost"
                    Ensure           = $Ensure
                    GroupScope       = 'DomainLocal'
                    Category         = 'Security'
                    Path             = $OuPath
                }
                Script "db-${Name}" { # Custom Script resource to create or remove a CNAME record as there is a bug in the DnsServerDsc module in PowerShell 7 https://github.com/dsccommunity/DnsServerDsc/issues/268
                    GetScript = {
                            $Result = $(Get-DnsServerResourceRecord -ZoneName $using:Domain -Name $using:Name -ErrorAction SilentlyContinue)
                            return $Result
                    }
                    TestScript = {
                        $record = $(Get-DnsServerResourceRecord -ZoneName $using:Domain -Name $using:Name -ErrorAction SilentlyContinue)
                        if ($using:Ensure -eq 'Present') {
                            return $($record -and $record.RecordType -eq 'CName' -and $record.RecordData.HostNameAlias -eq "$using:DatabaseHost.")
                        } elseif ($using:Ensure -eq 'Absent') {
                            return $(-not $record)
                        } else {
                            throw "Invalid value for Ensure: $using:Ensure. Use 'Present' or 'Absent'."
                        }
                    }
                    SetScript = {
                        if ($using:Ensure -eq 'Present') {
                            Add-DnsServerResourceRecordCName -ZoneName $using:Domain -Name $using:Name -HostNameAlias $using:DatabaseHost
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
                SQLDatabase $Name {
                    Ensure       = $Ensure
                    Name         = $Name
                    InstanceName = 'MSSQLSERVER'
                    OwnerName    = 'sa'
                }        
                SqlLogin "${AdGroupPrefix}Read"
                {
                    Ensure               = $Ensure
                    Name                 = "$SqlLoginDomainName\${AdGroupPrefix}Read"
                    LoginType            = 'WindowsGroup'
                    InstanceName         = 'MSSQLSERVER'
                }
                SqlLogin "${AdGroupPrefix}RW"
                {
                    Ensure               = $Ensure
                    Name                 = "$SqlLoginDomainName\${AdGroupPrefix}RW"
                    LoginType            = 'WindowsGroup'
                    InstanceName         = 'MSSQLSERVER'
                }
                SqlLogin "${AdGroupPrefix}DBO"
                {
                    Ensure               = $Ensure
                    Name                 = "$SqlLoginDomainName\${AdGroupPrefix}DBO"
                    LoginType            = 'WindowsGroup'
                    InstanceName         = 'MSSQLSERVER'
                }
                SqlDatabaseUser "${AdGroupPrefix}Read"
                {
                    Ensure               = $Ensure
                    Name                 = "$SqlLoginDomainName\${AdGroupPrefix}Read"
                    LoginName            = "$SqlLoginDomainName\${AdGroupPrefix}Read"
                    DatabaseName         = $Name
                    InstanceName         = 'MSSQLSERVER'
                    DependsOn            = "[SqlLogin]${AdGroupPrefix}Read", "[SQLDatabase]$Name"
                    UserType             = 'Login'
                }
                SqlDatabaseUser "${AdGroupPrefix}RW"
                {
                    Ensure               = $Ensure
                    Name                 = "$SqlLoginDomainName\${AdGroupPrefix}RW"
                    LoginName            = "$SqlLoginDomainName\${AdGroupPrefix}RW"
                    DatabaseName         = $Name
                    InstanceName         = 'MSSQLSERVER'
                    DependsOn            = "[SqlLogin]${AdGroupPrefix}RW", "[SQLDatabase]$Name"
                    UserType             = 'Login'
                }
                SqlDatabaseUser "${AdGroupPrefix}DBO"
                {
                    Ensure               = $Ensure
                    Name                 = "$SqlLoginDomainName\${AdGroupPrefix}DBO"
                    LoginName            = "$SqlLoginDomainName\${AdGroupPrefix}DBO"
                    DatabaseName         = $Name
                    InstanceName         = 'MSSQLSERVER'
                    DependsOn            = "[SqlLogin]${AdGroupPrefix}DBO", "[SQLDatabase]$Name"
                    UserType             = 'Login'
                }
                SqlDatabaseRole "db_datareader_${Name}"
                {
                    Ensure               = $Ensure
                    Name                 = "db_datareader"
                    DatabaseName         = $Name
                    InstanceName         = 'MSSQLSERVER'
                    MembersToInclude     = "$SqlLoginDomainName\${AdGroupPrefix}Read","$SqlLoginDomainName\${AdGroupPrefix}RW"
                    DependsOn            = "[SqlDatabaseUser]${AdGroupPrefix}Read"
                }
                SqlDatabaseRole "db_datawriter_${Name}"
                {
                    Ensure               = $Ensure
                    Name                 = "db_datawriter"
                    DatabaseName         = $Name
                    InstanceName         = 'MSSQLSERVER'
                    MembersToInclude     = "$SqlLoginDomainName\${AdGroupPrefix}RW"
                    DependsOn            = "[SqlDatabaseUser]${AdGroupPrefix}RW"
                }
                SqlDatabaseRole "db_owner_${Name}"
                {
                    Ensure               = $Ensure
                    Name                 = "db_owner"
                    DatabaseName         = $Name
                    InstanceName         = 'MSSQLSERVER'
                    MembersToInclude     = "$SqlLoginDomainName\${AdGroupPrefix}DBO"
                    DependsOn            = "[SqlDatabaseUser]${AdGroupPrefix}DBO"
                }
            }
        }
    }
}