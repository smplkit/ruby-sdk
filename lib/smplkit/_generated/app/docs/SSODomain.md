# SmplkitGeneratedClient::App::SSODomain

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **dns_txt_token** | **String** | Token to publish on the domain&#39;s DNS as a TXT record to prove ownership. The full record value is &#x60;smplkit-domain-verification&#x3D;&lt;token&gt;&#x60;. | [optional][readonly] |
| **verified_at** | **Time** | When the domain was verified. Null until verification succeeds. | [optional][readonly] |
| **status** | **String** | Verification status. &#x60;pending&#x60; means a claim has been registered but DNS TXT verification has not yet succeeded. &#x60;verified&#x60; means the domain is in use for SSO routing. | [optional][readonly] |
| **created_at** | **Time** | When the claim was created. | [optional][readonly] |
| **updated_at** | **Time** | When the claim was last modified. | [optional][readonly] |

## Example

```ruby
require 'smplkit_app_client'

instance = SmplkitGeneratedClient::App::SSODomain.new(
  dns_txt_token: null,
  verified_at: null,
  status: null,
  created_at: null,
  updated_at: null
)
```

