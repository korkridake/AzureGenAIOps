# GitHub Actions Workflow Fixes

This document explains the fixes applied to resolve GitHub Actions workflow issues.

## Issues Fixed

### 1. Package Dependency Issue

**Problem:** The `azure-cognitiveservices-language-textanalytics>=5.3.0` package in `requirements.txt` could not be installed because the maximum available version is 0.2.2.

**Solution:** Replaced with the modern Azure SDK package `azure-ai-textanalytics>=5.3.0` which has version 5.3.0 available.

**Files Changed:**
- `requirements.txt`: Line 13 updated

### 2. workflow_dispatch Input Limit Issue

**Problem:** The `infrastructure.yml` workflow had 11 inputs in the `workflow_dispatch` section, exceeding GitHub Actions' limit of 10 inputs.

**Solution:** Consolidated the 5 existing resource parameters into a single JSON parameter `existing_resources`.

**Before (11 inputs):**
- deployment_type
- environment
- resource_group
- location
- project_name
- existing_ai_foundry
- existing_openai
- existing_search
- existing_storage
- existing_keyvault
- whatif

**After (7 inputs):**
- deployment_type
- environment
- resource_group
- location
- project_name
- existing_resources (JSON format)
- whatif

**JSON Format for existing_resources:**
```json
{
  "ai_foundry": "my-ai-foundry-project",
  "openai": "my-openai-service",
  "search": "my-search-service", 
  "storage": "mystorageaccount",
  "keyvault": "my-keyvault"
}
```

**Files Changed:**
- `.github/workflows/infrastructure.yml`: 
  - Lines 37-57: Consolidated inputs
  - Lines 251-284: Added JSON parsing step
  - Lines 285-336: Updated deployment step to use parsed values

## Testing

Both fixes have been validated:
- YAML syntax validation passed
- Input count reduced from 11 to 7 (within the 10-input limit)
- Package availability confirmed via PyPI API

## Impact

These changes ensure that:
1. GitHub Actions can successfully install Python dependencies
2. The infrastructure workflow can be triggered without input limit errors
3. All existing functionality is preserved with minimal code changes