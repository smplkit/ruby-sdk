# SmplkitGeneratedClient::Logging::Logger

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Human-readable label for the logger. |  |
| **level** | **String** | Account-wide log level applied to this logger. &#x60;null&#x60; means no override at the logger level — the level is inherited from the logger&#39;s group or the framework default. | [optional] |
| **group** | **String** | Key of the log group this logger belongs to, or &#x60;null&#x60; if the logger is not grouped. Assigning a logger to a group promotes it to managed; assigning a group cascades to unmanaged descendants by clearing their group reference. | [optional] |
| **managed** | **Boolean** | When &#x60;true&#x60;, the logger is part of the account&#39;s managed configuration and counts toward the managed-loggers usage counter. Setting &#x60;level&#x60;, &#x60;group&#x60;, or &#x60;environments&#x60; on an unmanaged logger promotes it to managed automatically. | [optional] |
| **sources** | **Array&lt;Hash&lt;String, Object&gt;&gt;** | Service / environment observations reported by SDKs for this logger. Each entry carries the service name, environment, the level the SDK saw, the resolved level after framework inheritance, and timestamps for the first and most recent sighting. | [optional][readonly] |
| **environments** | **Hash&lt;String, Object&gt;** | Per-environment level overrides keyed by environment name. Each value is an object with an optional &#x60;level&#x60; field, e.g. &#x60;{\&quot;production\&quot;: {\&quot;level\&quot;: \&quot;WARN\&quot;}}&#x60;. An environment may be present with no &#x60;level&#x60; to record that the logger applies there without changing the resolved level. | [optional] |
| **effective_levels** | **Hash&lt;String, Object&gt;** | Per-environment summary of what runtimes are reporting for this logger. Keyed by environment name; each entry is one of &#x60;{\&quot;status\&quot;: \&quot;none\&quot;}&#x60;, &#x60;{\&quot;status\&quot;: \&quot;agrees\&quot;, \&quot;level\&quot;: \&quot;&lt;LEVEL&gt;\&quot;}&#x60;, or &#x60;{\&quot;status\&quot;: \&quot;varies\&quot;}&#x60;. &#x60;agrees&#x60; means every observed source in that environment reports the same resolved level; &#x60;varies&#x60; means at least two sources disagree. | [optional][readonly] |
| **created_at** | **Time** | When the logger was first created or discovered. | [optional][readonly] |
| **updated_at** | **Time** | When the logger was last modified. | [optional][readonly] |

## Example

```ruby
require 'smplkit_logging_client'

instance = SmplkitGeneratedClient::Logging::Logger.new(
  name: null,
  level: null,
  group: null,
  managed: null,
  sources: null,
  environments: null,
  effective_levels: null,
  created_at: null,
  updated_at: null
)
```

