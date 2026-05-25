# SmplkitGeneratedClient::App::SSOConnection

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **protocol** | **String** | Federation protocol. &#x60;oidc&#x60; for OpenID Connect; &#x60;saml&#x60; for SAML 2.0. Determines which set of IdP fields below are required. |  |
| **oidc_issuer** | **String** | OIDC issuer URL — the base from which &#x60;.well-known/openid-configuration&#x60; is discovered. Required when &#x60;protocol&#x60; is &#x60;oidc&#x60;; ignored when &#x60;protocol&#x60; is &#x60;saml&#x60;. | [optional] |
| **oidc_client_id** | **String** | OIDC client identifier issued by the IdP for smplkit. Required when &#x60;protocol&#x60; is &#x60;oidc&#x60;; ignored otherwise. | [optional] |
| **oidc_client_secret** | **String** | OIDC client secret. Write-only — supplied on PUT, never returned by the API. Stored envelope-encrypted at rest. Required on first creation of an OIDC connection; on subsequent PUTs, omit to retain the existing value. | [optional] |
| **saml_idp_entity_id** | **String** | SAML IdP EntityID (typically a URI). Required when &#x60;protocol&#x60; is &#x60;saml&#x60;; ignored otherwise. | [optional] |
| **saml_idp_sso_url** | **String** | SAML IdP single sign-on URL (HTTP-Redirect or HTTP-POST endpoint). Required when &#x60;protocol&#x60; is &#x60;saml&#x60;. | [optional] |
| **saml_idp_slo_url** | **String** | SAML IdP single logout URL. Optional — when present, smplkit will issue LogoutRequests on user sign-out. | [optional] |
| **saml_idp_x509_cert** | **String** | SAML IdP X.509 signing certificate (PEM-encoded). Required when &#x60;protocol&#x60; is &#x60;saml&#x60;. | [optional] |
| **default_role** | **String** | Role granted to a user provisioned just-in-time on their first SSO login when no group mapping applies. &#x60;OWNER&#x60; values are downgraded to &#x60;ADMIN&#x60; for JIT — owner promotion remains an explicit account action. | [optional][default to &#39;MEMBER&#39;] |
| **group_role_mappings** | **Hash&lt;String, String&gt;** | Mapping of IdP group claim values to smplkit roles. The first key matching the user&#39;s group claims (in declaration order) decides the JIT role; if none match, &#x60;default_role&#x60; applies. Example: &#x60;{\&quot;smplkit-admins\&quot;: \&quot;ADMIN\&quot;}&#x60;. | [optional] |
| **enforced** | **Boolean** | When &#x60;true&#x60;, password and social sign-in are rejected for users whose email domain matches one of the account&#39;s verified domains. The account owner is exempt (break-glass). | [optional][default to false] |
| **sp_entity_id** | **String** | Service Provider EntityID to register with the IdP. Computed from the connection — paste this value into the IdP&#39;s smplkit configuration. | [optional][readonly] |
| **acs_url** | **String** | Assertion Consumer Service URL (SAML) or redirect URI (OIDC) to register with the IdP. Computed. | [optional][readonly] |
| **slo_url** | **String** | Single Logout URL to register with the IdP. Computed; smplkit accepts logout requests here for the SAML case. | [optional][readonly] |
| **created_at** | **Time** | When the connection was created. | [optional][readonly] |
| **updated_at** | **Time** | When the connection was last modified. | [optional][readonly] |

## Example

```ruby
require 'smplkit_app_client'

instance = SmplkitGeneratedClient::App::SSOConnection.new(
  protocol: null,
  oidc_issuer: null,
  oidc_client_id: null,
  oidc_client_secret: null,
  saml_idp_entity_id: null,
  saml_idp_sso_url: null,
  saml_idp_slo_url: null,
  saml_idp_x509_cert: null,
  default_role: null,
  group_role_mappings: null,
  enforced: null,
  sp_entity_id: null,
  acs_url: null,
  slo_url: null,
  created_at: null,
  updated_at: null
)
```

