# SmplkitGeneratedClient::Config::PaginationMeta

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **page** | **Integer** | 1-based page number returned. |  |
| **size** | **Integer** | Number of items per page. |  |
| **total** | **Integer** | Total number of matching items across all pages. Present only when the request included &#x60;meta[total]&#x3D;true&#x60;. | [optional] |
| **total_pages** | **Integer** | Total number of pages at the requested page size. Present only when the request included &#x60;meta[total]&#x3D;true&#x60;. | [optional] |

## Example

```ruby
require 'smplkit_config_client'

instance = SmplkitGeneratedClient::Config::PaginationMeta.new(
  page: null,
  size: null,
  total: null,
  total_pages: null
)
```

