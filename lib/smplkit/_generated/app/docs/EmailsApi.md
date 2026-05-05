# SmplkitGeneratedClient::App::EmailsApi

All URIs are relative to *http://localhost*

| Method | HTTP request | Description |
| ------ | ------------ | ----------- |
| [**send_contact_email**](EmailsApi.md#send_contact_email) | **POST** /api/v1/emails | Send Contact Us Email |


## send_contact_email

> <EmailResponse> send_contact_email(request_body)

Send Contact Us Email

Send a contact-us message. Delivers two emails: a ticket to support with Reply-To set to the user, and an auto-response to the user. Nothing is persisted; the returned id is for correlation only.

### Examples

```ruby
require 'time'
require 'smplkit_app_client'
# setup authorization
SmplkitGeneratedClient::App.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::App::EmailsApi.new
request_body = { key: 3.56} # Hash<String, Object> | 

begin
  # Send Contact Us Email
  result = api_instance.send_contact_email(request_body)
  p result
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling EmailsApi->send_contact_email: #{e}"
end
```

#### Using the send_contact_email_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<EmailResponse>, Integer, Hash)> send_contact_email_with_http_info(request_body)

```ruby
begin
  # Send Contact Us Email
  data, status_code, headers = api_instance.send_contact_email_with_http_info(request_body)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <EmailResponse>
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling EmailsApi->send_contact_email_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **request_body** | [**Hash&lt;String, Object&gt;**](Object.md) |  |  |

### Return type

[**EmailResponse**](EmailResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: application/vnd.api+json
- **Accept**: application/vnd.api+json

