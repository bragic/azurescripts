function New-AzVNetPeering {
    param (
        [Parameter(Mandatory = $true)]
        [string]$LocalVNetName,

        [Parameter(Mandatory = $true)]
        [string]$LocalResourceGroup,

        [Parameter(Mandatory = $true)]
        [string]$RemoteVNetName,

        [Parameter(Mandatory = $true)]
        [string]$RemoteResourceGroup,

        [Parameter(Mandatory = $false)]
        [switch]$AllowGatewayTransit,

        [Parameter(Mandatory = $false)]
        [switch]$UseRemoteGateways
    )

    # Retrieve the Virtual Networks
    $LocalVNet = Get-AzVirtualNetwork -Name $LocalVNetName -ResourceGroupName $LocalResourceGroup
    $RemoteVNet = Get-AzVirtualNetwork -Name $RemoteVNetName -ResourceGroupName $RemoteResourceGroup

    # Ensure both VNets exist
    if (-not $LocalVNet) {
        Write-Error "Local VNet '$LocalVNetName' not found in resource group '$LocalResourceGroup'."
        return
    }
    if (-not $RemoteVNet) {
        Write-Error "Remote VNet '$RemoteVNetName' not found in resource group '$RemoteResourceGroup'."
        return
    }

    # Retrieve VNet IDs
    $LocalVNetId = $LocalVNet.Id
    $RemoteVNetId = $RemoteVNet.Id

    # Generate peering names
    $LocalToRemotePeeringName = "$LocalVNetName-to-$RemoteVNetName"
    $RemoteToLocalPeeringName = "$RemoteVNetName-to-$LocalVNetName"

    # Create peering from local to remote
    Add-AzVirtualNetworkPeering -Name $LocalToRemotePeeringName `
        -VirtualNetwork $LocalVNet `
        -RemoteVirtualNetworkId $RemoteVNetId `
        -AllowForwardedTraffic

    # Create peering from remote to local
    Add-AzVirtualNetworkPeering -Name $RemoteToLocalPeeringName `
        -VirtualNetwork $RemoteVNet `
        -RemoteVirtualNetworkId $LocalVNetId `
        -AllowForwardedTraffic


    Write-Output "VNet Peering successfully created between '$LocalVNetName' and '$RemoteVNetName'."
}
