# SmplkitGeneratedClient::App::Account

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Human-readable name for the account. |  |
| **key** | **String** | Stable URL-safe identifier for the account, derived from the account name at creation. Used in console URLs and other places that prefer a human-readable handle. | [optional][readonly] |
| **has_stripe_customer** | **Boolean** | &#x60;true&#x60; once the account has been linked to a billing provider customer record. | [optional][readonly][default to false] |
| **expires_at** | **Time** | When the account is scheduled to expire. &#x60;null&#x60; for accounts with no expiry. | [optional][readonly] |
| **created_at** | **Time** | When the account was created. | [optional][readonly] |
| **deleted_at** | **Time** | When the account was deleted. &#x60;null&#x60; for active accounts. | [optional][readonly] |
| **product_subscriptions** | **Hash&lt;String, Object&gt;** | Map of product key to the account&#39;s subscription summary for that product, including plan, status, and entitlement limits. | [optional][readonly] |
| **entry_point** | **String** | How the account first reached smplkit (e.g. &#x60;LOGIN&#x60;, &#x60;GET_STARTED&#x60;, &#x60;LIVE_DEMO&#x60;). | [optional][readonly] |
| **show_sample_data** | **Boolean** | Whether the account is currently configured to display the sample dataset alongside the customer&#39;s own resources. | [optional][readonly] |
| **discount_override_pct** | **Integer** | Custom discount percentage applied to the account in place of the volume-based discount schedule. &#x60;null&#x60; means the volume schedule applies. | [optional][readonly] |
| **discount_override_reason** | **String** | Free-form note explaining why the override was set. | [optional][readonly] |
| **discount_override_set_by_user_id** | **String** | UUID of the user who set the override. | [optional][readonly] |
| **discount_override_set_at** | **Time** | When the override was last changed. | [optional][readonly] |

## Example

```ruby
require 'smplkit_app_client'

instance = SmplkitGeneratedClient::App::Account.new(
  name: null,
  key: null,
  has_stripe_customer: null,
  expires_at: null,
  created_at: null,
  deleted_at: null,
  product_subscriptions: null,
  entry_point: null,
  show_sample_data: null,
  discount_override_pct: null,
  discount_override_reason: null,
  discount_override_set_by_user_id: null,
  discount_override_set_at: null
)
```

