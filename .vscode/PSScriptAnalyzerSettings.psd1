@{
    # Include default rules and custom rules
    IncludeDefaultRules = $true
    
    # Custom rule settings
    Rules = @{
        # Security rules
        PSAvoidUsingInvokeExpression = @{
            Enable = $true
            Severity = 'Error'
        }
        
        PSAvoidUsingWriteHost = @{
            Enable = $true
            Severity = 'Warning'
        }
        
        PSAvoidUsingPlainTextForPassword = @{
            Enable = $true
            Severity = 'Error'
        }
        
        PSAvoidUsingConvertToSecureStringWithPlainText = @{
            Enable = $true
            Severity = 'Error'
        }
        
        PSAvoidUsingUsernameAndPasswordParams = @{
            Enable = $true
            Severity = 'Warning'
        }
        
        PSAvoidUsingEmptyCatchBlock = @{
            Enable = $true
            Severity = 'Warning'
        }
        
        PSAvoidUsingPositionalParameters = @{
            Enable = $true
            Severity = 'Warning'
        }
        
        PSAvoidUsingWMICmdlet = @{
            Enable = $true
            Severity = 'Warning'
        }
        
        PSAvoidUsingDeprecatedManifestFields = @{
            Enable = $true
            Severity = 'Warning'
        }
        
        # Code quality rules
        PSUseApprovedVerbs = @{
            Enable = $true
            Severity = 'Warning'
        }
        
        PSReservedCmdletChar = @{
            Enable = $true
            Severity = 'Error'
        }
        
        PSReservedParams = @{
            Enable = $true
            Severity = 'Error'
        }
        
        PSMissingModuleManifestField = @{
            Enable = $true
            Severity = 'Warning'
        }
        
        PSUseDeclaredVarsMoreThanAssignments = @{
            Enable = $true
            Severity = 'Warning'
        }
        
        PSUseShouldProcessForStateChangingFunctions = @{
            Enable = $true
            Severity = 'Warning'
        }
        
        PSUseSingularNouns = @{
            Enable = $true
            Severity = 'Warning'
        }
        
        PSUseSupportsShouldProcess = @{
            Enable = $true
            Severity = 'Warning'
        }
        
        PSUseToExportFieldsInManifest = @{
            Enable = $true
            Severity = 'Warning'
        }
        
        PSUseUTF8EncodingForHelpFile = @{
            Enable = $true
            Severity = 'Warning'
        }
        
        # Performance rules
        PSAvoidAssignmentToAutomaticVariable = @{
            Enable = $true
            Severity = 'Error'
        }
        
        PSAvoidGlobalVars = @{
            Enable = $true
            Severity = 'Warning'
        }
        
        PSAvoidUsingAliases = @{
            Enable = $true
            Severity = 'Warning'
        }
        
        PSAvoidUsingBrokenHashAlgorithms = @{
            Enable = $true
            Severity = 'Error'
        }
        
        PSAvoidUsingCmdletAliases = @{
            Enable = $true
            Severity = 'Warning'
        }
        
        PSAvoidUsingDoubleQuotesForConstantString = @{
            Enable = $true
            Severity = 'Information'
        }
        
        # Style rules
        PSAlignAssignmentStatement = @{
            Enable = $true
            Severity = 'Information'
        }
        
        PSAvoidLongLines = @{
            Enable = $true
            Severity = 'Warning'
            MaximumLineLength = 120
        }
        
        PSAvoidTrailingWhitespace = @{
            Enable = $true
            Severity = 'Warning'
        }
        
        PSProvideCommentHelp = @{
            Enable = $true
            Severity = 'Warning'
            ExcludeRules = @('PSProvideCommentHelpForAdvancedFunctions')
        }
        
        PSProvideDefaultParameterValue = @{
            Enable = $true
            Severity = 'Information'
        }
        
        PSProvideVerboseMessage = @{
            Enable = $true
            Severity = 'Information'
        }
        
        PSRequireInputAttribute = @{
            Enable = $true
            Severity = 'Warning'
        }
        
        PSRequireOutputAttribute = @{
            Enable = $true
            Severity = 'Warning'
        }
        
        PSRequireValidPath = @{
            Enable = $true
            Severity = 'Warning'
        }
        
        PSShouldProcess = @{
            Enable = $true
            Severity = 'Warning'
        }
        
        PSUseBOMForUnicodeEncodedFile = @{
            Enable = $true
            Severity = 'Information'
        }
        
        PSUseCmdletCorrectly = @{
            Enable = $true
            Severity = 'Warning'
        }
        
        PSUseCompatibleCommands = @{
            Enable = $true
            Severity = 'Warning'
        }
        
        PSUseCompatibleSyntax = @{
            Enable = $true
            Severity = 'Warning'
        }
        
        PSUseConsistentIndentation = @{
            Enable = $true
            Severity = 'Information'
            IndentationSize = 4
            Kind = 'Space'
        }
        
        PSUseConsistentWhitespace = @{
            Enable = $true
            Severity = 'Information'
        }
        
        PSUseCorrectCasing = @{
            Enable = $true
            Severity = 'Information'
        }
        
        PSUseLiteralInitializerForHashtable = @{
            Enable = $true
            Severity = 'Information'
        }
        
        PSUseProcessBlockForPipelineCommand = @{
            Enable = $true
            Severity = 'Information'
        }
    }
} 