#APIDefintion

`APIDefinition` is a protocol by which you can express what an API wants to do. For example, the `path`, the `http method`, `headers` etc.

You start defining an `APIDefinition` for a [RESTful resource](https://www.thoughtworks.com/insights/blog/rest-api-design-resource-modeling).

For example your API has `/accounts, /bets, /announcements` then you should define one APIDefinition per resource. 

You can use Swift enum to better express an API Definition which is readable and compile safe.

```swift
// Participating request models
struct EditableAccountDetails: Encodable, JSONRepresentable {
    let name: String
    let email: String
}

// All endpoints under /accounts resource
enum AccountsAPIDefinition {
    case details
    case update(details: JSONRepresentable)
}
```

We define each endpoint as an enum case with associated values if any.

**JSONRepresentable**
> **Uluru** is strict with request parameters and json body to be JSON. `JSONRepresentable` is the way to express it without loose keys and values so we operate under compiler safety.

Next confirm to `APIDefinition` 

```swift
extension AccountsAPIDefinition: APIDefinition {
...
}    
```


Specify the base url of the API and relative path of the resource  

```
    var baseURL: URL {
        return URL(string: "https://myapi.com")!
    }
    
    var path: String {
        "/accounts"
    }

```

Here you can optionally use the associated value to construct the path. For example `/accounts/<accountnumber>`


Then express the http method of the specific endpoint

```swift
var method: HTTPMethod {
        switch self {
        case .details:
            return .GET
        case .update:
            return .PUT
        }
    }
```

Next we need to tell Uluru what is the encoding strategy. In this case we are using a `GET` without any parms and `POST` with body params. This is easily expressed as 

```swift
var encoding: EncodingStrategy {
        switch self {
        case .details:
            return .ignore
        case .update(let details):
            return .jsonBody(parameters: details)
        }
    }
```

The advantage of representing params as `JSONRepresentable` is that they can be safely encoded.

Possible encoding strategies are

* `ignore`: Encoding not required
* `queryParameters(parameters: JSONRepresentable)`: GET query params 
* `jsonBody(parameters: JSONRepresentable)`: JSON body
* `jsonBodyUsingCustomEncoder(parameters: JSONRepresentable, encoder: JSONEncoder)`: JSON body with custom JSONEncoder.


Almost there ...
Next we will add any headers

```swift
    var headers: [String : String]? {
        return ["Content-Type": "application/json"]
    }
```

This completes all the details Uluru needs to execute a network request. But in practice you may want to group the general requirements of an APIDefinition in a 

```swift
protocol TABAPIDefinition: APIDefinition {
    var baseURL: URL {
        return URL(string: "https://myapi.com")!
    }

    var headers: [String : String]? {
        return ["Content-Type": "application/json"]
    }
}
```

```swift
enum AccountsAPIDefinition: TABAPIDefinition {
... provide only what is required.
}

```