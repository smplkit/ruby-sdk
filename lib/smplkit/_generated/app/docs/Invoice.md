# SmplkitGeneratedClient::App::Invoice

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **number** | **String** | Invoice number assigned by the billing provider. |  |
| **status** | **String** | Invoice lifecycle state, e.g. &#x60;draft&#x60;, &#x60;open&#x60;, &#x60;paid&#x60;, &#x60;uncollectible&#x60;, &#x60;void&#x60;. |  |
| **amount_due** | **Integer** | Amount owed on the invoice in the smallest currency unit (e.g. cents). |  |
| **amount_paid** | **Integer** | Amount paid against the invoice in the smallest currency unit. |  |
| **currency** | **String** | ISO 4217 currency code, e.g. &#x60;usd&#x60;. |  |
| **description** | **String** | Human-readable summary of the invoice&#39;s line items. |  |
| **period_start** | **String** | Start of the service period the invoice covers (ISO 8601). |  |
| **period_end** | **String** | End of the service period the invoice covers (ISO 8601). |  |
| **created_at** | **String** | When the invoice was created (ISO 8601). |  |
| **paid_at** | **String** | When the invoice was paid in full (ISO 8601), or &#x60;null&#x60; if unpaid. |  |
| **hosted_invoice_url** | **String** | Link to the hosted invoice page. |  |
| **invoice_pdf** | **String** | Link to the PDF rendering of the invoice. |  |

## Example

```ruby
require 'smplkit_app_client'

instance = SmplkitGeneratedClient::App::Invoice.new(
  number: null,
  status: null,
  amount_due: null,
  amount_paid: null,
  currency: null,
  description: null,
  period_start: null,
  period_end: null,
  created_at: null,
  paid_at: null,
  hosted_invoice_url: null,
  invoice_pdf: null
)
```

