# JSON Utilities Powershell Module

## Description

Module contains following Cmdlets

- `Get-JsonDifference` - Obtains differences between two JSON objects and produces JSON string with the following JSON object keys:

  - Added - items that were not present in FromJsonString and are now in ToJsonString JSON object.
  - Changed - items that were present in FromJsonString and in ToJsonString containing new values are from ToJsonString JSON object.
  - ChangedOriginals - - items that were present in FromJsonString and in ToJsonString containing old values are from FromJsonString JSON object.
  - Removed - items that were present in FromJsonString and are missing in ToJsonString JSON object.
  - NotChanged - items that are present in FromJsonString and in ToJsonString JSON objects with the same values.
  - New - Merged Added and Changed resulting objects representing all items that have changed and were added.

- `ConvertTo-KeysSortedJSONString` - Sorts JSON object by keys

## Target system

Was written to work on Windows PowerShell 5.1, but it also work with PowerShell 6/7 on other platforms

## **Limitations**

1. Arrays sub-objects are compared literally as strings after every object within array is sorted by keys and whole array is minified afterwards.

2. Due to limitation of ConvertTo-Json in PowerShell 5.1 <https://github.com/PowerShell/PowerShell/issues/3705> object with case sensitive keys are not supported. E.g. Can't have object wil `KeyName` and `keyname`.

## Install

Available in PSGallery: [https://www.powershellgallery.com/packages/JsonUtils](https://www.powershellgallery.com/packages/JsonUtils)

```powershell
Install-Module -Name JsonUtils -Scope CurrentUser
```

## Roadmap

2022-07-01 Szeraax-

I want to work this module towards a v1.0 release. I plan to make a full code review of the module to improve readability and improve performance. Stuff like using objects and `Add-Member` is generally quite inefficient.

It is likely that I will change at least 1 function name. I may change some parameter names. If I do, I will deprecate and add warning message, without breaking changes unless absolutely needed (unlikely).

Stay tuned!

## Usage

Full usage documentation in function docs

### `Get-JsonDifference`

```powershell
Get-Help Get-JsonDifference -Full
```

```text
NAME
    Get-JsonDifference

SYNOPSIS
    Compares two JSON strings and generated stringified JSON object representing differences.

    LIMITATIONS:
        1. Arrays sub-objects are compared literally as strings after every object within array is sorted by keys and
            whole array is minified afterwards.

        2. Due to limitation of ConvertTo-Json in PowerShell 5.1 <https://github.com/PowerShell/PowerShell/issues/3705>
            object with case sensitive keys are not supported. E.g. Can't have object wil `KeyName` and `keyname`.


SYNTAX
    Get-JsonDifference [-FromJsonString] <String> [-ToJsonString] <String> [[-Depth] <String>] [-Compress] [<CommonParameters>]


DESCRIPTION


PARAMETERS
    -FromJsonString <String>
        Old variant of stringified JSON object.

        Required?                    true
        Position?                    1
        Default value
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -ToJsonString <String>
        New variant of stringified JSON object that FromJsonString will be compared to.

        Required?                    true
        Position?                    2
        Default value
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -Depth <String>
        Depth used on resulting object conversion to JSON string ('ConvertTo-Json -Depth' parameter).
        Is it also used when converting Array values into JSON string after it has been sorted for comparison logic.

        Required?                    false
        Position?                    3
        Default value                25
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -Compress [<SwitchParameter>]
        Set to minify resulting object

        Required?                    false
        Position?                    named
        Default value                False
        Accept pipeline input?       false
        Accept wildcard characters?  false

    <CommonParameters>
        This cmdlet supports the common parameters: Verbose, Debug,
        ErrorAction, ErrorVariable, WarningAction, WarningVariable,
        OutBuffer, PipelineVariable, and OutVariable. For more information, see
        about_CommonParameters (https://go.microsoft.com/fwlink/?LinkID=113216).

INPUTS

OUTPUTS
    JSON string with the following JSON object keys:
    - Added - items that were not present in FromJsonString and are now in ToJsonString JSON object.
    - Changed - items that were present in FromJsonString and in ToJsonString containing new values are from ToJsonString JSON object.
    - ChangedOriginals - - items that were present in FromJsonString and in ToJsonString containing old values are from FromJsonString JSON object.
    - Removed - items that were present in FromJsonString and are missing in ToJsonString JSON object.
    - NotChanged - items that are present in FromJsonString and in ToJsonString JSON objects with the same values.
    - New - Merged Added and Changed resulting objects representing all items that have changed and were added.


    -------------------------- EXAMPLE 1 --------------------------

    PS > Get-JsonDifference -FromJsonString '{"foo_gone":"bar","bar":{"foo":"bar","bar":"foo"},"arr":[{"bar":"baz","foo":"bar"},1]}' `
                       -ToJsonString   '{"foo_added":"bar","bar":{"foo":"bar","bar":"baz"},"arr":[{"foo":"bar","bar":"baz"},1]}'
    {
        "Added": {
            "foo_added": "bar"
        },
        "Changed": {
            "bar": {
                "bar": "baz"
            }
        },
        "ChangedOriginals": {
            "bar": {
                "bar": "foo"
            }
        },
        "Removed": {
            "foo_gone": "bar"
        },
        "NotChanged": {
            "bar": {
                    "foo": "bar"
            },
            "arr": [
                {
                    "foo": "bar",
                    "bar": "baz"
                },
                1
            ]
        },
        "New": {
            "foo_added": "bar",
            "bar": {
                "bar": "baz"
            }
        }
    }

RELATED LINKS
    https://github.com/choovick/ps-jsonutils
```

### `ConvertTo-KeysSortedJSONString`

```powershell
Get-Help ConvertTo-KeysSortedJSONString -Full
```

```text
NAME
    ConvertTo-KeysSortedJSONString

SYNOPSIS
    Sorts JSON strings by object keys.


SYNTAX
    ConvertTo-KeysSortedJSONString [-JsonString] <String> [[-Depth] <String>] [-Compress] [<CommonParameters>]


DESCRIPTION


PARAMETERS
    -JsonString <String>
        Input JSON string

        Required?                    true
        Position?                    1
        Default value
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -Depth <String>
        Used for ConvertTo-Json on resulting object

        Required?                    false
        Position?                    2
        Default value                25
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -Compress [<SwitchParameter>]
        Returned minified JSON

        Required?                    false
        Position?                    named
        Default value                False
        Accept pipeline input?       false
        Accept wildcard characters?  false

    <CommonParameters>
        This cmdlet supports the common parameters: Verbose, Debug,
        ErrorAction, ErrorVariable, WarningAction, WarningVariable,
        OutBuffer, PipelineVariable, and OutVariable. For more information, see
        about_CommonParameters (https://go.microsoft.com/fwlink/?LinkID=113216).

INPUTS

OUTPUTS
    String of sorted and stringified JSON object


    -------------------------- EXAMPLE 1 --------------------------

    PS > ConvertTo-KeysSortedJSONString -JsonString '{"b":1,"1":{"b":null,"a":1}}'
    {
        "1": {
            "a": 1,
            "b": null
        },
        "b": 1
    }

RELATED LINKS
    https://github.com/choovick/ps-jsonutils
```

## Testing and VSCode coverage

```powershell
# Install Pester:
Install-Module Pester -MinimumVersion 5.0.2 -Scope CurrentUser -Force

# Code coverage in VSCode plugin:
code --install-extension ryanluker.vscode-coverage-gutters

# Run test
./run-test.ps1
```
