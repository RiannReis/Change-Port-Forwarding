## About this:
This PowerShell script is designed to manage port forwarding for Windows Subsystem for Linux (WSL) using netsh interface portproxy. It requires administrator privileges and performs the following tasks:

### Parameters Definition:

`$OldPort` (optional): The old port that should be removed.
`$NewPort` (mandatory): The new port to be forwarded.
`$WSLAddress` (mandatory): The IP address of the WSL instance.

### Helper Functions:

`Test-AdminRights()`: Checks if the script is running with administrator privileges.
`Test-PortInUse($Port)`: Verifies if a given port is currently in use.
`Test-WSLAddress($Address)`: Validates if the provided WSL IP address is correctly formatted.

### Execution Logic:

- Ensures the script is run as an administrator.
- Validates the input parameters, ensuring the port is within the valid range (1024-65535) and the WSL address is correctly formatted.
- Checks if the new port is already in use and aborts if so.
- Removes any existing port forwarding configuration for $OldPort, if provided.
- Adds a new port forwarding rule mapping $NewPort to the specified $WSLAddress.
- Updates firewall rules to allow traffic on $NewPort.
- Displays the current port proxy configuration.

### Error Handling:

- The script catches and displays errors, exiting with an error code if any step fails.
- This script is useful for setting up WSL port forwarding while ensuring proper firewall and proxy configurations.
