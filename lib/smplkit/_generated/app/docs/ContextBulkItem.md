# SmplkitGeneratedClient::App::ContextBulkItem

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **type** | **String** | Key of the context type this instance belongs to (e.g. &#x60;user&#x60;, &#x60;account&#x60;, &#x60;device&#x60;). |  |
| **key** | **String** | Entity identifier within the context type, e.g. &#x60;user-123&#x60;. |  |
| **attributes** | **Hash&lt;String, Object&gt;** | Observed attribute values for this context instance. | [optional] |

## Example

```ruby
require 'smplkit_app_client'

instance = SmplkitGeneratedClient::App::ContextBulkItem.new(
  type: null,
  key: null,
  attributes: null
)
```

