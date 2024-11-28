import UIKit
import StreamChatUI

/// Manages the functionality of a reusable search bar.
class SearchBarManager: NSObject, UISearchBarDelegate {
    
    /// The search bar instance managed by this class.
    let searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.placeholder = "Search for a username" // Placeholder text for guidance.
        searchBar.sizeToFit() // Adjust the size of the search bar.
        return searchBar
    }()
    
    /// Callback for handling the search action.
    var onSearch: ((String) -> Void)?
    
    /// Initializes the search bar and sets up its delegate.
    override init() {
        super.init()
        searchBar.delegate = self
    }
    
    // MARK: - UISearchBarDelegate Methods
    
    /// Filters the search text to allow only lowercase letters and removes spaces.
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        let filteredText = searchText.lowercased().replacingOccurrences(of: " ", with: "")
        
        // Update the search bar text if it has been altered.
        if filteredText != searchText {
            searchBar.text = filteredText
        }
    }
    
    /// Handles the search button click event.
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let searchText = searchBar.text, !searchText.isEmpty else { return }
        onSearch?(searchText) // Trigger the search action via the callback.
        searchBar.resignFirstResponder() // Dismiss the keyboard.
    }
}
