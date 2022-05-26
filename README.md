# Uluru 

![Uluru by artist Peter Taylor Tjutjatja](docs/uluru-photo.jpg)Uluru by artist Peter Taylor Tjutjatja

## What is Uluru
Uluru is a simple and agnostic layer for REST APIs using declarative API concept and written in Swift.

## How Uluru is different?

### Declarative Services
With [declarative API](https://www.twilio.com/blog/2017/05/declarative-apis.html) the service are described by **what** they want to do rather than **how** to do. The how part of the equation is handled by Uluru. This makes defining services intuitive and simple.

### Plugin system
Uluru strives to follow Open-Closed priniciple - *Open for extension and closed for modification*. This is achieved using [Plugins](https://subscription.packtpub.com/book/web_development/9781783287338/1/ch01lvl1sec13/exploring-middleware-architecture) and [Strategy pattern](https://en.wikipedia.org/wiki/Strategy_pattern) so the behavior can be customized without modifying the core.

This has many benefits 

1. New functionalities can be added as plugins, for example a plugin to provide the correct request headers, a plugin to capture API errors.
2. Plugins keep the code modular since they are dont depend on each other.
3. Strategies allow to customize the behaviour at runtime, for example correct authentication strategy as per API.

### Testability in mind
Uluru is designed with testability in mind. Every API request can be stubbed by simple closures so that developers are encouraged to write acceptance tests with ease. 

## Usage

Start by definining what an API Service wants to do by implementing `APIDefinition`. 

**CatsAPIDefinition.swift**

```
struct Cat: Codable, JSONRepresentable {
    let name: String
    let color: String
}

enum CatsAPIDefinition {
   case allCats
   case registerCat(JSONRepresentable)
}

extension CatsAPIDefinition: APIDefinition {
    var baseURL: URL {
        return URL(string: "https://mycatsapi.com")!
    }

    var path: String {
        switch self {
        case .allCats:
            return "/cats"
        case .registerCat:
            return "/register"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .allCats:
            return .GET
        case .registerCat:
            return .POST
        }
    }

    var encoding: EncodingStrategy {
        switch self {
        case .allCats:
            return .ignore
        case .registerCat(let aCat):
            return .jsonBody(parameters: aCat)
        }
    }

    var headers: [String : String]? {
        return ["Content-type": "application/json"]
    }
}

```

**CatsRepository.swift**

```
class CatsRepository {

    private let service: ServiceRequester<CatsAPIDefinition>
    init(_ service: ServiceRequester<CatsAPIDefinition>) {
        self.service = service
    }

    func fetchAllCats() {
        service.request(.allCats, expecting: [Cat].self) { result in
            switch result {
            case .success(let response):
                let ourCats = response.parsed
                // how about a photo shoot with our cats?
            case .failure(let error):
                // do something with error
                break
            }
        }
    }

    func addCat(_ aCat: Cat) {
        service.request(.registerCat(aCat), expecting: Cat.self) { result in
            switch result {
            case .success(let response):
                let newCat = response.parsed
                // may be this is your instagram cat
            case .failure(let error):
                // do something with error
                break
            }
        }
    }
}

extension CatsRepository {
    static func make() -> CatsRepository {
        return CatsRepository(ServiceRequester())
    }
}
```


## Documentation
See all docs and core concepts [here](docs/README.md).

## Framework release process
See release process [here](docs/release/README.md).