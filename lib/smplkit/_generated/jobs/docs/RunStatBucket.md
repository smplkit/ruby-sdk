# SmplkitGeneratedClient::Jobs::RunStatBucket

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **bucket** | **Time** | Start of the bucket (UTC). Buckets are aligned to the epoch — e.g. &#x60;1h&#x60; buckets start on the hour. |  |
| **count** | **Integer** | Runs created within this bucket. |  |

## Example

```ruby
require 'smplkit_jobs_client'

instance = SmplkitGeneratedClient::Jobs::RunStatBucket.new(
  bucket: null,
  count: null
)
```

