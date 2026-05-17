# SmplkitGeneratedClient::Audit::EventSearchListLinks

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **_next** | **String** | Opaque cursor token for the next page. POST the same body with &#x60;page[after]&#x60; set to this value to fetch the next page. Unlike the URL-form &#x60;links.next&#x60; returned by &#x60;GET /api/v1/events&#x60;, this is a bare cursor token — the client must re-issue a POST with its body, which the URL form cannot capture. | [optional] |

## Example

```ruby
require 'smplkit_audit_client'

instance = SmplkitGeneratedClient::Audit::EventSearchListLinks.new(
  _next: null
)
```

