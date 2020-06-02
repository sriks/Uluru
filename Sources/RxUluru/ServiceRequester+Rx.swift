//Copyright © 2020 Tabcorp. All rights reserved.

import Foundation
import Uluru
import RxSwift

extension ServiceRequester: ReactiveCompatible {}

public extension Reactive where Base: Service {

    func request<T: Decodable>(_ api: Base.API,
                               expecting: T.Type) -> Single<ParsedDataResponse<T>> {
        return Single.create { [weak base] single in
            let cancellable = base?.request(api, expecting: expecting, completion: { result in
                switch result {
                case .success(let response):
                    single(.success(response))
                case .failure(let error):
                    single(.error(error))
                }
            })
            
            return Disposables.create {
                cancellable?.cancel()
            }
        }
    }
}
