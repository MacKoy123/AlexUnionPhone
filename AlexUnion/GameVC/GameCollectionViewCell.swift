//
//  GameCollectionViewCell.swift
//  AlexUnion
//
//  Created by Viktor Puzakov on 9/5/19.
//  Copyright © 2019 Mac. All rights reserved.
//

import UIKit

class GameCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var label: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.layer.cornerRadius = 3.0
        self.layer.borderWidth = 2.0
        self.layer.borderColor = UIColor.black.cgColor
    }
}
