# SmplkitGeneratedClient::Jobs::JobCreateResource

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **id** | **String** | Client-supplied resource id. |  |
| **type** | **String** |  | [optional][default to &#39;job&#39;] |
| **attributes** | [**Job**](Job.md) |  |  |

## Example

```ruby
require 'smplkit_jobs_client'

instance = SmplkitGeneratedClient::Jobs::JobCreateResource.new(
  id: null,
  type: null,
  attributes: null
)
```

