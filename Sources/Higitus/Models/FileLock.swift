import Foundation

// TODO: save the PID inside the lock, that way if the PID cannot be reached, we can safely recreate the lock
struct Lock {
    
    init(url: FileURL) {
        self.url = url
    }
    
    private let url: FileURL
    
    func acquire() -> Bool {
        guard !url.exists else { return false }
        url.touch()
        return true
    }

    func release() {
        try? FileManager.default.removeItem(atPath: url.asPath)
    }
}
