# SmplkitGeneratedClient::Config::ConfigBulkItem

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **id** | **String** | Config key as declared in code. URL-safe and stable for the lifetime of the config. |  |
| **name** | **String** | Display name. Defaults to a humanized version of the &#x60;id&#x60; when omitted. | [optional] |
| **description** | **String** | Optional human-readable description of the config. | [optional] |
| **parent** | **String** | Parent config key. Used only when creating a new (discovered) config. Ignored on subsequent observations of an existing config — discovery never modifies parent on a config that already exists. | [optional] |
| **items** | [**Hash&lt;String, ConfigItemDefinition&gt;**](ConfigItemDefinition.md) | Items declared by the SDK with their types, defaults, and descriptions. Used to populate items on a newly-discovered config; ignored on subsequent observations of an existing config. | [optional] |
| **service** | **String** | Service reporting the declaration. Defaults to &#x60;unknown&#x60;. | [optional] |
| **environment** | **String** | Environment reporting the declaration. Defaults to &#x60;unknown&#x60;. | [optional] |

## Example

```ruby
require 'smplkit_config_client'

instance = SmplkitGeneratedClient::Config::ConfigBulkItem.new(
  id: null,
  name: null,
  description: null,
  parent: null,
  items: null,
  service: null,
  environment: null
)
```

