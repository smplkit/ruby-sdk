# SmplkitGeneratedClient::App::EmailRegistrationsApi

All URIs are relative to *http://localhost*

| Method | HTTP request | Description |
| ------ | ------------ | ----------- |
| [**create_email_registration**](EmailRegistrationsApi.md#create_email_registration) | **POST** /api/v1/email-registrations | Register for Launch List |


## create_email_registration

> create_email_registration(request_body)

Register for Launch List

Submit an email address to the smplkit launch list. Sends a notification to support@smplkit.com. No authentication required. Nothing is persisted.

### Examples

```ruby
require 'time'
require 'smplkit_app_client'

api_instance = SmplkitGeneratedClient::App::EmailRegistrationsApi.new
request_body = { key: 3.56} # Hash<String, Object> | 

begin
  # Register for Launch List
  api_instance.create_email_registration(request_body)
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling EmailRegistrationsApi->create_email_registration: #{e}"
end
```

#### Using the create_email_registration_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> create_email_registration_with_http_info(request_body)

```ruby
begin
  # Register for Launch List
  data, status_code, headers = api_instance.create_email_registration_with_http_info(request_body)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling EmailRegistrationsApi->create_email_registration_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **request_body** | [**Hash&lt;String, Object&gt;**](Object.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/vnd.api+json
- **Accept**: application/vnd.api+json

