import Foundation

enum LoadingState<T> {
    case idle
    case loading
    case loaded(T)
    case failed(Error)
}

extension LoadingState {
    var value: T? {
        if case let .loaded(value) = self {
            return value
        }
        return nil
    }

    var isLoading: Bool {
        if case .loading = self {
            return true
        }
        return false
    }
}
