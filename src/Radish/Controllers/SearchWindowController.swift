//
//

import AppKit

import Async
import RangicCore


class SearchWindowController : NSWindowController, NSWindowDelegate
{
    var viewSearchResults = false
    @IBOutlet weak var hostText: NSTextField!
    @IBOutlet weak var searchText: NSTextField!
    @IBOutlet weak var statusImage: NSImageView!
    @IBOutlet weak var statusLabel: NSTextField!
    @IBOutlet weak var workingIndicator: NSProgressIndicator!

    override func windowDidLoad() {
        self.window?.delegate = self
    }
    
    override func awakeFromNib()
    {
        hostText.stringValue = Preferences.findAPhotoHost
        statusImage.isHidden = true
        statusLabel.stringValue = ""
        workingIndicator.isHidden = true
        searchText.stringValue = Preferences.lastSearchText

        if Preferences.findAPhotoHost.count > 0 {
            window?.makeFirstResponder(searchText)
        }
    }

    func windowWillClose(_ notification: Notification)
    {
        NSApplication.shared.stopModal()
    }

    @IBAction func cancel(_ sender: AnyObject)
    {
        close()
    }

    @IBAction func view(_ sender: AnyObject)
    {
        statusImage.isHidden = true
        statusLabel.stringValue = ""
        workingIndicator.startAnimation(sender)
        workingIndicator.isHidden = false
        Preferences.lastSearchText = searchText.stringValue
        
        let hostValue = self.hostText.stringValue
        let searchValue = self.searchText.stringValue
        

        // Run search (clear status text, start working indicator)
        // When it completes (end working indicator)
        // If it succeeds, set flag and close
        // If it fails, set status message and stay open
        Async.background {
            FindAPhotoResults.search(
                hostValue,
                text: searchValue,
                first: 1,
                count: 1,
                completion: { (result: FindAPhotoResults) -> () in
                    Async.main {
                        self.workingIndicator.isHidden = true
                        self.workingIndicator.stopAnimation(sender)

                        self.statusImage.isHidden = false
                        if result.hasError {
                            self.statusImage.image = NSImage(named: "FailedCheck")
                            self.statusLabel.stringValue = "FAILED: \(result.errorMessage!)"
                        } else {
                            Preferences.findAPhotoHost = hostValue
                            self.statusImage.image = NSImage(named: "SucceededCheck")
                            if result.totalMatches! == 0 {
                                self.statusLabel.stringValue = "Succeeded - but there are no matches"
                            } else {
                                self.statusLabel.stringValue = "Succeeded with a total of \(result.totalMatches!) matches"

                                self.viewSearchResults = true
                                self.close()
                            }
                        }
                    }
            })
        }
    }
}
