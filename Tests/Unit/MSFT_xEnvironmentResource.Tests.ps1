﻿$errorActionPreference = 'Stop'
Set-StrictMode -Version 'Latest'

Import-Module -Name (Join-Path -Path (Split-Path $PSScriptRoot -Parent) `
                               -ChildPath 'CommonTestHelper.psm1')

$script:testEnvironment = Enter-DscResourceTestEnvironment `
    -DscResourceModuleName 'xPSDesiredStateConfiguration' `
    -DscResourceName 'MSFT_xEnvironmentResource' `
    -TestType 'Unit'

try
{
    InModuleScope 'MSFT_xEnvironmentResource' {
        # Mock objects
        $script:mockEnvironmentVarName1 = 'PATH'
        $script:mockEnvironmentVarName2 = 'APPDATA'
        $script:mockEnvironmentVarInvalidName = 'Invalid'

        $script:mockEnvironmentVar1 = @{
            PATH = 'mock path for testing'
        }
            
        $script:mockEnvironmentVar2 = @{
            APPDATA = 'mock path to Application Data directory for testing'
        }

        Describe 'xEnvironmentResource\Get-TargetResource' {
            Mock -CommandName 'Get-ItemPropertyExpanded' -MockWith {
                if ($Name -eq $script:mockEnvironmentVarName1)
                {
                    return $script:mockEnvironmentVar1.PATH
                }
                else
                {
                    return $null
                }
            }

            Context 'Environment variable exists' {
                $getTargetResourceResult = Get-TargetResource -Name $script:mockEnvironmentVarName1

                It 'Should retrieve the expanded environment variable object' {
                    Assert-MockCalled -CommandName 'Get-ItemPropertyExpanded' -Exactly 1 -Scope 'Context'
                }

                It 'Should return a hashtable' {
                    $getTargetResourceResult -is [Hashtable] | Should Be $true
                }

                It 'Should return the environment variable name' {
                    $getTargetResourceResult.Name | Should Be $script:mockEnvironmentVarName1
                }

                It 'Should return the environment variable Ensure state as Present' {
                    $getTargetResourceResult.Ensure | Should Be 'Present'
                }

                It 'Should return the value of the environment variable' {
                    $getTargetResourceResult.Value | Should Be $script:mockEnvironmentVar1.$script:mockEnvironmentVarName1
                }
            }

            Context 'Environment variable does not exist' {
                $getTargetResourceResult = Get-TargetResource -Name $script:mockEnvironmentVarInvalidName

                It 'Should retrieve the expanded environment variable object' {
                    Assert-MockCalled -CommandName 'Get-ItemPropertyExpanded' -Exactly 1 -Scope 'Context'
                }

                It 'Should return a hashtable' {
                    $getTargetResourceResult -is [Hashtable] | Should Be $true
                }

                It 'Should return the environment variable name' {
                    $getTargetResourceResult.Name | Should Be $script:mockEnvironmentVarInvalidName
                }

                It 'Should return the environment variable Ensure state as Absent' {
                    $getTargetResourceResult.Ensure | Should Be 'Absent'
                }
                
                It 'Should return Value as null' {
                    $getTargetResourceResult.Value | Should Be $null
                }
            }
        }

        Describe 'xEnvironmentResource\Set-TargetResource' {
            Context 'Add new environment variable without Path and item properties not present' {
                $newPathValue = 'new path value'
                Mock -CommandName Get-ItemPropertyExpanded -MockWith { return $null }
                Mock -CommandName Get-EnvironmentVariable -MockWith { return $null }
                Mock -CommandName Set-EnvironmentVariable -MockWith { $script:mockEnvironmentVar1.PATH = $newPathValue }
                
                It 'Should not throw an exception' {
                    { Set-TargetResource -Name $script:mockEnvironmentVarName1 -Value $newPathValue } | Should Not Throw
                }
                
                It 'Should have set the mock variable value' {
                    $script:mockEnvironmentVar1.PATH | Should Be $newPathValue
                }

                It 'Should have called the correct mocks to set the environment variable' {
                    Assert-MockCalled Get-ItemPropertyExpanded -Exactly 1 -Scope Context
                    Assert-MockCalled Get-EnvironmentVariable -Exactly 1 -Scope Context
                    Assert-MockCalled Set-EnvironmentVariable -Exactly 1 -Scope Context
                }
            }

            Context 'Add new environment variable with Path and item properties present' {
                $newPathValue = 'new path value2'
                Mock -CommandName Get-EnvironmentVariable -MockWith { return $null }
                Mock -CommandName Set-EnvironmentVariable -MockWith { $script:mockEnvironmentVar1.PATH = $newPathValue }
                
                It 'Should not throw an exception' {
                    { Set-TargetResource -Name $script:mockEnvironmentVarName1 -Value $newPathValue -Path $true } | Should Not Throw
                }
                
                It 'Should have set the mock variable value' {
                    $script:mockEnvironmentVar1.PATH | Should Be $newPathValue
                }

                It 'Should have called the correct mocks to set the environment variable' {
                    Assert-MockCalled Get-EnvironmentVariable -Exactly 2 -Scope Context
                    Assert-MockCalled Set-EnvironmentVariable -Exactly 1 -Scope Context
                }
            }

            Context 'Update environment variable but no Value specified' {
                Mock -CommandName Get-ItemPropertyExpanded -MockWith { return $script:mockEnvironmentVar1.PATH }
                Mock -CommandName Get-EnvironmentVariable -MockWith { return 'mock environment variable' }
                Mock -CommandName Set-EnvironmentVariable -MockWith {}
                
                It 'Should not throw an exception' {
                    { Set-TargetResource -Name $script:mockEnvironmentVarName1 } | Should Not Throw
                }

                It 'Should have called the correct mocks to not set the environment variable' {
                    Assert-MockCalled Get-ItemPropertyExpanded -Exactly 1 -Scope Context
                    Assert-MockCalled Get-EnvironmentVariable -Exactly 1 -Scope Context
                    Assert-MockCalled Set-EnvironmentVariable -Exactly 0 -Scope Context
                }
            }

            Context 'Update environment variable without Path and Value given is the value already set' {
                $newPathValue = 'new path value2'
                $script:mockEnvironmentVar1.PATH = $newPathValue
                Mock -CommandName Get-ItemPropertyExpanded -MockWith { return $script:mockEnvironmentVar1.PATH }
                Mock -CommandName Get-EnvironmentVariable -MockWith { return $script:mockEnvironmentVar1.PATH }
                Mock -CommandName Set-EnvironmentVariable -MockWith { $script:mockEnvironmentVar1.PATH = 'bad value' }
                
                It 'Should not throw an exception' {
                    { Set-TargetResource -Name $script:mockEnvironmentVarName1 -Value $newPathValue } | Should Not Throw
                }
                
                It 'Should not have updated the mock variable value' {
                    $script:mockEnvironmentVar1.PATH | Should Be $newPathValue
                }

                It 'Should have called the correct mocks to not set the environment variable' {
                    Assert-MockCalled Get-ItemPropertyExpanded -Exactly 1 -Scope Context
                    Assert-MockCalled Get-EnvironmentVariable -Exactly 1 -Scope Context
                    Assert-MockCalled Set-EnvironmentVariable -Exactly 0 -Scope Context
                }
            }

            Context 'Update environment variable without Path and new Value passed in' {
                $newPathValue = 'new path value3'
                Mock -CommandName Get-ItemPropertyExpanded -MockWith { return $script:mockEnvironmentVar1.PATH }
                Mock -CommandName Get-EnvironmentVariable -MockWith { return $script:mockEnvironmentVar1.PATH }
                Mock -CommandName Set-EnvironmentVariable -MockWith { $script:mockEnvironmentVar1.PATH = $newPathValue }
                
                It 'Should not throw an exception' {
                    { Set-TargetResource -Name $script:mockEnvironmentVarName1 -Value $newPathValue } | Should Not Throw
                }
                
                It 'Should have updated the mock variable value' {
                    $script:mockEnvironmentVar1.PATH | Should Be $newPathValue
                }

                It 'Should have called the correct mocks to set the environment variable' {
                    Assert-MockCalled Get-ItemPropertyExpanded -Exactly 1 -Scope Context
                    Assert-MockCalled Get-EnvironmentVariable -Exactly 1 -Scope Context
                    Assert-MockCalled Set-EnvironmentVariable -Exactly 1 -Scope Context
                }
            }

            Context 'Update environment variable with Path and invalid Value (;) passed in' {
                $newPathValue = ';'
                Mock -CommandName Get-EnvironmentVariable -MockWith { return $script:mockEnvironmentVar1.PATH }
                Mock -CommandName Set-EnvironmentVariable -MockWith { $script:mockEnvironmentVar1.PATH = $newPathValue }
                
                It 'Should not throw an exception' {
                    { Set-TargetResource -Name $script:mockEnvironmentVarName1 -Value $newPathValue -Path $true } | Should Not Throw
                }
                
                It 'Should not have updated the mock variable value' {
                    $script:mockEnvironmentVar1.PATH | Should Not Be $newPathValue
                }

                It 'Should have called the correct mocks to not set the environment variable' {
                    Assert-MockCalled Get-EnvironmentVariable -Exactly 2 -Scope Context
                    Assert-MockCalled Set-EnvironmentVariable -Exactly 0 -Scope Context
                }
            }

            Context 'Update environment variable with Path and invalid Value ( ) passed in' {
                $newPathValue = '    '
                Mock -CommandName Get-EnvironmentVariable -MockWith { return $script:mockEnvironmentVar1.PATH }
                Mock -CommandName Set-EnvironmentVariable -MockWith { $script:mockEnvironmentVar1.PATH = $newPathValue }
                
                It 'Should not throw an exception' {
                    { Set-TargetResource -Name $script:mockEnvironmentVarName1 -Value $newPathValue -Path $true } | Should Not Throw
                }
                
                It 'Should not have updated the mock variable value' {
                    $script:mockEnvironmentVar1.PATH | Should Not Be $newPathValue
                }

                It 'Should have called the correct mocks to not set the environment variable' {
                    Assert-MockCalled Get-EnvironmentVariable -Exactly 2 -Scope Context
                    Assert-MockCalled Set-EnvironmentVariable -Exactly 0 -Scope Context
                }
            }

            Context 'Update environment variable with new Path and valid Value passed in' {
                $newPathValue = 'new path value 4'
                $newFullPathValue = ($script:mockEnvironmentVar1.PATH +';' + $newPathValue)
                Mock -CommandName Get-EnvironmentVariable -MockWith { return $script:mockEnvironmentVar1.PATH }
                Mock -CommandName Set-EnvironmentVariable -MockWith { $script:mockEnvironmentVar1.PATH = $newFullPathValue }
                
                It 'Should not throw an exception' {
                    { Set-TargetResource -Name $script:mockEnvironmentVarName1 -Value $newPathValue -Path $true } | Should Not Throw
                }
                
                It 'Should have updated the mock variable value' {
                    $script:mockEnvironmentVar1.PATH | Should Be $newFullPathValue
                }

                It 'Should have called the correct mocks to set the environment variable' {
                    Assert-MockCalled Get-EnvironmentVariable -Exactly 2 -Scope Context
                    Assert-MockCalled Set-EnvironmentVariable -Exactly 2 -Scope Context
                }
            }

            Context 'Update environment variable with Value that the environment variable is already set to' {
                $oldPathValue = $script:mockEnvironmentVar1.PATH
                $newPathValue = 'new path value 5'
                $newFullPathValue = ($script:mockEnvironmentVar1.PATH +';' + $newPathValue)
                Mock -CommandName Get-EnvironmentVariable -MockWith { return $script:mockEnvironmentVar1.PATH }
                Mock -CommandName Set-EnvironmentVariable -MockWith { $script:mockEnvironmentVar1.PATH = $newFullPathValue }
                
                It 'Should not throw an exception' {
                    { Set-TargetResource -Name $script:mockEnvironmentVarName1 -Value $oldPathValue -Path $true } | Should Not Throw
                }
                
                It 'Should not have updated the mock variable value' {
                    $script:mockEnvironmentVar1.PATH | Should Be $oldPathValue
                }

                It 'Should have called the correct mocks to not set the environment variable' {
                    Assert-MockCalled Get-EnvironmentVariable -Exactly 2 -Scope Context
                    Assert-MockCalled Set-EnvironmentVariable -Exactly 0 -Scope Context
                }
            }

            Context 'Remove environment variable that is already removed' {
                Mock -CommandName Get-ItemPropertyExpanded -MockWith { return $null }
                Mock -CommandName Get-EnvironmentVariable -MockWith { return $null }
                Mock -CommandName Remove-EnvironmentVariable -MockWith {}
                
                It 'Should not throw an exception' {
                    { Set-TargetResource -Name $script:mockEnvironmentVarName1 -Ensure 'Absent' } | Should Not Throw
                }

                It 'Should have called the correct mocks to not remove the environment variable' {
                    Assert-MockCalled Get-ItemPropertyExpanded -Exactly 1 -Scope Context
                    Assert-MockCalled Get-EnvironmentVariable -Exactly 1 -Scope Context
                    Assert-MockCalled Remove-EnvironmentVariable -Exactly 0 -Scope Context
                }
            }

            Context 'Remove environment variable with no Value specified' {
                Mock -CommandName Get-EnvironmentVariable -MockWith { return $script:mockEnvironmentVar1.PATH }
                Mock -CommandName Remove-EnvironmentVariable -MockWith {}
                Mock -CommandName Test-PathInPathList -MockWith { return $false }
                
                It 'Should not throw an exception' {
                    { Set-TargetResource -Name $script:mockEnvironmentVarName1 -Ensure 'Absent' -Path $true } | Should Not Throw
                }

                It 'Should have called the correct mocks to remove the environment variable' {
                    Assert-MockCalled Get-EnvironmentVariable -Exactly 2 -Scope Context
                    Assert-MockCalled Remove-EnvironmentVariable -Exactly 1 -Scope Context
                    Assert-MockCalled Test-PathInPathList -Exactly 0 -Scope Context
                }
            }

            Context 'Remove environment variable with Value specified and Path set to false' {
                Mock -CommandName Get-ItemPropertyExpanded -MockWith { return $script:mockEnvironmentVar1.PATH }
                Mock -CommandName Get-EnvironmentVariable -MockWith { return $script:mockEnvironmentVar1.PATH }
                Mock -CommandName Remove-EnvironmentVariable -MockWith {}
                Mock -CommandName Test-PathInPathList -MockWith { return $false }
                
                It 'Should not throw an exception' {
                    { Set-TargetResource -Name $script:mockEnvironmentVarName1 `
                                         -Value 'mockNewValue' `
                                         -Ensure 'Absent' `
                                         -Path $false 
                    } | Should Not Throw
                }

                It 'Should have called the correct mocks to remove the environment variable' {
                    Assert-MockCalled Get-ItemPropertyExpanded -Exactly 1 -Scope Context
                    Assert-MockCalled Get-EnvironmentVariable -Exactly 1 -Scope Context
                    Assert-MockCalled Remove-EnvironmentVariable -Exactly 1 -Scope Context
                    Assert-MockCalled Test-PathInPathList -Exactly 0 -Scope Context
                }
            }

            Context 'Remove environment variable with Value set to semicolen (;) and Path set to true' {
                Mock -CommandName Get-EnvironmentVariable -MockWith { return $script:mockEnvironmentVar1.PATH }
                Mock -CommandName Remove-EnvironmentVariable -MockWith {}
                Mock -CommandName Test-PathInPathList -MockWith { return $false }
                
                It 'Should not throw an exception' {
                    { Set-TargetResource -Name $script:mockEnvironmentVarName1 `
                                         -Value ';' `
                                         -Ensure 'Absent' `
                                         -Path $true
                    } | Should Not Throw
                }

                It 'Should have called the correct mocks to not remove the environment variable' {
                    Assert-MockCalled Get-EnvironmentVariable -Exactly 2 -Scope Context
                    Assert-MockCalled Remove-EnvironmentVariable -Exactly 0 -Scope Context
                    Assert-MockCalled Test-PathInPathList -Exactly 0 -Scope Context
                }
            }

            Context 'Remove environment variable with Value set to value not in path and Path set to true' {
                Mock -CommandName Get-EnvironmentVariable -MockWith { return $script:mockEnvironmentVar1.PATH }
                Mock -CommandName Remove-EnvironmentVariable -MockWith {}
                Mock -CommandName Set-EnvironmentVariable -MockWith {}
                
                It 'Should not throw an exception' {
                    { Set-TargetResource -Name $script:mockEnvironmentVarName1 `
                                         -Value 'nonExistentPath' `
                                         -Ensure 'Absent' `
                                         -Path $true
                    } | Should Not Throw
                }

                It 'Should have called the correct mocks to not remove the environment variable' {
                    Assert-MockCalled Get-EnvironmentVariable -Exactly 2 -Scope Context
                    Assert-MockCalled Remove-EnvironmentVariable -Exactly 0 -Scope Context
                    Assert-MockCalled Set-EnvironmentVariable -Exactly 0 -Scope Context
                }
            }

            Context 'Remove environment variable with Value set to full path value that the environment var is already set to' {
                $pathToRemove = $script:mockEnvironmentVar1.PATH
                Mock -CommandName Get-EnvironmentVariable -MockWith { return $script:mockEnvironmentVar1.PATH }
                Mock -CommandName Remove-EnvironmentVariable -MockWith {}
                Mock -CommandName Set-EnvironmentVariable -MockWith {}
                
                It 'Should not throw an exception' {
                    { Set-TargetResource -Name $script:mockEnvironmentVarName1 `
                                         -Value $pathToRemove `
                                         -Ensure 'Absent' `
                                         -Path $true
                    } | Should Not Throw
                }

                It 'Should have called the correct mocks to remove the environment variable' {
                    Assert-MockCalled Get-EnvironmentVariable -Exactly 2 -Scope Context
                    Assert-MockCalled Remove-EnvironmentVariable -Exactly 2 -Scope Context
                    Assert-MockCalled Set-EnvironmentVariable -Exactly 0 -Scope Context
                }
            }

            Context 'Remove environment variable with Value set to a path value that the environment variable contains' {
                $script:mockEnvironmentVar1.PATH = 'path1;path2;path3;path4'
                $pathToRemove = 'path3'
                Mock -CommandName Get-EnvironmentVariable -MockWith { return $script:mockEnvironmentVar1.PATH }
                Mock -CommandName Remove-EnvironmentVariable -MockWith {}
                Mock -CommandName Set-EnvironmentVariable -MockWith {}
                
                It 'Should not throw an exception' {
                    { Set-TargetResource -Name $script:mockEnvironmentVarName1 `
                                         -Value $pathToRemove `
                                         -Ensure 'Absent' `
                                         -Path $true
                    } | Should Not Throw
                }

                It 'Should have called the correct mocks to set the environment variable' {
                    Assert-MockCalled Get-EnvironmentVariable -Exactly 2 -Scope Context
                    Assert-MockCalled Remove-EnvironmentVariable -Exactly 0 -Scope Context
                    Assert-MockCalled Set-EnvironmentVariable -Exactly 2 -Scope Context
                }
            }
        }

        Describe 'xEnvironmentResource\Test-TargetResource' {
            Context 'Ensure set to Present and environment variable not found' {
                Mock -CommandName Get-EnvironmentVariable -MockWith { return $null }
                Mock -CommandName Test-PathInPathListWithCriteria -MockWith { return $true }

                It 'Should return false' {
                    $testTargetResourceResult = Test-TargetResource -Name $script:mockEnvironmentVarName1 `
                                                                    -Ensure 'Present' `
                                                                    -Path $true
                    $testTargetResourceResult | Should Be $false
                }

                It 'Should have called the correct mocks' {
                    Assert-MockCalled Get-EnvironmentVariable -Exactly 2 -Scope Context
                    Assert-MockCalled Test-PathInPathListWithCriteria -Exactly 0 -Scope Context
                }
            }

            Context 'Ensure set to Present and value not specified' {
                Mock -CommandName Get-EnvironmentVariable -MockWith { return $script:mockEnvironmentVar1.PATH }
                Mock -CommandName Test-PathInPathListWithCriteria -MockWith { return $true }

                It 'Should return true' {
                    $testTargetResourceResult = Test-TargetResource -Name $script:mockEnvironmentVarName1 `
                                                                    -Ensure 'Present' `
                                                                    -Path $true
                    $testTargetResourceResult | Should Be $true
                }

                It 'Should have called the correct mocks' {
                    Assert-MockCalled Get-EnvironmentVariable -Exactly 2 -Scope Context
                    Assert-MockCalled Test-PathInPathListWithCriteria -Exactly 0 -Scope Context
                }
            }

            Context 'Ensure set to Present and Path set to false with incorrect value' {
                $expectedValue = 'wrongExpectedValue'
                Mock -CommandName Get-ItemPropertyExpanded -MockWith { return $script:mockEnvironmentVar1.PATH }
                Mock -CommandName Get-EnvironmentVariable -MockWith { return $script:mockEnvironmentVar1.PATH }
                Mock -CommandName Test-PathInPathListWithCriteria -MockWith { return $true }

                It 'Should return false' {
                    $testTargetResourceResult = Test-TargetResource -Name $script:mockEnvironmentVarName1 `
                                                                    -Value $expectedValue `
                                                                    -Ensure 'Present' `
                                                                    -Path $false
                    $testTargetResourceResult | Should Be $false
                }

                It 'Should have called the correct mocks' {
                    Assert-MockCalled Get-ItemPropertyExpanded -Exactly 1 -Scope Context
                    Assert-MockCalled Test-PathInPathListWithCriteria -Exactly 0 -Scope Context
                }
            }

            Context 'Ensure set to Present and Path set to false with correct value' {
                $expectedValue = $script:mockEnvironmentVar1.PATH
                Mock -CommandName Get-ItemPropertyExpanded -MockWith { return $script:mockEnvironmentVar1.PATH }
                Mock -CommandName Get-EnvironmentVariable -MockWith { return $script:mockEnvironmentVar1.PATH }
                Mock -CommandName Test-PathInPathListWithCriteria -MockWith { return $true }

                It 'Should return true' {
                    $testTargetResourceResult = Test-TargetResource -Name $script:mockEnvironmentVarName1 `
                                                                    -Value $expectedValue `
                                                                    -Ensure 'Present' `
                                                                    -Path $false
                    $testTargetResourceResult | Should Be $true
                }

                It 'Should have called the correct mocks' {
                    Assert-MockCalled Get-ItemPropertyExpanded -Exactly 1 -Scope Context
                    Assert-MockCalled Get-EnvironmentVariable -Exactly 1 -Scope Context
                    Assert-MockCalled Test-PathInPathListWithCriteria -Exactly 0 -Scope Context
                }
            }

            Context 'Ensure set to Present, Path set to true and Value contains all paths set in environment variable' {
                $expectedValue = $script:mockEnvironmentVar1.PATH
                Mock -CommandName Get-EnvironmentVariable -MockWith { return $script:mockEnvironmentVar1.PATH }

                It 'Should return true' {
                    $testTargetResourceResult = Test-TargetResource -Name $script:mockEnvironmentVarName1 `
                                                                    -Value $expectedValue `
                                                                    -Ensure 'Present' `
                                                                    -Path $true
                    $testTargetResourceResult | Should Be $true
                }

                It 'Should have called the correct mocks' {
                    Assert-MockCalled Get-EnvironmentVariable -Exactly 2 -Scope Context
                }
            }

            Context 'Ensure set to Present, Path set to true, and Value is set in environment variable' {
                $script:mockEnvironmentVar1.PATH = 'path1;path2;path3;path4'
                $expectedValue = 'path3;path2'
                Mock -CommandName Get-EnvironmentVariable -MockWith { return $script:mockEnvironmentVar1.PATH }

                It 'Should return true' {
                    $testTargetResourceResult = Test-TargetResource -Name $script:mockEnvironmentVarName1 `
                                                                    -Value $expectedValue `
                                                                    -Ensure 'Present' `
                                                                    -Path $true
                    $testTargetResourceResult | Should Be $true
                }

                It 'Should have called the correct mocks' {
                    Assert-MockCalled Get-EnvironmentVariable -Exactly 2 -Scope Context
                }
            }

            Context 'Ensure set to Present, Path set to true, and not all paths in Value are set in machine' {
                $script:mockEnvironmentVar1.PATH = 'path1;path2;path3;path4'
                $expectedValue = 'path3;path4;path5'
                Mock -CommandName Get-EnvironmentVariable -MockWith { return $script:mockEnvironmentVar1.PATH }

                It 'Should return false' {
                    $testTargetResourceResult = Test-TargetResource -Name $script:mockEnvironmentVarName1 `
                                                                    -Value $expectedValue `
                                                                    -Ensure 'Present' `
                                                                    -Path $true
                    $testTargetResourceResult | Should Be $false
                }

                It 'Should have called the correct mocks' {
                    Assert-MockCalled Get-EnvironmentVariable -Exactly 2 -Scope Context
                }
            }
            
            Context 'Ensure set to Present, Path set to true, and not all paths in Value are set in process' {
                $script:mockEnvironmentVar1.PATH = 'path1;path2;path3;path4'
                $expectedValue = 'path3;path4;path5'
                Mock -CommandName Get-EnvironmentVariable -MockWith {
                    if ($Target -eq $script:environmentVariableTarget.Machine)
                    {
                        return $expectedValue
                    }
                    else
                    {
                        return $script:mockEnvironmentVar1.PATH
                    }
                }

                It 'Should return false' {
                    $testTargetResourceResult = Test-TargetResource -Name $script:mockEnvironmentVarName1 `
                                                                    -Value $expectedValue `
                                                                    -Ensure 'Present' `
                                                                    -Path $true
                    $testTargetResourceResult | Should Be $false
                }

                It 'Should have called the correct mocks' {
                    Assert-MockCalled Get-EnvironmentVariable -Exactly 2 -Scope Context
                }
            }

            Context 'Ensure set to Absent and environment variable not found' {
                Mock -CommandName Get-EnvironmentVariable -MockWith { return $null }
                Mock -CommandName Test-PathInPathListWithCriteria -MockWith { return $true }

                It 'Should return true' {
                    $testTargetResourceResult = Test-TargetResource -Name $script:mockEnvironmentVarName1 `
                                                                    -Ensure 'Absent' `
                                                                    -Path $true
                    $testTargetResourceResult | Should Be $true
                }

                It 'Should have called the correct mocks' {
                    Assert-MockCalled Get-EnvironmentVariable -Exactly 2 -Scope Context
                    Assert-MockCalled Test-PathInPathListWithCriteria -Exactly 0 -Scope Context
                }
            }
            
            Context 'Ensure set to Absent and value not specified' {
                Mock -CommandName Get-EnvironmentVariable -MockWith { return $script:mockEnvironmentVar1.PATH }
                Mock -CommandName Test-PathInPathListWithCriteria -MockWith { return $true }

                It 'Should return false' {
                    $testTargetResourceResult = Test-TargetResource -Name $script:mockEnvironmentVarName1 `
                                                                    -Ensure 'Absent' `
                                                                    -Path $true
                    $testTargetResourceResult | Should Be $false
                }

                It 'Should have called the correct mocks' {
                    Assert-MockCalled Get-EnvironmentVariable -Exactly 2 -Scope Context
                    Assert-MockCalled Test-PathInPathListWithCriteria -Exactly 0 -Scope Context
                }
            }
            
            Context 'Ensure set to Absent and Path set to false with non-existent value' {
                $expectedValue = 'nonExistentExpectedValue'
                Mock -CommandName Get-ItemPropertyExpanded -MockWith { return $script:mockEnvironmentVar1.PATH }
                Mock -CommandName Get-EnvironmentVariable -MockWith { return $script:mockEnvironmentVar1.PATH }
                Mock -CommandName Test-PathInPathListWithCriteria -MockWith { return $true }

                It 'Should return true' {
                    $testTargetResourceResult = Test-TargetResource -Name $script:mockEnvironmentVarName1 `
                                                                    -Value $expectedValue `
                                                                    -Ensure 'Absent' `
                                                                    -Path $false
                    $testTargetResourceResult | Should Be $true
                }

                It 'Should have called the correct mocks' {
                    Assert-MockCalled Get-ItemPropertyExpanded -Exactly 1 -Scope Context
                    Assert-MockCalled Get-EnvironmentVariable -Exactly 1 -Scope Context
                    Assert-MockCalled Test-PathInPathListWithCriteria -Exactly 0 -Scope Context
                }
            }

            Context 'Ensure set to Absent and Path set to false with existent value' {
                $expectedValue = $script:mockEnvironmentVar1.PATH
                Mock -CommandName Get-ItemPropertyExpanded -MockWith { return $script:mockEnvironmentVar1.PATH }
                Mock -CommandName Get-EnvironmentVariable -MockWith { return $script:mockEnvironmentVar1.PATH }
                Mock -CommandName Test-PathInPathListWithCriteria -MockWith { return $true }

                It 'Should return false' {
                    $testTargetResourceResult = Test-TargetResource -Name $script:mockEnvironmentVarName1 `
                                                                    -Value $expectedValue `
                                                                    -Ensure 'Absent' `
                                                                    -Path $false
                    $testTargetResourceResult | Should Be $false
                }

                It 'Should have called the correct mocks' {
                    Assert-MockCalled Get-ItemPropertyExpanded -Exactly 1 -Scope Context
                    Assert-MockCalled Get-EnvironmentVariable -Exactly 1 -Scope Context
                    Assert-MockCalled Test-PathInPathListWithCriteria -Exactly 0 -Scope Context
                }
            }

            Context 'Ensure set to Absent, Path set to true, and Value is set in machine environment variable' {
                Mock -CommandName Get-EnvironmentVariable -MockWith { return $script:mockEnvironmentVar1.PATH }
                Mock -CommandName Test-PathInPathListWithCriteria -MockWith { return $true }
                
                It 'Should return false' {
                    $testTargetResourceResult = Test-TargetResource -Name $script:mockEnvironmentVarName1 `
                                                                    -Value 'existentValue' `
                                                                    -Ensure 'Absent' `
                                                                    -Path $true
                    $testTargetResourceResult | Should Be $false
                }

                It 'Should have called the correct mocks' {
                    Assert-MockCalled Get-EnvironmentVariable -Exactly 2 -Scope Context
                    Assert-MockCalled Test-PathInPathListWithCriteria -Exactly 1 -Scope Context                    
                }
            }

            Context 'Ensure set to Present, Path set to true, and none of the paths in Value are set in environment variable' {
                Mock -CommandName Get-EnvironmentVariable -MockWith { return $script:mockEnvironmentVar1.PATH }
                Mock -CommandName Test-PathInPathListWithCriteria -MockWith { return $false }

                It 'Should return true' {
                    $testTargetResourceResult = Test-TargetResource -Name $script:mockEnvironmentVarName1 `
                                                                    -Value 'nonExistentValue' `
                                                                    -Ensure 'Absent' `
                                                                    -Path $true
                    $testTargetResourceResult | Should Be $true
                }

                It 'Should have called the correct mocks' {
                    Assert-MockCalled Get-EnvironmentVariable -Exactly 2 -Scope Context
                    Assert-MockCalled Test-PathInPathListWithCriteria -Exactly 2 -Scope Context
                }
            }
            
            Context 'Ensure set to Present, Path set to true, and Value is set in process environment variable' {
                $script:mockEnvironmentVar1.PATH = 'path1;path2;path3;path4'
                $nonExistentValue = 'path5;path6;path7'
                Mock -CommandName Get-EnvironmentVariable -MockWith {
                    if ($Target -eq $script:environmentVariableTarget.Machine)
                    {
                        return $script:mockEnvironmentVar1.PATH
                    }
                    else
                    {
                        return $nonExistentValue
                    }
                }

                It 'Should return false' {
                    $testTargetResourceResult = Test-TargetResource -Name $script:mockEnvironmentVarName1 `
                                                                    -Value $nonExistentValue `
                                                                    -Ensure 'Absent' `
                                                                    -Path $true
                    $testTargetResourceResult | Should Be $false
                }

                It 'Should have called the correct mocks' {
                    Assert-MockCalled Get-EnvironmentVariable -Exactly 2 -Scope Context
                }
            }
        }

        Describe 'xEnvironmentResource\Get-EnvironmentVariable' {
        }

        Describe 'xEnvironmentResource\Set-EnvironmentVariable' {
        }

        Describe 'xEnvironmentResource\Set-EnvironmentVariable' {
        }

        Describe 'xEnvironmentResource\Remove-EnvironmentVariable' {
        }

        Describe 'xEnvironmentResource\Test-PathInPathListWithCriteria' {
        }

        Describe 'xEnvironmentResource\Test-PathInPathList' {
        }

        Describe 'xEnvironmentResource\Get-ItemPropertyExpanded' {
        }
    }
}
finally
{
    Exit-DscResourceTestEnvironment -TestEnvironment $script:testEnvironment
}

