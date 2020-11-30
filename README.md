# VMware.CfgMax

_A Powershell module to interact with the VMware Configuration Maximums website (<https://configmax.vmware.com>)_

This module is not supported by VMware, and comes with no warranties express or implied. Please test and validate its functionality before using this product in a production environment.

## Installing VMware.CfgMax

### Powershell Gallery

VMware.CfgMax is available from the PowerShell Gallery. Run the following command in a PowerShell session to install the module:

```PowerShell
Install-Module VMware.CfgMax
```

### Manual Install

If for some reason, your system is unable to access PowerShell Gallery to install modules, you can install the module manually:

Open a PowerShell session and run the following command to find all the module installation paths on your system.

```PowerShell
$env:PSModulePath
```

Navigate to one of the paths returned from the command above, and create a new directory for the module

```PowerShell
New-Item VMware.CfgMax -ItemType Directory
```

Download the `.psd1` and `.psm1` files from <https://github.com/dcoghlan/VMware.CfgMax/tree/main/module> and save them to the directory created above.

## Loading the module

Once the VMware.CfgMax module is loaded onto your system, run the following command to import the module for use:

```PowerShell
Import-Module VMware.CfgMax
```

## What's Available

There are only a couple of cmdlets in this module. To view them all, run the following command:

```PowerShell
Get-Command -Module VMware.CfgMax
```

Each available cmdlet will return details and examples via the built-in Get-Help cmdlet.

```PowerShell
Get-Help Get-CfgMaxProduct -Full
```

## Sample Usage

### List all products available on the VMware Configuration Maximums website

```PowerShell
PS > Get-CfgMaxProduct | ft

Id Name                                  ProductId PublishDate Description
-- ----                                  --------- ----------- -----------
 1 NSX Data Center for vSphere                  33 08 Feb 2018
 3 vSphere                                     199 08 Feb 2018
 4 NSX-T Data Center                            34 08 Aug 2018
 5 vRealize Operations Manager                  77 03 Oct 2018
 6 VMware Site Recovery Manager                  6 25 Oct 2018
 7 vCloud Director For Service Providers       182 26 Mar 2019
 8 VMware Cloud Director Availability          789 10 Jul 2019
 9 VMware HCX                                  834 24 Jul 2019
10 vSphere Replication                          12 06 Aug 2019
11 Horizon                                     275 24 Aug 2019
12 VMware Cloud on AWS                         310 05 Sep 2019
13 vCloud Usage meter                          183 17 Jan 2020
14 VMware Cloud Foundation                     915 26 Mar 2020
15 VMware Unified Access Gateway               351 26 Mar 2020
16 VMware Integrated OpenStack                1158 29 May 2020
17 vRealize Automation                          65 28 Sep 2020
18 VMware Cloud Disaster Recovery                0 13 Oct 2020
```

### List all the releases for a particular product (by Name)

```PowerShell
PS > Get-CfgMaxProduct -Name 'vSphere Replication' | Get-CfgMaxRelease | ft

Id Version                 ProductId ReleaseId GADate      PublishDate LastUpdate
-- -------                 --------- --------- ------      ----------- ----------
64 vSphere Replication 8.3        10         0 02 Apr 2020 02 Apr 2020 24 Mar 2020
46 vSphere Replication 8.2        10      3554 09 May 2019 09 May 2019 07 Aug 2019
45 vSphere Replication 8.1        10      2699 17 Apr 2018 17 Apr 2018 07 Aug 2019
44 vSphere Replication 6.5        10      1646 15 Nov 2016 15 Nov 2016 07 Aug 2019
```

### List all the releases for a particular product (by Id)

```PowerShell
PS > Get-CfgMaxProduct -Id 10 | Get-CfgMaxRelease | ft

Id Version                 ProductId ReleaseId GADate      PublishDate LastUpdate
-- -------                 --------- --------- ------      ----------- ----------
64 vSphere Replication 8.3        10         0 02 Apr 2020 02 Apr 2020 24 Mar 2020
46 vSphere Replication 8.2        10      3554 09 May 2019 09 May 2019 07 Aug 2019
45 vSphere Replication 8.1        10      2699 17 Apr 2018 17 Apr 2018 07 Aug 2019
44 vSphere Replication 6.5        10      1646 15 Nov 2016 15 Nov 2016 07 Aug 2019
```

### List all the categories available for a particular release

```PowerShell
PS > Get-CfgMaxProduct -Id 4 | Get-CfgMaxRelease -id 88 | Get-CfgMaxCategory | Select Id,Category,Description | ft

Id Category              Description
-- --------              -----------
17 General
16 Layer 2 Networking    NSX for vSphere offers a layer 2 overlay networking solution as well as layer 2 bridging.
18 Layer 3 Networking    NSX provides a multi-tier, in-kernel distributed logical routing system.
19 Firewall              NSX for vSphere supports an identity-based firewall in which the firewall rules that protect a given workload can be changed based on the identity of the user whom is using the workload.
20 Load Balancing        The NSX for vSphere Edge Service Gateway provides a load balancing service to distribute load across multiple workloads.
21 VPN                   The NSX for vSphere Edge Service Gateway provides a SSL VPN service.
22 Guest Introspection
31 Cloud Native          NSX integrates with Tanzu Application Service and provides logical networking and security to Cloud Foundry applications.
34 Network Introspection
74 Federation
```

### View all configuration maximums for a particular release

```Powershell
PS > $product = Get-CfgMaxProduct -Name 'vSphere Replication'
PS > $release = $product | Get-CfgMaxRelease -id 64
PS > Get-CfgMaxLimits -Product $product -Release $release | ft

Category           Group             Limit                                                                                                                    Value     Description
--------           -----             -----                                                                                                                    -----     -----------
Operational Limits Protection limits Maximum number of protected virtual machines per vSphere Replication appliance (via embedded vSphere Replication server) 200
Operational Limits Protection limits Maximum number of protected virtual machines per vSphere Replication server                                              200       The maximum number of virtual machines that you can assign to each vSphere Replication server is 200. So, if you deploy the maximum of 9 additional vSphere Replication servers, the total number of virtual machines that you can protect is 2000 between different vCenter Server instances and a maximum of 500 replications in a single vCenter Server instance.
Operational Limits Protection limits Maximum number of virtual machines managed per vSphere Replication appliance in a single vCenter server instance         500
Operational Limits Protection limits Maximum number of virtual machines configured for replication at a time                                                  20
Operational Limits Protection limits Maximum number of Multiple Point in Time Instances (MPITs)                                                               24
Operational Limits Protection limits Maximum number of virtual machines managed per vSphere Replication appliance in a vCenter Server                         2000
Operational Limits Recovery Limits   Minimum Recovery Point Objective (RPO)                                                                                   5 minutes
Operational Limits Recovery Limits   Maximum Recovery Point Objective (RPO)                                                                                   24 hours
Operational Limits Deployment Limits vSphere Replication appliances per vCenter Server instance                                                               1         You can only deploy one vSphere Replication appliance on a vCenter Server instance. When you deploy another vSphere Replication appliance, during the boot process vSphere Replication detects another appliance already deployed and registered as an extension to vCenter Server. You have to confirm if you want to proceed with the new appliance and recreate all replications or shut it down and reboot the old appliance to restore the o…
Operational Limits Deployment Limits Maximum number of additional vSphere Replication servers per vSphere Replication                                         9

```

### View a specific categories configuration maximums for a particular release

```PowerShell
PS > $product = Get-CfgMaxProduct -Name 'NSX-T Data Center'
PS > $release =  $product | Get-CfgMaxRelease -Version 'NSX-T Data Center 3.1.0'
PS > $category = $release | Get-CfgMaxCategory -Category 'Load Balancing'
PS > Get-CfgMaxLimits -Product $product -Release $release -Category $category | ft

Category                                    Group                      Limit                                                                           Value  Description
--------                                    -----                      -----                                                                           -----  -----------
Load Balancing : Virtual Servers            Virtual Servers            Virtual Servers per Small Load Balancer                                         20
Load Balancing : Virtual Servers            Virtual Servers            Virtual Servers per Medium Load Balancer                                        100
Load Balancing : Virtual Servers            Virtual Servers            Virtual Servers per Large Load Balancer                                         1,000
Load Balancing : Virtual Servers            Virtual Servers            Virtual Servers per Extra Large Load Balancer                                   2,000
Load Balancing : Pools                      Pools                      Pools per Small Load Balancer                                                   60
Load Balancing : Pools                      Pools                      Pools per Medium Load Balancer                                                  300
Load Balancing : Pools                      Pools                      Pools per Large Load Balancer                                                   3,000
Load Balancing : Pools                      Pools                      Pools per Extra Large Load Balancer                                             4,000
Load Balancing : Pool Members               Pool Members               Pool Members per Small Load Balancer                                            300
Load Balancing : Pool Members               Pool Members               Pool Members per Medium Load Balancer                                           2,000
Load Balancing : Pool Members               Pool Members               Pool Members per Large Load Balancer                                            7,500
Load Balancing : Pool Members               Pool Members               Pool Members per Extra Large Load Balancer                                      10,000
Load Balancing : Pool Members per Edge Node Pool Members per Edge Node Pool Members per Medium Edge Node                                               2,000
Load Balancing : Pool Members per Edge Node Pool Members per Edge Node Pool Members per Large Edge Node                                                7,500
Load Balancing : Pool Members per Edge Node Pool Members per Edge Node Pool Members per Bare-Metal Edge Node                                           30,000
Load Balancing : Pool Members per Edge Node Pool Members per Edge Node Pool Members per Extra Large Edge Node                                          10,000
Load Balancing : Load Balancer Instances    Load Balancer Instances    Small Load Balancer Instances per Small Edge Node in VM Form Factor             1
Load Balancing : Load Balancer Instances    Load Balancer Instances    Small Load Balancer Instances per Medium Edge Node in VM Form Factor            10
Load Balancing : Load Balancer Instances    Load Balancer Instances    Medium Load Balancer Instances per Medium Edge Node in VM Form Factor           1
Load Balancing : Load Balancer Instances    Load Balancer Instances    Small Load Balancer Instances per Large Edge Node in VM Form Factor             40
Load Balancing : Load Balancer Instances    Load Balancer Instances    Medium Load Balancer Instances per Large Edge Node in VM Form Factor            4
Load Balancing : Load Balancer Instances    Load Balancer Instances    Large Load Balancer Instances per Large Edge Node in VM Form Factor             1
Load Balancing : Load Balancer Instances    Load Balancer Instances    Small Load Balancer Instances per Extra Large Edge Node in VM Form Factor       80
Load Balancing : Load Balancer Instances    Load Balancer Instances    Medium Load Balancer Instances per Extra Large Edge Node in VM Form Factor      8
Load Balancing : Load Balancer Instances    Load Balancer Instances    Large Load Balancer Instances per Extra Large Edge Node in VM Form Factor       2
Load Balancing : Load Balancer Instances    Load Balancer Instances    Extra Large Load Balancer Instances per Extra Large Edge Node in VM Form Factor 1
Load Balancing : Load Balancer Instances    Load Balancer Instances    Small Load Balancer Instances per Bare-Metal Edge Node                          750
Load Balancing : Load Balancer Instances    Load Balancer Instances    Medium Load Balancer Instances per Bare-Metal Edge Node                         75
Load Balancing : Load Balancer Instances    Load Balancer Instances    Large Load Balancer Instances per Bare-Metal Edge Node                          18
Load Balancing : Load Balancer Instances    Load Balancer Instances    Extra Large Load Balancer Instances per Bare-Metal Edge Node                    9
```

### Compare configuration limits between 2 releases, only showing newly added values

```PowerShell
PS > $product = Get-CfgMaxProduct -Name 'NSX-T Data Center'
PS > $releaseA =  $product | Get-CfgMaxRelease -Version 'NSX-T Data Center 3.0.0'
PS > $releaseB =  $product | Get-CfgMaxRelease -Version 'NSX-T Data Center 3.1.0'
PS > Compare-CfgMaxLimits -Product $product -Release $releaseA -CompareRelease $releaseB -Show New | ft

Category                            Group                Limit                                                            NSX-T Data Center 3.0.0 NSX-T Data Center 3.1.0 CompareStatus
--------                            -----                -----                                                            ----------------------- ----------------------- -------------
General:Nodes                       Nodes                Transport Nodes per NSX Instance                                 NA                      1600                    New
General:Edge Nodes                  Edge Nodes           Network Latency between Edge Nodes part of the same Edge Cluster NA                      10ms                    New
Layer 3 Networking:Logical Routing  Logical Routing      Tier-1 Logical Routers per Edge Node                             NA                      64                      New
Layer 3 Networking:Logical Routing  Logical Routing      Tier-1 Gateways per Edge Node                                    NA                      64                      New
Layer 3 Networking:Logical Routing  Logical Routing      Combined Uplinks/CSP Ports per Tier-0 Gateway Service Router     NA                      4,000                   New
Layer 3 Networking:Logical Routing  Logical Routing      Tier-0 Logical Routers per Edge Node                             NA                      1                       New
Layer 3 Networking:Logical Routing  Logical Routing      Tier-0 Gateways per Edge Node                                    NA                      1                       New
VPN   :Layer 2 VPN                  L2 VPN               Server Sessions per Small Edge Node in VM Form Factor            NA                      64                      New
Firewall       :Intrusion Detection Intrusion Detection  Events Recorded                                                  NA                      1,500,000               New
Federation:Networking               Networking           RTEP-RTEP Tunnels per Edge Node                                  NA                      120                     New
Federation:Layer 2                  Layer 2              Stretched Segments                                               NA                      2,000                   New
Federation:Layer 2                  Layer 2              Global Segments                                                  NA                      2,000                   New
Federation:Layer 2                  Layer 2              MAC Identifiers per Overlay Segment (VNI)                        NA                      1,024                   New
Federation:Layer 2                  Layer 2              Stretched Segments Ports                                         NA                      8,000                   New
Federation:Layer 3                  Layer 3              Stretched Tier-1 Gateways per Location                           NA                      620                     New
Federation:Layer 3                  Layer 3              Locations per Stretched Tier-1 Gateway                           NA                      4                       New
Federation:Layer 3                  Layer 3              Number of Locations per Stretched Tier-0 Gateway                 NA                      4                       New
Federation:Layer 3                  Layer 3              Stretched Tier-0 Gateways per Location                           NA                      20                      New
Federation:DHCP                     DHCP                 DHCP Server Instances                                            NA                      3,000                   New
Federation:Grouping and Tagging     Grouping and Tagging Groups based on Tags per Location                                NA                      4,000                   New
Federation:Grouping and Tagging     Grouping and Tagging Global Groups                                                    NA                      5,400                   New
Federation:Grouping and Tagging     Grouping and Tagging Global Groups based on Tag                                       NA                      5,400                   New
Federation:Grouping and Tagging     Grouping and Tagging Groups across Locations                                          NA                      10,000                  New
Federation:Grouping and Tagging     Grouping and Tagging Groups Based on Tags across all Locations                        NA                      5,400                   New
Federation:Grouping and Tagging     Grouping and Tagging Groups Based on IP Sets across all Locations                     NA                      3,000                   New
Federation:Grouping and Tagging     Grouping and Tagging Groups per Location                                              NA                      3,000                   New
Federation:Global Firewall          Global Firewall      Federation Wide Firewall Sections                                NA                      3,000                   New
Federation:Global Firewall          Global Firewall      Federation Wide Rules per Section                                NA                      1,000                   New
Federation:Distributed Firewall     Distributed Firewall Stateful Firewall Rules across all Global Firewall Policies      NA                      30,000                  New
Federation:Distributed Firewall     Distributed Firewall Federation wide Stateful Firewall Rules                          NA                      30,000                  New
Federation:Distributed Firewall     Distributed Firewall Stateful Firewall Rules Applied to a Location                    NA                      10,000                  New
```

### Compare configuration limits between 2 releases, only showing modified values

```PowerShell
PS > $product = Get-CfgMaxProduct -Name 'NSX-T Data Center'
PS > $releaseA =  $product | Get-CfgMaxRelease -Version 'NSX-T Data Center 3.0.0'
PS > $releaseB =  $product | Get-CfgMaxRelease -Version 'NSX-T Data Center 3.1.0'
PS > Compare-CfgMaxLimits -Product $product -Release $releaseA -CompareRelease $releaseB -Show Modified | ft

Category                                      Group                                   Limit                                                              NSX-T Data Center 3.0.0 NSX-T Data Center 3.1.0 CompareStatus
--------                                      -----                                   -----                                                              ----------------------- ----------------------- -------------
General:Nodes                                 Nodes                                   Virtual Interfaces per Hypervisor Host                             400                     1,000                   Modified
General:Nodes                                 Nodes                                   vSphere Clusters Prepared for NSX                                  64                      128                     Modified
General:Nodes                                 Nodes                                   Hosts per vSphere Cluster                                          64                      96                      Modified
General:Nodes                                 Nodes                                   Physical Servers                                                   300                     1,024                   Modified
Layer 3 Networking:DHCP                       DHCP                                    DHCP Relays                                                        2,000                   4,000                   Modified
Layer 3 Networking:Logical Routing            Logical Routing                         Service Ports per Trunk per Service Router                         1,600                   4,000                   Modified
Layer 3 Networking:Logical Routing            Logical Routing                         Tier-1 Logical Routers per Tier-0 Logical Router                   400                     1,000                   Modified
Layer 3 Networking:Logical Routing            Logical Routing                         Tier-1 Gateways per Tier-0 Gateway                                 400                     1,000                   Modified
Firewall       :Distributed Firewall          Distributed Firewall                    Rules per Hypervisor Host                                          10,000                  120,000                 Modified
Firewall       :Grouping and Tagging          Grouping and Tagging                    Groups                                                             10,000                  20,000                  Modified
Firewall       :Identity Firewall             Identity Firewall                       VDI Virtual Machines per Host                                      150                     250                     Modified
VPN   :Layer 2 VPN                            L2 VPN                                  Logical Segments per Session per Small Edge Node in VM Form Factor 64                      512                     Modified
VPN   :IPsec VPN                              IPsec VPN                               IPsec Tunnels per Session on Bare Metal Edge Node                  256                     512                     Modified
VPN   :IPsec VPN                              IPsec VPN                               IPsec Tunnels per Small Edge Node in VM Form Factor                1,024                   2,048                   Modified
VPN   :IPsec VPN                              IPsec VPN                               IPsec Tunnels per Medium Edge Node in VM Form Factor               2,048                   4,096                   Modified
VPN   :IPsec VPN                              IPsec VPN                               IPsec Tunnels per Session on Small Edge Node in VM Form Factor     128                     512                     Modified
VPN   :IPsec VPN                              IPsec VPN                               IPsec Tunnels per Large Edge Node in VM Form Factor                4,096                   8,192                   Modified
VPN   :IPsec VPN                              IPsec VPN                               IPsec Tunnels per Bare Metal Edge Node                             4,096                   8,192                   Modified
Cloud Native:Tanzu Kubernetes Grid Integrated Tanzu Kubernetes Grid Integrated (TKGI) Kubernetes PODs                                                    25,000                  60,000                  Modified
Network Introspection:E-W                     E-W                                     Service Virtual Machines in a Cluster Based Deployment             72                      256                     Modified
Firewall       :Intrusion Detection           Intrusion Detection                     IDS Profiles                                                       3                       25                      Modified
Federation:General                            General                                 Hypervisor Hosts Across all Locations                              96                      256                     Modified
Federation:General                            General                                 Locations                                                          3                       4                       Modified
```

### Compare configuration limits between 2 releases, only showing deleted values

```PowerShell
PS > $product = Get-CfgMaxProduct -Name 'NSX-T Data Center'
PS > $releaseA =  $product | Get-CfgMaxRelease -Version 'NSX-T Data Center 3.0.0'
PS > $releaseB =  $product | Get-CfgMaxRelease -Version 'NSX-T Data Center 3.1.0'
PS > Compare-CfgMaxLimits -Product $product -Release $releaseA -CompareRelease $releaseB -Show Deleted | ft

ompare-CfgMaxLimits -Product $product -Release $releaseA -CompareRelease $releaseB -Show Deleted | ft

Category                           Group           Limit                             NSX-T Data Center 3.0.0 NSX-T Data Center 3.1.0 CompareStatus
--------                           -----           -----                             ----------------------- ----------------------- -------------
Layer 3 Networking:Logical Routing Logical Routing Uplinks per Tier-0 Service Router 16                      NA                      Deleted
```

### Compare configuration limits between 2 releases showing all limits and export to CSV

```PowerShell
PS > $product = Get-CfgMaxProduct -Name 'NSX-T Data Center'
PS > $releaseA =  $product | Get-CfgMaxRelease -Version 'NSX-T Data Center 3.0.0'
PS > $releaseB =  $product | Get-CfgMaxRelease -Version 'NSX-T Data Center 3.1.0'
PS > Compare-CfgMaxLimits -Product $product -Release $releaseA -CompareRelease $releaseB | Export-Csv -Path compare-status.csv
```

- Here is a snippet of the resulting CSV file

```CSV
"Category","Group","Limit","NSX-T Data Center 3.0.0","NSX-T Data Center 3.1.0","CompareStatus"
"General:Nodes","Nodes","Transport Nodes per NSX Instance","NA","1600","New"
"General:Nodes","Nodes","Concurrent Graphical User Interface Users per Manager","5","5",
"General:Nodes","Nodes","Discovered vSphere Clusters","640","640",
"General:Nodes","Nodes","Network Latency between the NSX Management Cluster and Transport Nodes","150ms","150ms",
"General:Nodes","Nodes","Hypervisor Hosts per NSX Management Cluster","1,024","1,024",
"General:Nodes","Nodes","Compute Managers per NSX Management Cluster","16","16",
"General:Nodes","Nodes","NSX Instances per Compute Manager","1","1",
"General:Nodes","Nodes","Virtual Interfaces per Hypervisor Host","400","1,000","Modified"
"General:Nodes","Nodes","vSphere Clusters Prepared for NSX","64","128","Modified"
"General:Nodes","Nodes","Hosts per vSphere Cluster","64","96","Modified"
"General:Nodes","Nodes","Network Latency between NSX Management Nodes","10ms","10ms",
"General:Nodes","Nodes","Physical Servers","300","1,024","Modified"
"General:Nodes","Nodes","Audit Log Entries","1,000,000","1,000,000",
"General:Nodes","Nodes","NSX Managers","3","3",
```
