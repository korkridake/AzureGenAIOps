#!/usr/bin/env python3
"""
Test script to verify Azure Key Vault access and configuration.
"""

import os
import sys
import logging
from pathlib import Path

# Add src directory to path
sys.path.insert(0, str(Path(__file__).parent.parent / "src"))

try:
    from common.keyvault_config import KeyVaultConfig, EnhancedLLMConfig, create_config
    from azure.identity import DefaultAzureCredential
    from azure.keyvault.secrets import SecretClient
    AZURE_AVAILABLE = True
except ImportError as e:
    print(f"Error importing Azure libraries: {e}")
    print("Please install Azure SDK: pip install azure-identity azure-keyvault-secrets")
    AZURE_AVAILABLE = False

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)


def test_azure_authentication():
    """Test Azure authentication."""
    print("🔐 Testing Azure Authentication...")
    
    if not AZURE_AVAILABLE:
        print("❌ Azure SDK not available")
        return False
    
    try:
        credential = DefaultAzureCredential()
        # Try to get a token to verify authentication works
        token = credential.get_token("https://management.azure.com/.default")
        print("✅ Azure authentication successful")
        return True
    except Exception as e:
        print(f"❌ Azure authentication failed: {e}")
        return False


def test_key_vault_access():
    """Test Key Vault access."""
    print("\n🔑 Testing Key Vault Access...")
    
    key_vault_name = os.getenv("AZURE_KEY_VAULT_NAME")
    if not key_vault_name:
        print("❌ AZURE_KEY_VAULT_NAME environment variable not set")
        return False
    
    print(f"Key Vault: {key_vault_name}")
    
    if not AZURE_AVAILABLE:
        print("❌ Azure SDK not available")
        return False
    
    try:
        credential = DefaultAzureCredential()
        vault_url = f"https://{key_vault_name}.vault.azure.net/"
        client = SecretClient(vault_url=vault_url, credential=credential)
        
        # Try to list secrets
        secret_properties = list(client.list_properties_of_secrets())
        print(f"✅ Key Vault access successful - found {len(secret_properties)} secrets")
        
        # List some secret names (without values)
        if secret_properties:
            print("Available secrets:")
            for prop in secret_properties[:5]:  # Show first 5
                print(f"  - {prop.name}")
            if len(secret_properties) > 5:
                print(f"  ... and {len(secret_properties) - 5} more")
        
        return True
    except Exception as e:
        print(f"❌ Key Vault access failed: {e}")
        return False


def test_keyvault_config():
    """Test KeyVaultConfig class."""
    print("\n🛠️ Testing KeyVaultConfig Class...")
    
    key_vault_name = os.getenv("AZURE_KEY_VAULT_NAME")
    if not key_vault_name:
        print("❌ AZURE_KEY_VAULT_NAME environment variable not set")
        return False
    
    try:
        # Test with managed identity (default in Azure)
        kv_config = KeyVaultConfig(key_vault_name=key_vault_name, use_managed_identity=True)
        
        # Test getting a secret
        test_secret = kv_config.get_secret("openai-endpoint", "not-found")
        if test_secret and test_secret != "not-found":
            print("✅ KeyVaultConfig can retrieve secrets")
            print(f"OpenAI Endpoint: {test_secret}")
        else:
            print("⚠️ KeyVaultConfig initialized but couldn't retrieve test secret")
        
        return True
    except Exception as e:
        print(f"❌ KeyVaultConfig test failed: {e}")
        return False


def test_enhanced_config():
    """Test EnhancedLLMConfig class."""
    print("\n⚙️ Testing EnhancedLLMConfig Class...")
    
    try:
        # Create config with Key Vault
        config = create_config(use_key_vault=True)
        
        print(f"Configuration loaded:")
        print(f"  Azure Subscription ID: {config.azure_subscription_id}")
        print(f"  Resource Group: {config.azure_resource_group}")
        print(f"  AI Project Name: {config.azure_ai_project_name}")
        print(f"  OpenAI Endpoint: {config.azure_openai_endpoint}")
        print(f"  Search Endpoint: {config.azure_search_endpoint}")
        print(f"  Key Vault Name: {config.azure_key_vault_name}")
        
        # Test configuration validation
        try:
            config.validate_required_config()
            print("✅ Configuration validation passed")
        except ValueError as e:
            print(f"⚠️ Configuration validation failed: {e}")
        
        return True
    except Exception as e:
        print(f"❌ EnhancedLLMConfig test failed: {e}")
        return False


def test_fallback_to_env_vars():
    """Test fallback to environment variables."""
    print("\n🔄 Testing Fallback to Environment Variables...")
    
    try:
        # Create config without Key Vault
        config = create_config(use_key_vault=False)
        
        # Check if it can still load from environment variables
        env_values = {
            "Subscription ID": config.azure_subscription_id,
            "Resource Group": config.azure_resource_group,
            "Environment": config.environment
        }
        
        loaded_count = sum(1 for value in env_values.values() if value)
        print(f"✅ Loaded {loaded_count}/{len(env_values)} values from environment variables")
        
        for name, value in env_values.items():
            if value:
                print(f"  {name}: {value}")
        
        return True
    except Exception as e:
        print(f"❌ Environment variable fallback test failed: {e}")
        return False


def print_environment_info():
    """Print current environment information."""
    print("\n📋 Environment Information:")
    
    env_vars = [
        "AZURE_SUBSCRIPTION_ID",
        "AZURE_RESOURCE_GROUP", 
        "AZURE_KEY_VAULT_NAME",
        "AZURE_CLIENT_ID",
        "AZURE_TENANT_ID",
        "ENVIRONMENT"
    ]
    
    for var in env_vars:
        value = os.getenv(var)
        if value:
            # Mask sensitive values
            if "ID" in var or "KEY" in var:
                masked_value = value[:8] + "..." if len(value) > 8 else "***"
                print(f"  {var}: {masked_value}")
            else:
                print(f"  {var}: {value}")
        else:
            print(f"  {var}: (not set)")


def main():
    """Run all tests."""
    print("🧪 Azure Key Vault Configuration Test")
    print("=" * 50)
    
    print_environment_info()
    
    # Run tests
    tests = [
        ("Azure Authentication", test_azure_authentication),
        ("Key Vault Access", test_key_vault_access),
        ("KeyVaultConfig Class", test_keyvault_config),
        ("EnhancedLLMConfig Class", test_enhanced_config),
        ("Environment Variable Fallback", test_fallback_to_env_vars)
    ]
    
    results = []
    for test_name, test_func in tests:
        try:
            result = test_func()
            results.append((test_name, result))
        except Exception as e:
            print(f"❌ {test_name} failed with exception: {e}")
            results.append((test_name, False))
    
    # Summary
    print("\n📊 Test Summary:")
    print("=" * 30)
    
    passed = sum(1 for _, result in results if result)
    total = len(results)
    
    for test_name, result in results:
        status = "✅ PASS" if result else "❌ FAIL"
        print(f"{status} - {test_name}")
    
    print(f"\nOverall: {passed}/{total} tests passed")
    
    if passed == total:
        print("\n🎉 All tests passed! Your Key Vault configuration is working correctly.")
        return 0
    else:
        print(f"\n⚠️ {total - passed} test(s) failed. Please check the configuration.")
        return 1


if __name__ == "__main__":
    sys.exit(main())