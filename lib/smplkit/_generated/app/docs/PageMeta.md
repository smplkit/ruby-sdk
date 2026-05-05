# SmplkitGeneratedClient::App::PageMeta

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **size** | **Integer** | Page size used for this response |  |
| **number** | **Integer** | 1-based page number returned |  |
| **total_items** | **Integer** | Total number of matching items across all pages |  |
| **total_pages** | **Integer** | Total number of pages at the current page size |  |

## Example

```ruby
require 'smplkit_app_client'

instance = SmplkitGeneratedClient::App::PageMeta.new(
  size: null,
  number: null,
  total_items: null,
  total_pages: null
)
```

