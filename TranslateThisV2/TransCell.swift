//
//  TransCell.swift
//  TranslateThisV2
//
//  Created by Robert on 7/27/17.
//  Copyright © 2017 R&R Developement. All rights reserved.
//

import Foundation
import UIKit

class TransCell: UITableViewCell {
    
    var Delegate: TranslationsTVC?
    var indexPath: NSIndexPath?
    
    
    
    @IBOutlet weak var PhraseLabel: UILabel!
    
    @IBAction func micButtonPressed(_ sender: UIButton) {
        Delegate?.speakTranslation(for: indexPath!)
    }
}