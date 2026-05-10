# SmplkitGeneratedClient::Audit::Forwarder

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** |  |  |
| **forwarder_type** | [**ForwarderType**](ForwarderType.md) |  |  |
| **enabled** | **Boolean** |  | [optional][default to true] |
| **filter** | **Hash&lt;String, Object&gt;** |  | [optional] |
| **transform** | **String** |  | [optional] |
| **http** | [**ForwarderHttp**](ForwarderHttp.md) |  |  |
| **slug** | **String** |  | [optional] |
| **created_at** | **Time** |  | [optional][readonly] |
| **updated_at** | **Time** |  | [optional][readonly] |
| **deleted_at** | **Time** |  | [optional][readonly] |
| **version** | **Integer** |  | [optional][readonly] |
| **data** | **Hash&lt;String, Object&gt;** |  | [optional] |

## Example

```ruby
require 'smplkit_audit_client'

instance = SmplkitGeneratedClient::Audit::Forwarder.new(
  name: null,
  forwarder_type: null,
  enabled: null,
  filter: null,
  transform: null,
  http: null,
  slug: null,
  created_at: null,
  updated_at: null,
  deleted_at: null,
  version: null,
  data: null
)
```

