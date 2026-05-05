# SmplkitGeneratedClient::App::ApiKey

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** |  |  |
| **status** | **String** |  | [optional][readonly] |
| **key** | **String** |  | [optional][readonly] |
| **scopes** | **Hash&lt;String, Object&gt;** |  | [optional] |
| **created_by** | **String** |  | [optional][readonly] |
| **expires_at** | **Time** |  | [optional] |
| **last_used_at** | **Time** |  | [optional][readonly] |
| **created_at** | **Time** |  | [optional][readonly] |
| **updated_at** | **Time** |  | [optional][readonly] |
| **data** | **Hash&lt;String, Object&gt;** |  | [optional][readonly] |

## Example

```ruby
require 'smplkit_app_client'

instance = SmplkitGeneratedClient::App::ApiKey.new(
  name: null,
  status: null,
  key: null,
  scopes: null,
  created_by: null,
  expires_at: null,
  last_used_at: null,
  created_at: null,
  updated_at: null,
  data: null
)
```

