# NWTC.ResourceGroups: Public Functions

Reference for every exported command in the module (v1.1.0).
For installation, logging, and module structure, see [`../Docs/README.md`](../Docs/README.md).

| Function | Purpose | Added |
|---|---|---|
| `New-TestResourceGroup` | Create resource groups with standard naming, tags, and logging | 1.0.0 |
| `Get-ResourceGroupSummary` | Read-only report of resource group name, location, and tags | 1.1.0 |

---

## New-TestResourceGroup

Creates Azure resource groups by project ID (`1001` becomes `RG-1001`) or by full name. It checks Azure first and skips groups that already exist, then returns one object per request with a `Created`, `Skipped`, or `Failed` status, followed by a run summary.

### Syntax

```powershell
New-TestResourceGroup -ProjectID <string[]> [-Tags <hashtable>] [-WhatIf] [-Confirm]
New-TestResourceGroup -ResourceGroupName <string[]> [-Tags <hashtable>] [-WhatIf] [-Confirm]
```

### Parameters

| Parameter | Type | Required | Pipeline | Notes |
|---|---|---|---|---|
| `-ProjectID` | string[] | Yes (ProjectID set) | By value | Digits only. Builds the name `RG-<ProjectID>` |
| `-ResourceGroupName` | string[] | Yes (ResourceGroupName set) | No | Letters, numbers, hyphens, and underscores |
| `-Tags` | hashtable | No | No | Defaults to `Department=IT; Environment=Test` |
| `-WhatIf` / `-Confirm` | switch | No | No | Preview or confirm before anything is created |

### Examples

```powershell
New-TestResourceGroup -ProjectID 1001
New-TestResourceGroup -ResourceGroupName Dev1, Dev2
"1001", "1002" | New-TestResourceGroup -WhatIf
Get-Content .\lab-files\ResourceGroups.txt | New-TestResourceGroup
New-TestResourceGroup -ResourceGroupName LM6-Test -Tags @{ Project = 'LM6'; Owner = 'Mike' }
```

### Output

`ResourceGroupName`, `Location`, `Status` (Created / Skipped / Failed), `Tags`, `Timestamp`, then a run summary with total, created, skipped, errors, and elapsed time.

---

## Get-ResourceGroupSummary *(new in 1.1.0)*

Read-only report of resource groups in the current subscription. It never creates, changes, or deletes anything.

### Syntax

```powershell
Get-ResourceGroupSummary [[-Name] <string[]>]
```

### Parameters

| Parameter | Type | Required | Pipeline | Notes |
|---|---|---|---|---|
| `-Name` | string[] | No | By value, and by property name (`ResourceGroupName`) | Omit it to return every resource group |

### Examples

```powershell
Get-ResourceGroupSummary                                   # all groups
Get-ResourceGroupSummary -Name 'RG-1001', 'Dev1'           # specific groups
'RG-1001' | Get-ResourceGroupSummary                       # pipeline by value
Get-AzResourceGroup -Name 'RG-1001' | Get-ResourceGroupSummary   # pipeline by property
Get-ResourceGroupSummary | Where-Object Tags -ne 'None' | Format-Table
```

### Output

| Property | Example |
|---|---|
| `ResourceGroupName` | `LM6-Test` |
| `Location` | `centralus` |
| `Tags` | `Owner=Mike; Project=LM6` (sorted by key), or `None` |

A name that doesn't exist produces a `[NOT FOUND]` warning, and the remaining names are still processed.

---

## Full help

```powershell
Get-Help New-TestResourceGroup -Full
Get-Help Get-ResourceGroupSummary -Full
```