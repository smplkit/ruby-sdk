# SmplkitGeneratedClient::App::ApiKey

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Human-readable name for the key. |  |
| **kind** | **String** | Credential class of the key, set at creation and immutable. &#x60;PRIVATE&#x60; (the default) keys carry full API access and must be kept secret — never expose one in a browser or client application. &#x60;PUBLIC&#x60; keys are browser-safe, read-only credentials for reading feature flags and configuration from client-side code; they must be scoped to exactly one environment with &#x60;permissions: [\&quot;read\&quot;]&#x60;. Accepted case-insensitively. | [optional][default to &#39;PRIVATE&#39;] |
| **status** | **String** | Lifecycle state of the key. &#x60;ACTIVE&#x60; keys may be used to authenticate; &#x60;REVOKED&#x60; keys are rejected. | [optional][readonly] |
| **key** | **String** | The bearer token value. Returned in plaintext on the create response so the caller can capture it; subsequent reads return the same value for round-tripping. | [optional][readonly] |
| **scopes** | **Hash&lt;String, Object&gt;** | Scope restrictions applied to the key, as a JSON object mapping dimension names to arrays of allowed values. An empty object (the default) grants unrestricted access. The &#x60;environments&#x60; dimension lists the environment keys the key may operate in (for example &#x60;{\&quot;environments\&quot;: [\&quot;production\&quot;]}&#x60;); a request&#39;s environment must be one of them. A dimension that is absent or set to an empty array is unrestricted in that dimension. | [optional] |
| **created_by** | **String** | UUID of the user who created the key. | [optional][readonly] |
| **expires_at** | **Time** | Optional expiry timestamp. After this time, the key is rejected. Omit for keys that do not expire. | [optional] |
| **last_used_at** | **Time** | When the key was most recently used to authenticate. | [optional][readonly] |
| **created_at** | **Time** | When the key was created. | [optional][readonly] |
| **updated_at** | **Time** | When the key was last modified. | [optional][readonly] |

## Example

```ruby
require 'smplkit_app_client'

instance = SmplkitGeneratedClient::App::ApiKey.new(
  name: null,
  kind: null,
  status: null,
  key: null,
  scopes: {&quot;environments&quot;:[&quot;production&quot;]},
  created_by: null,
  expires_at: null,
  last_used_at: null,
  created_at: null,
  updated_at: null
)
```

