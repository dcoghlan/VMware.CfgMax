
$Script:urlBase = "https://vsantoolsapi.vmware.com"
$Script:CfgMaxHeaders = New-Object 'System.Collections.Generic.Dictionary[String,object]'
$Script:CfgMaxHeaders.Add("Origin", "https://configmax.vmware.com")
$Script:CfgMaxHeaders.Add("Referer", "https://configmax.vmware.com/guest")
$Script:CfgMaxHeaders.Add("Content-Type", "application/json")

function Convert-CfgMaxRawLimit {
    param (
        $raw
    )

    $data = $raw.split('/')
    $data[0].trim('-')
}

function Add-UriQueryParam {
    param (
        [Parameter (Mandatory = $true)]
        [object]$QueryObject,
        [Parameter (Mandatory = $true)]
        [ValidateNotNullorEmpty()]
        [string[]]$QueryString
    )

    foreach ($queryToAppend in $QueryString) {
        if ( ($null -ne $QueryObject) -AND ($QueryObject.Length -gt 1) ) {
            if ($QueryObject.contains($queryToAppend)) {
                Write-Verbose "QueryObject already contains $queryToAppend. Not adding."
            }
            else {
                if ($QueryObject.StartsWith('?')) {
                    $QueryObject = $QueryObject.Substring(1) + "&" + $queryToAppend
                }
                else {
                    $QueryObject = $QueryObject + "&" + $queryToAppend
                }
            }
        }
        else {
            $QueryObject = $queryToAppend; 
        }
    }
    $QueryObject
}

function ConvertFrom-UnixTime {
    param (
        [Parameter (Mandatory = $true)]
        [ValidateNotNullorEmpty()]
        [Double]$timestamp
    )
    $EpochStart = Get-Date 1970-01-01T00:00:00
    $EpochStart = $EpochStart.AddMilliseconds($timestamp)
    $EpochStart.tostring('dd MMM yyyy')
}

function New-CfgMaxCategorySpec {
    param (
        [Parameter (Mandatory = $true)]
        [ValidateNotNullorEmpty()]
        [string]$ProductId,
        [Parameter (Mandatory = $true)]
        [ValidateNotNullorEmpty()]
        [string]$ReleaseId
    )
    $data = @{
        "prodId"     = $ProductId;
        "relId"      = $ReleaseId
        "categories" = New-Object System.Collections.ArrayList
    }
    $data
}

function Add-CfgMaxCategorySpecItem {
    param (
        [Parameter (Mandatory = $true)]
        [ValidateNotNullorEmpty()]
        [object[]]$Category,
        [object]$spec
    )

    foreach ($item in $category) {
        
        foreach ($subcategory in $item.subcategories) {
            $data = @{
                "categoryId"    = $item.id;
                "subCategoryId" = $subcategory.id
            }
            $spec.categories.add($data)
        }
    }
    $spec
}

function New-CfgMaxProductItem {
    param (
        [Parameter (Mandatory = $true)]
        [ValidateNotNullorEmpty()]
        $Item
    )
    [PSCustomobject]@{
        "Id"          = $item.id;
        "Name"        = $item.rmVmwProduct;
        "ProductId"   = $item.rmVmwProductId;
        "PublishDate" = ConvertFrom-UnixTime -Timestamp $item.cmPublishDate;
        "Description" = $item.description;
    }
}

function New-CfgMaxReleaseItem {
    param (
        [Parameter (Mandatory = $true)]
        [ValidateNotNullorEmpty()]
        $Item
    )
    [PSCustomobject]@{
        "Id"          = $item.id;
        "Version"     = $item.rmVmwPrdRelVersion;
        "ProductId"   = $item.cmVmwProductId;
        "ReleaseId"   = $item.rmVmwPrdRelId;
        "GADate"      = ConvertFrom-UnixTime -Timestamp $item.rmVmwPrdRelGADate;
        "PublishDate" = ConvertFrom-UnixTime -Timestamp $item.cmRelPublishDate;
        "LastUpdate"  = ConvertFrom-UnixTime -Timestamp $item.lastUpdate;
    }
}

function New-CfgMaxCategoryItem {
    param (
        [Parameter (Mandatory = $true)]
        [ValidateNotNullorEmpty()]
        $Item
    )

    $categoryObject = [PSCustomobject]@{
        "Id"            = $item.id;
        "Category"      = $item.category.trim();
        "Description"   = $item.description;
        "ProductId"     = $item.cmVmwProductId;
        "ReleaseId"     = $item.cmVmwProdRelId;
        "LastUpdate"    = ConvertFrom-UnixTime -Timestamp $item.lastUpdate;
        "Child"         = $item.child;
        "subcategories" = New-Object System.Collections.ArrayList
    }

    foreach ($subcategoryItem in $item.subcategories) {
        $subCategoryObject = New-CfgMaxSubCategoryItem -Item $subcategoryItem
        $categoryObject.subcategories.Add($subCategoryObject) | Out-Null
    }

    $categoryObject
}

function New-CfgMaxSubCategoryItem {
    param (
        [Parameter (Mandatory = $true)]
        [ValidateNotNullorEmpty()]
        $Item
    )

    [PSCustomobject]@{
        "Id"          = $item.id;
        "subCategory" = $item.subCategory.trim();
        "Description" = $item.decription;
        "LastUpdate"  = ConvertFrom-UnixTime -Timestamp $item.lastUpdate;
    }
}

function Invoke-CfgMaxParseLimitResponse {
    param (
        [Parameter (Mandatory = $true)]
        [ValidateNotNullorEmpty()]
        $Limit
    )

    foreach ($category in $Limit) {
        foreach ($attribute in $category.configs) {
            $limitObject = [PSCustomobject]@{
                "Category"    = $category.name;
                "Group"       = $attribute.headername;
                "Limit"       = $attribute.keyName;
                "Value"       = $attribute.attrValue;
                "Description" = $attribute.description;
            }
            $limitObject
        }
    }
}

function Get-CfgMaxCompareIndexMap {
    <#
    .SYNOPSIS
    This cmdlet generates a mapping table of releases in order of the
    release/version rather than the GA date which is what is returned from the
    VMware Configuration Maximums site when doing a comparison of releases.

    .DESCRIPTION
    When multiple releases are submitted to the compare API, the order of the
    releases that are sent back in the response is based on the GA Date of the
    release. Unfortunatley, this means that there is a situation whereby an
    earlier realease (e.g. NSX-T Data Center 2.5.2) will be ordered AFTER a
    later release (e.g. NSX-T Data Center 3.0.0). Whilst this doesn't cause an
    issue when just displaying the output, because i've written some logic to
    show new/modified/deleted limits between the earliest and latest releases in
    the retruned comparison response, the order in which the results are
    returned actually matters.

    So this cmdlet, queries the releases for the product, as they are displayed
    in the correct order, and uses that ordered list of releases from the API,
    to generate a curated ordered hashtable of releases returned in the
    comparison response. The values assigned in the ordered hashtable are the
    index values of the release in the coparison response, so that the correct
    values for the releases can be looked up and displayed in the correct order.
    #>
    param (
        [Parameter (Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullorEmpty()]
        $Product,
        [Parameter (Mandatory = $true)]
        [ValidateNotNullorEmpty()]
        $ComparedReleases
    )

    $releases = $Product | Get-CfgMaxRelease | Sort-Object -Property Version | Select-Object Version
    $orderedReleases = [ordered]@{}
    foreach ($version in $($releases.version)) {
        if ($ComparedReleases -contains $version) {
            $orderedReleases[$version] = [array]::indexof($ComparedReleases, $version)
        }
    }
    Write-Verbose "Get-CfgMaxCompareIndexMap(): $($orderedReleases | ConvertTo-Json -Depth 100)"
    $orderedReleases
}

################################################################################
# Functions to export
################################################################################

function Get-CfgMaxProduct {
    <#
    .SYNOPSIS
    This cmdlet was designed to retrieve the list of products available on the
    VMware Configuration Maximums site.

    .DESCRIPTION
    Using a REST API call, this cmdlet will retrieve the complete list of
    products available on the VMware Configuration Maximums site. Each product
    that is discovered is returned as an individual object. Specifying no
    parameters will return all products. Alternativley, individual products can
    be returned by either specifying the -Id or -Name parameters.

    .PARAMETER Name
    Defines the product to return that is an exact name match.

    .PARAMETER Id
    Defines the product to return that is an exact Id match.

    .EXAMPLE
    Get-CfgMaxProduct

    Retrieves all products

    .EXAMPLE
    Get-CfgMaxProduct | Format-Table

    Retrieves all products and displays them all in a nice fancy table.

    .EXAMPLE
    Get-CfgMaxProduct -Name 'NSX Data Center for vSphere'
    
    Retrieves a product matching the exact name provided.

    .EXAMPLE
    Get-CfgMaxProduct -id 4
    
    Retrieves a product matching the Id provided.

    .NOTES
    Author(s):      Dale Coghlan
    Twitter:        @DaleCoghlan
    Github:         dcoghlan        

    .LINK
    https://github.com/dcoghlan/VMware.CfgMax
    #>

    [CmdLetBinding(DefaultParameterSetName = "Default")]
    
    param (
        [Parameter (Mandatory = $True, ParameterSetName = "Name")]
        [ValidateNotNullorEmpty()]
        [string]$Name,
        [Parameter (Mandatory = $True, ParameterSetName = "Id")]
        [int]$Id
    )

    $baseUri = New-Object System.UriBuilder($Script:urlBase)
    $baseUri.path = "/configmax/menutree/v1/vmwareproducts"
    $baseUri.Query = Add-UriQueryParam -QueryObject $baseUri.Query -QueryString "hasconfigmaxset=true"
    try {
        $response = Invoke-RestMethod -Uri $baseUri.Uri -Headers $Script:CfgMaxHeaders
    }
    catch {
        throw "Unable to retieve config max products."
    }

    if ($response) {
        Write-Debug ($response | ConvertTo-Json -Depth 100)
        if ($PSCmdlet.ParameterSetName -eq 'Id') {
            $item = $response | Where-Object { $_.id -eq $Id }
            if ($item) {
                New-CfgMaxProductItem -Item $item
            }
        }
        elseif ($PSBoundParameters.ContainsKey("Name")) {
            $item = $response | Where-Object { $_.rmVmwProduct -eq $Name.trim() }
            if ($item) {
                New-CfgMaxProductItem -Item $item
            }
        }
        else {
            $data = New-Object System.Collections.ArrayList
            foreach ($item in $response) {
                $tempObject = New-CfgMaxProductItem -Item $item
                $data.Add($tempObject) | Out-Null
            }
            $data
        }
    }
}

function Get-CfgMaxRelease {
    <#
    .SYNOPSIS
    Retrieve the list of releases/versions of a given product available on the
    VMware Configuration Maximums site.
    
    .DESCRIPTION
    Retrieve the list of releases/versions of a given product available on the
    VMware Configuration Maximums site.
    
    .PARAMETER Product
    Specifies the product object, as returned from the cmdlet Get-CfgMaxProduct.
    
    .PARAMETER Version
    When specified, is used to return the releas/eversion that is an exact string
    match. Cannot be specified together with -Id parameter.
    
    .PARAMETER Id
    When specified, is used to return the release/version that is an exact Id
    match. Cannot be specified together with -Version parameter.
    
    .EXAMPLE
    Get-CfgMaxProduct -Name 'NSX-T Data Center' | Get-CfgMaxRelease | Format-Table

    Retrieves all the releases for the 'NSX-T Data Center' Product, and displays
    them all in a nice table
    
    .EXAMPLE
    Get-CfgMaxProduct -Name 'NSX-T Data Center' | Get-CfgMaxRelease -Version 'NSX-T Data Center 3.1.0'

    Retrieves a release matching the exact version provided.

    .EXAMPLE
    Get-CfgMaxProduct -Name 'NSX-T Data Center' | Get-CfgMaxRelease -Id 88

    Retrieves a specific release matching the Id provided.

    .NOTES
    Author(s):      Dale Coghlan
    Twitter:        @DaleCoghlan
    Github:         dcoghlan        

    .LINK
    https://github.com/dcoghlan/VMware.CfgMax
    #>

    [CmdLetBinding(DefaultParameterSetName = "Default")]
    param (
        [Parameter (Mandatory = $True, ValueFromPipeline = $true)]
        [ValidateNotNullorEmpty()]
        [object]$Product,
        [Parameter (Mandatory = $True, ParameterSetName = "Version")]
        [ValidateNotNullorEmpty()]
        [string]$Version,
        [Parameter (Mandatory = $True, ParameterSetName = "Id")]
        [int]$Id
    )
    $baseUri = New-Object System.UriBuilder($Script:urlBase)
    $baseUri.path = "/configmax/menutree/v1/vmwareproducts/$($product.id)/releases"
    $baseUri.Query = Add-UriQueryParam -QueryObject $baseUri.Query -QueryString "hasconfigmaxset=true", "ispublished=true"
    try {
        $response = Invoke-RestMethod -Uri $baseUri.Uri -Headers $Script:CfgMaxHeaders
    }
    catch {
        throw "Unable to retieve config max releases."
    }
    $data = New-Object System.Collections.ArrayList
    if ($response) {
        Write-Debug ($response | ConvertTo-Json -Depth 100)
        if ($PSCmdlet.ParameterSetName -eq 'Id') {
            $item = $response | Where-Object { $_.id -eq $Id }
            if ($item) {
                New-CfgMaxReleaseItem -Item $Item
            }
        }
        elseif ($PSBoundParameters.ContainsKey("Version")) {
            $item = $response | Where-Object { $_.rmVmwPrdRelVersion -eq $Version.trim() }
            if ($item) {
                New-CfgMaxReleaseItem -Item $Item
            }
        }
        else {
            foreach ($item in $response) {
                $tempObject = New-CfgMaxReleaseItem -Item $Item
                $data.Add($tempObject) | Out-Null
            }
            $data
        }
    }
}

function Get-CfgMaxCategory {
    <#
    .SYNOPSIS
    Retrieve the list of categories of a given product/release combination
    available on the VMware Configuration Maximums site.
    
    .DESCRIPTION
    Retrieve the list of categories of a given product/release combination
    available on the VMware Configuration Maximums site.
    
    .PARAMETER Release
    Specifies the release object to retieve the categories for.
    
    .PARAMETER Id
    When specified, is used to return the category that is an exact Id
    match. Cannot be specified together with -Category parameter.
    
    .PARAMETER Category
    When specified, is used to return the category that is an exact string
    match. Cannot be specified together with -Id parameter.
    
    .EXAMPLE
    Get-CfgMaxProduct -Name 'NSX-T Data Center' | Get-CfgMaxRelease -Version 'NSX-T Data Center 3.1.0' | Get-CfgMaxCategory | Format-Table

    Retrieves all the categories for the 'NSX-T Data Center 3.1.0' release of 
    the 'NSX-T Data Center' Product, and displays them all in a nice table

    .EXAMPLE
    Get-CfgMaxProduct -Name 'NSX-T Data Center' | Get-CfgMaxRelease -Version 'NSX-T Data Center 3.1.0' | Get-CfgMaxCategory -Id 17

    Retrieves a category matching the exact version provided.

    .EXAMPLE
    Get-CfgMaxProduct -Name 'NSX-T Data Center' | Get-CfgMaxRelease -Version 'NSX-T Data Center 3.1.0' | Get-CfgMaxCategory -Category 'Layer 3 Networking'
    
    Retrieves a category matching the exact category provided.

    .NOTES
    Author(s):      Dale Coghlan
    Twitter:        @DaleCoghlan
    Github:         dcoghlan        

    .LINK
    https://github.com/dcoghlan/VMware.CfgMax
    #>

    [CmdLetBinding(DefaultParameterSetName = "Default")]
    param (
        [Parameter (Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullorEmpty()]
        [object]$Release,
        [Parameter (Mandatory = $True, ParameterSetName = "Id")]
        [ValidateNotNullorEmpty()]
        [int]$Id,
        [Parameter (Mandatory = $True, ParameterSetName = "Category")]
        [ValidateNotNullorEmpty()]
        [string]$Category
    )
    $baseUri = New-Object System.UriBuilder($Script:urlBase)
    $baseUri.path = "/configmax/menutree/v1/vmwareproducts/$($Release.ProductId)/releases/$($Release.Id)/categories"

    try {
        $response = Invoke-RestMethod -Uri $baseUri.Uri -Headers $Script:CfgMaxHeaders
    }
    catch {
        throw "Unable to retieve config max categories for ID: $($Release.Id)."
    }

    if ($response) {
        Write-Debug ($response | ConvertTo-Json -Depth 100)
        if ($PSCmdlet.ParameterSetName -eq 'Id') {
            $item = $response | Where-Object { $_.id -eq $Id }
            New-CfgMaxCategoryItem -Item $item
        }
        elseif ($PSCmdlet.ParameterSetName -eq 'Category') {
            $item = $response | Where-Object { $_.category.trim() -eq $Category.trim() }
            New-CfgMaxCategoryItem -Item $item
        }
        else {
            $data = New-Object System.Collections.ArrayList
            foreach ($item in $response) {
                $data.Add($(New-CfgMaxCategoryItem -Item $item)) | Out-Null
            }
            $data
        }
    }
}

function Get-CfgMaxLimits {
    <#
    .SYNOPSIS
    Retrieve the list of limits from the VMware Configuration Maximums site 
    based on the Product, Release and Categories specified.
    
    .DESCRIPTION
    Retrieve the list of limits from the VMware Configuration Maximums site 
    based on the Product, Release and Categories specified.    
    
    .PARAMETER Product
    Specifies the Product object to retieve the limits for.
    
    .PARAMETER Release
    Specifies the Release object to retieve the limits for.

    .PARAMETER Category
    Specifies the Category object to retieve the limits for.
    
    .EXAMPLE
    $product = Get-CfgMaxProduct -Name 'NSX-T Data Center'
    PS > $release = $product | Get-CfgMaxRelease -Version 'NSX-T Data Center 3.1.0'
    PS > Get-CfgMaxLimits -product $product -Release $release

    Retrieve the limits for the entire NSX-T 3.1.0 release (All Categories)

    .EXAMPLE
    $product = Get-CfgMaxProduct -Name 'NSX-T Data Center'
    PS > $release = $product | Get-CfgMaxRelease -Version 'NSX-T Data Center 3.1.0'
    PS > $category = $release | Get-CfgMaxCategory -Category 'Load Balancing'
    PS > Get-CfgMaxLimits -product $product -Release $release -Category $category

    Retrieve the limits for the NSX-T 3.1.0 Load Balancing Category only
    
    .NOTES
    Author(s):      Dale Coghlan
    Twitter:        @DaleCoghlan
    Github:         dcoghlan        

    .LINK
    https://github.com/dcoghlan/VMware.CfgMax
    #>

    param (
        [Parameter (Mandatory = $true)]
        [ValidateScript( { $_ })]
        [object]$Product,
        [Parameter (Mandatory = $true)]
        [ValidateNotNullorEmpty()]
        [object]$Release,
        [Parameter (Mandatory = $False)]
        [ValidateScript( { $_ })]
        [object[]]$Category
    )

    # process {

    $baseUri = New-Object System.UriBuilder($Script:urlBase)
    $baseUri.path = "/configmax/managelimits/v1/vmwareproducts/$($Product.Id)/releases/$($Release.Id)/categories/attributes"
    $baseUri.Query = Add-UriQueryParam -QueryObject $baseUri.Query -QueryString "showall=false", "isTotalCount=false"

    $body = New-CfgMaxCategorySpec -ProductId $Product.Id -ReleaseId $Release.Id
    if ($Category) {
        Add-CfgMaxCategorySpecItem -spec $body -Category $Category | Out-Null
    }
    Write-Verbose $($body | ConvertTo-Json -Depth 100)

    try {
        $response = Invoke-RestMethod -Method POST -Uri $baseUri.uri -Headers $Script:CfgMaxHeaders -Body $($body | ConvertTo-Json -Depth 100)
    }
    catch {
        throw "Unable to retieve config max limits."
    }

    if ($response) {
        Write-Debug ($response | ConvertTo-Json -Depth 100)
        Invoke-CfgMaxParseLimitResponse -Limit $response 
    }

    # }
}

function Compare-CfgMaxLimits {
    <#
    .SYNOPSIS
    Compares the configuration maximum limits between different product releases
    to help identify which limits have been added, changed, removed or remain
    the same.

    .DESCRIPTION
    Compares the configuration maximum limits between different product releases
    to help identify which limits have been added, changed, removed or remain
    the same. It doesn't matter which release is provided to the -Release or
    -CompareRelease parameters, as the comparison will always be between the
    oldest and newest releases provided.    

    .PARAMETER Product
    Specifies the Product object to that will be used for the comparison.

    .PARAMETER Release
    Specifies the Release object that is used as the base comparison object.

    .PARAMETER CompareReleases
    Specifies one or more Release objects to use for the comparison. 

    .PARAMETER Show
    Specifies which types of limits are displayed. Default is All

    All = Displays all limits from all releases specified in the comparison.

    New = Limits which exist in the latest release specified in the comparison,
    which did not exist in the earliest release specified in the comparison.

    Modified = Limits which are different between the earliest and latest
    releases specified in the comparison.

    Deleted = Limits which exist in the earliest release specified in the
    comparison, which do not exist in the latest release specified in the
    comparison.

    .EXAMPLE
    $product = Get-CfgMaxProduct -Name 'NSX-T Data Center'
    PS > $releaseA = $product | Get-CfgMaxRelease -Version 'NSX-T Data Center 3.0.0'
    PS > $releaseB = $product | Get-CfgMaxRelease -Version 'NSX-T Data Center 2.5.2'
    PS > Compare-CfgMaxLimits -Product $product -Release $releaseA -CompareRelease $releaseB

    Compare the limits between NSX-T Data Center releases 2.5.2 and 3.0.0

    .EXAMPLE
    $product = Get-CfgMaxProduct -Name 'NSX-T Data Center'
    PS > $releaseA = $product | Get-CfgMaxRelease -Version 'NSX-T Data Center 3.0.0' 
    PS > $releaseB = $product | Get-CfgMaxRelease -Version 'NSX-T Data Center 2.5.2'
    PS > Compare-CfgMaxLimits -Product $product -Release $releaseA -CompareRelease $releaseB | Format-Table

    Compare the limits between NSX-T Data Center releases 2.5.2 and 3.0.0 and format the output in a nice table

    .EXAMPLE
    $product = Get-CfgMaxProduct -Name 'NSX-T Data Center'
    PS > $releaseA = $product | Get-CfgMaxRelease -Version 'NSX-T Data Center 3.0.0' 
    PS > $releaseB = $product | Get-CfgMaxRelease -Version 'NSX-T Data Center 2.5.2' 
    PS > Compare-CfgMaxLimits -Product $product -Release $releaseA -CompareRelease $releaseB -Show New | Format-Table

    Compare the limits between NSX-T Data Center releases 2.5.2 and 3.0.0 and only display the newly added entries in a nicely formatted table

    .EXAMPLE
    $product = Get-CfgMaxProduct -Name 'NSX-T Data Center'
    PS > $releaseA = $product | Get-CfgMaxRelease -Version 'NSX-T Data Center 3.0.0' 
    PS > $releaseB = $product | Get-CfgMaxRelease -Version 'NSX-T Data Center 2.5.2' 
    PS > Compare-CfgMaxLimits -Product $product -Release $releaseA -CompareRelease $releaseB -Show Modified | Format-Table

    Compare the limits between NSX-T Data Center releases 2.5.2 and 3.0.0 and only display the modified entries in a nicely formatted table

    .EXAMPLE
    $product = Get-CfgMaxProduct -Name 'NSX-T Data Center'
    PS > $releaseA = $product | Get-CfgMaxRelease -Version 'NSX-T Data Center 3.0.0' 
    PS > $releaseB = $product | Get-CfgMaxRelease -Version 'NSX-T Data Center 2.5.2' 
    PS > Compare-CfgMaxLimits -Product $product -Release $releaseA -CompareRelease $releaseB -Show Deleted | Format-Table

    Compare the limits between NSX-T Data Center releases 2.5.2 and 3.0.0 and only display the deleted entries in a nicely formatted table

    .EXAMPLE
    $product = Get-CfgMaxProduct -Name 'NSX-T Data Center'
    PS > $releaseA = $product | Get-CfgMaxRelease -Version 'NSX-T Data Center 3.0.0' 
    PS > $releaseB = $product | Get-CfgMaxRelease -Version 'NSX-T Data Center 2.5.2' 
    PS > $releaseC = $product | Get-CfgMaxRelease -Version 'NSX-T Data Center 2.5.1' 
    PS > $releaseD = $product | Get-CfgMaxRelease -Version 'NSX-T Data Center 3.0.1' 
    PS > Compare-CfgMaxLimits -Product $product -Release $releaseA -CompareRelease $releaseB, $ReleaseC, $ReleaseD -Show All | Format-Table

    Compare the limits between NSX-T Data Center releases 2.5.1, 2.5.2, 3.0.0, and 3.1.1 and display the entries in a nicely formatted table

    .NOTES
    Author(s):      Dale Coghlan
    Twitter:        @DaleCoghlan
    Github:         dcoghlan        

    .LINK
    https://github.com/dcoghlan/VMware.CfgMax
    #>
    param (
        [Parameter (Mandatory = $true)]
        [ValidateNotNullorEmpty()]
        [object]$Product,
        [Parameter (Mandatory = $true)]
        [ValidateNotNullorEmpty()]
        [object]$Release,
        [Parameter (Mandatory = $true)]
        [ValidateNotNullorEmpty()]
        [object]$CompareRelease,
        [Parameter (Mandatory = $False)]
        [ ValidateSet("New", "Modified", "Deleted", "All") ]
        [string]$Show = "All"
    )

    $baseUri = New-Object System.UriBuilder($Script:urlBase)
    $baseUri.path = "/configmax/comparelimits/v1/vmwareproducts/$($Product.Id)/releases/$($Release.Id)/configmaxset/comparision"
    $body = @{
        "vmwareProductId" = $Product.Id;
        "releaseIds"      = New-Object System.Collections.ArrayList
    }
    foreach ($rel in $CompareRelease) {
        $body.item('releaseIds').Add($rel.Id) | Out-Null
    }

    Write-Verbose $($body | ConvertTo-Json -Depth 100)
    try {
        $response = Invoke-RestMethod -Method POST -Uri $baseUri.uri -Headers $Script:CfgMaxHeaders -Body $($body | ConvertTo-Json -Depth 100)
    }
    catch {
        throw "Unable to compare config max limits."
    }
    
    if ($response) {
        Write-Debug ($response | ConvertTo-Json -Depth 100)

        $releaseOrderIndexMap = Get-CfgMaxCompareIndexMap -Product $Product -ComparedReleases $response.releases
        Write-Verbose "$($releaseOrderIndexMap | ConvertTo-Json -Depth 100)"
        $valueStartIndex = $releaseOrderIndexMap[($releaseOrderIndexMap.keys | Select-Object -First 1)]
        Write-Verbose "StartIndex = $valueStartIndex"
        $valueEndIndex = $releaseOrderIndexMap[($releaseOrderIndexMap.keys | Select-Object -Last 1)]
        Write-Verbose "EndIndex = $valueEndIndex"

        foreach ($category in $response.Categories) {
            foreach ($attribute in $category.attributes) {
                $limitObject = [PSCustomobject]@{
                    "Category" = $category.categoryName;
                    "Group"    = $attribute.attributeHeader;
                    "Limit"    = $attribute.attributKey;
                }
                foreach ($returnedReleaseName in $releaseOrderIndexMap.keys) {
                    $xlatedIndex = $releaseOrderIndexMap[$returnedReleaseName]
                    $limitObject | Add-Member -MemberType NoteProperty -Name $returnedReleaseName -Value (Convert-CfgMaxRawLimit -raw $attribute.attributeValues[$xlatedIndex])
                }

                $limitObject | Add-Member -MemberType NoteProperty -Name 'CompareStatus' -Value $null
                
                $valueStart = $attribute.attributeValues[$valueStartIndex]
                $valueEnd = $attribute.attributeValues[$valueEndIndex]
                if ( ($valueStart -eq 'NA') -AND ($valueEnd -ne 'NA') ) {
                    $limitObject.CompareStatus = 'New'
                }
                elseif ( ($valueEnd -eq 'NA') -AND ($valueStart -ne 'NA') ) {
                    $limitObject.CompareStatus = 'Deleted'
                }
                elseif ($valueStart -ne $valueEnd) {
                    $limitObject.CompareStatus = 'Modified'
                }
    
                switch ($Show) {
                    "New" {
                        if ($limitObject.CompareStatus -eq 'New') { $limitObject }
                        Break
                    }
                    "Modified" {
                        if ($limitObject.CompareStatus -eq 'Modified') { $limitObject }
                        Break
                    }
                    "Deleted" {
                        if ($limitObject.CompareStatus -eq 'Deleted') { $limitObject }
                        Break
                    }
                    Default {
                        $limitObject
                    }
                }
            }
        }
    }
}
