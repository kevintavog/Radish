//
//

import AppKit

import Async
import RangicCore


class SearchWindowController : NSWindowController
{
    var viewSearchResults = false
    @IBOutlet weak var hostText: NSTextField!
    @IBOutlet weak var searchText: NSTextField!
    @IBOutlet weak var statusImage: NSImageView!
    @IBOutlet weak var statusLabel: NSTextField!
    @IBOutlet weak var workingIndicator: NSProgressIndicator!

    
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

        // Run search (clear status text, start working indicator)
        // When it completes (end working indicator)
        // If it succeeds, set flag and close
        // If it fails, set status message and stay open
        Async.background {
            FindAPhotoResults.search(
                self.hostText.stringValue,
                text: self.searchText.stringValue,
                first: 1,
                count: 1,
                completion: { (result: FindAPhotoResults) -> () in
                    Async.main {
                        self.workingIndicator.isHidden = true
                        self.workingIndicator.stopAnimation(sender)

                        self.statusImage.isHidden = false
                        if result.hasError {
                            self.statusImage.image = NSImage(named: NSImage.Name(rawValue: "FailedCheck"))
                            self.statusLabel.stringValue = "FAILED: \(result.errorMessage!)"
                        } else {
                            Preferences.findAPhotoHost = self.hostText.stringValue
                            self.statusImage.image = NSImage(named: NSImage.Name(rawValue: "SucceededCheck"))
                            if result.totalMatches! == 0 {
                                self.statusLabel.stringValue = "Succeeded - but there are no matches"
                            } else {
                                self.statusLabel.stringValue = "Succeeded with a total of \(result.totalMatches!) matches"
                                
                                Async.main {
                                    self.viewSearchResults = true
                                    self.close()
                                }
                            }
                        }
                    }
            })
        }
    }
}
