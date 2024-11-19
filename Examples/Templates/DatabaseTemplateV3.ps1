Configuration DatabaseTemplateV3
{
    param (
        [string]$NodeName,
        [string]$Domain,
        [string]$Ensure,
        [string]$Name,
        [string]$DatabaseNodeName = $NodeName,
        [string]$DatabaseHost = $(switch ($DatabaseNodeName) {
                    "server1.domain.com" {
                        'sqlcluster.domain.com'
                    }
                    "server2.otherdomain.com" {
                        'sqlcluster.otherdomain.com'
                    }
                    Default {
                        $DatabaseNodeName
                    }
                }
            ),
        [string]$OuPath = $(switch ($Domain) {
                    "domain.com" {
                        'OU=Database,OU=Unit,OU=Test,OU=My,DC=domain,DC=com'
                    }
                    "otherdomain.com" {
                        'OU=Database,OU=Unit,OU=Test,OU=My,DC=otherdomain,DC=com'
                    }
                    Default {
                        Write-Error "Current domain is not covered"
                    }
                }
            ),
        [string]$SqlLoginDomainName = $(switch ($Domain) {
                    "domain.com" {
                        'DOMAIN'
                    }
                    "otherdomain.com" {
                        'OTHERDOMAIN'
                    }
                    Default {
                        Write-Error "Current domain is not covered"
                    }
                }
            )     
    )

    # Import the module that contains the File resource.
    Import-DscResource -Module PsDesiredStateConfiguration
    Import-DscResource -Module ActiveDirectoryDsc
    Import-DscResource -Module SqlServerDsc

    Node $NodeName
    {
        If ($Node.isMainDomainController) {
            ADGroup "DB_${Name}_Read" {
                GroupName        = "DB_${Name}_Read"
                Description      = "Read access to $Name on $DatabaseHost"
                Ensure           = $Ensure
                GroupScope       = 'DomainLocal'
                Category         = 'Security'
                Path             = $OuPath
            }
            ADGroup "DB_${Name}_RW" {
                GroupName        = "DB_${Name}_RW"
                Description      = "Read / Write access to $Name on $DatabaseHost"
                Ensure           = $Ensure
                GroupScope       = 'DomainLocal'
                Category         = 'Security'
                Path             = $OuPath
            }
            ADGroup "DB_${Name}_DBO" {
                GroupName        = "DB_${Name}_DBO"
                Description      = "DBO access to $Name on $DatabaseHost"
                Ensure           = $Ensure
                GroupScope       = 'DomainLocal'
                Category         = 'Security'
                Path             = $OuPath
            }
        } else {
            SQLDatabase $Name {
                Ensure       = $Ensure
                Name         = $Name
                InstanceName = 'MSSQLSERVER'
                ServerName   = $DatabaseHost
                OwnerName    = 'sa'
            }        
            SqlLogin "DB_${Name}_Read"
            {
                Ensure               = $Ensure
                Name                 = "$SqlLoginDomainName\DB_${Name}_Read"
                LoginType            = 'WindowsGroup'
                ServerName           = $DatabaseHost
                InstanceName         = 'MSSQLSERVER'
            }
            SqlLogin "DB_${Name}_RW"
            {
                Ensure               = $Ensure
                Name                 = "$SqlLoginDomainName\DB_${Name}_RW"
                LoginType            = 'WindowsGroup'
                ServerName           = $DatabaseHost
                InstanceName         = 'MSSQLSERVER'
            }
            SqlLogin "DB_${Name}_DBO"
            {
                Ensure               = $Ensure
                Name                 = "$SqlLoginDomainName\DB_${Name}_DBO"
                LoginType            = 'WindowsGroup'
                ServerName           = $DatabaseHost
                InstanceName         = 'MSSQLSERVER'
            }
            SqlDatabaseUser "DB_${Name}_Read"
            {
                Ensure               = $Ensure
                Name                 = "$SqlLoginDomainName\DB_${Name}_Read"
                LoginName            = "$SqlLoginDomainName\DB_${Name}_Read"
                DatabaseName         = $Name
                ServerName           = $DatabaseHost
                InstanceName         = 'MSSQLSERVER'
                DependsOn            = "[SqlLogin]DB_${Name}_Read", "[SQLDatabase]$Name"
                UserType             = 'Login'
            }
            SqlDatabaseUser "DB_${Name}_RW"
            {
                Ensure               = $Ensure
                Name                 = "$SqlLoginDomainName\DB_${Name}_RW"
                LoginName            = "$SqlLoginDomainName\DB_${Name}_RW"
                DatabaseName         = $Name
                ServerName           = $DatabaseHost
                InstanceName         = 'MSSQLSERVER'
                DependsOn            = "[SqlLogin]DB_${Name}_RW", "[SQLDatabase]$Name"
                UserType             = 'Login'
            }
            SqlDatabaseUser "DB_${Name}_DBO"
            {
                Ensure               = $Ensure
                Name                 = "$SqlLoginDomainName\DB_${Name}_DBO"
                LoginName            = "$SqlLoginDomainName\DB_${Name}_DBO"
                DatabaseName         = $Name
                ServerName           = $DatabaseHost
                InstanceName         = 'MSSQLSERVER'
                DependsOn            = "[SqlLogin]DB_${Name}_DBO", "[SQLDatabase]$Name"
                UserType             = 'Login'
            }
            SqlDatabaseRole "db_datareader_${Name}"
            {
                Ensure               = $Ensure
                Name                 = "db_datareader"
                DatabaseName         = $Name
                ServerName           = $DatabaseHost
                InstanceName         = 'MSSQLSERVER'
                MembersToInclude     = "$SqlLoginDomainName\DB_${Name}_Read","$SqlLoginDomainName\DB_${Name}_RW"
                DependsOn            = "[SqlDatabaseUser]DB_${Name}_Read"
            }
            SqlDatabaseRole "db_datawriter_${Name}"
            {
                Ensure               = $Ensure
                Name                 = "db_datawriter"
                DatabaseName         = $Name
                ServerName           = $DatabaseHost
                InstanceName         = 'MSSQLSERVER'
                MembersToInclude     = "$SqlLoginDomainName\DB_${Name}_RW"
                DependsOn            = "[SqlDatabaseUser]DB_${Name}_RW"
            }
            SqlDatabaseRole "db_owner_${Name}"
            {
                Ensure               = $Ensure
                Name                 = "db_owner"
                DatabaseName         = $Name
                ServerName           = $DatabaseHost
                InstanceName         = 'MSSQLSERVER'
                MembersToInclude     = "$SqlLoginDomainName\DB_${Name}_DBO"
                DependsOn            = "[SqlDatabaseUser]DB_${Name}_DBO"
            }
        }
    }
}