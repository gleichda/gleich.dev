---
title: "How Golang's omitempty can confuse the (Google) APIs"
date: 2021-01-14T07:51:22+01:00
draft: true****
---

## First thoughts

![Google Go Meme](/img/golang/GoGoogleMeme.jpg)

And this is also the reason we decided to do most of our programming in Go.
But sometimes we stumbled over some pitfalls. 
(Also referring to [the post of a colleague](https://medium.com/@kunzese/gcp-cloud-nat-golangs-http-client-65528ec86e) some times ago)

## What does the omitempty option exactly?

When building JSON Structs you often have fields that are optional.
To reduce the unnecessary transmission size in case you are calling some JOSN/REST APIs these fields don't need to be sent.
The same applies of course for storing JSON Objects in a NoSQL Database or on a file system where you don't want to waste your storage on default/nil values.

So a sample Go struct could look like below:

```go
type Customer struct {
    Name             string `json:"name"`
    FirstName        string `json:"firstName"`
    CreditCardNumber string `json:"creditCardNumber,omitempty"`
    Active           bool   `json:"active,omitempty"`
}
```

## Where does the confusion now come from?

### Parsing JSON to Go Structs

So creating a few different customers which could look like:

```json
{
  "name": "Doe",
  "firstName": "John",
  "creditCardNumber": "0123456789",
  "active": true
}
```

```json
{
  "name": "Doe",
  "firstName": "Jane"
}
```

```json
{
  "name": "Bloggs",
  "firstName": "Joe",
  "active": false
}
```

So parsing them in Go will give the following output:

John: `{Name:Doe FirstName:John CreditCardNumber:0123456789 Active:true}`

Jane: `{Name:Doe FirstName:Jane CreditCardNumber: Active:false}`

Joe: `{Name:Bloggs FirstName:Joe CreditCardNumber: Active:false}`

### Parsing back to JSON

So parsing the structs back to JSON will result in the following JSONs:

```json
{
  "name": "Doe",
  "firstName": "Jane"
}
```

```json
{
  "name": "Doe",
  "firstName": "John",
  "creditCardNumber": "0123456789",
  "active": true
}
```

```json
{
  "name": "Bloggs",
  "firstName": "Joe"
}
```

And now looking at Joe the `"active": false` disappeared.

Why?

Looking into the [`encoding/json` Go Package](https://golang.org/pkg/encoding/json/#Marshal):

The "omitempty" option specifies that the field should be omitted from the encoding if the field has an empty value, defined as false, 0, a nil pointer, a nil interface value, and any empty array, slice, map, or string.

So as `false` is the default boolean value it is just omitted.

## What's the Problem with that now?

When doing the PATCH request Google (and probably many other APIs) only updated the sent fields.
This means that disabling a Customer with the Patch Field won't work here.

Luckily at least for the Google APIs there is quite an easy pick how to fix it.
(After you finally discovered the problem...)
Each Struct of the [Google API Package](https://pkg.go.dev/google.golang.org/api) has a `ForceSendFields`:

```
// NullFields is a list of field names (e.g. "Enabled") to include in
// API requests with the JSON null value. By default, fields with empty
// values are omitted from API requests. However, any field with an
// empty value appearing in NullFields will be sent to the server as
// null. It is an error if a field in this list has a non-empty value.
// This may be used to include null fields in Patch requests.
```

(Taken from [BackendServiceIAP](https://pkg.go.dev/google.golang.org/api/compute/v1#BackendServiceIAP) as we found the issue there)

So for disabling the IAP the struct could look like:

```go
IAPConfig := compute.BackendServiceIAP{
    Enabled:                  false,
    ForceSendFields:          []string{"Enabled"},
}
```

## What can you as an API Client Maintainer do to don't have that issue

As long as you don't use the Boolean directly but use a Pointer this is no issue as for a Pointers the default is `nil`.
There is also a [Issue in the Go Repo](https://github.com/golang/go/issues/13284) for further reading.

So after explaining all that to you, I guess you already noticed that this was not an easy pick.
Together with support from my colleague (thanks for that btw) it took me about 5 hours to find that issue and fix it.
