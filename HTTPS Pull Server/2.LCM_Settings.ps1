[DSCLocalConfigurationManager()]
Configuration LCM {	
	Param (
        [Parameter(Mandatory=$true)]
        [string[]]$ComputerName
    )

    Node $Computername
	{
		Settings # Hit Ctrl-Space for help
		{
            ConfigurationMode = 'ApplyAndAutoCorrect'
            RebootNodeIfNeeded = $true
            		
		}
	}
}

# Create the Computer.Meta.Mof in folder
$ComputerName = 'moe-bs-dsc1'
LCM -computername $ComputerName -OutputPath .\

#Push the LCM Config
Set-DscLocalConfigurationManager -ComputerName $ComputerName -Path .\ -Verbose

# Get config to check
Get-DscLocalConfigurationManager




