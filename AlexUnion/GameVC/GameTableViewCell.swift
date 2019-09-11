//
//  GameTableViewCell.swift
//  AlexUnion
//
//  Created by Viktor Puzakov on 9/5/19.
//  Copyright © 2019 Mac. All rights reserved.
//

import UIKit

class GameTableViewCell: UITableViewCell {
    
    @IBOutlet weak var collectionView: UICollectionView!
    var word: String! = nil
    
    var characters: [Character] {
        return Array(word.uppercased())
    }
    var punctuationMarks: [Character] = [",", "!", "?", ":", "-"]
    
    var buttonTouchedCharacters: [Character] = [] {
        didSet {
            collectionView.reloadData()
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(UINib(nibName: "GameCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "cvCell")
    }
    
}

extension GameTableViewCell: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return characters.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: GameCollectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: "cvCell", for: indexPath) as! GameCollectionViewCell
        cell.label.text = String(characters[indexPath.row])
        if buttonTouchedCharacters.contains(characters[indexPath.row]) || punctuationMarks.contains( characters[indexPath.row]) {
            cell.backgroundColor = UIColor.white
        } else {
            cell.backgroundColor = UIColor.black
        }
        return cell
    }
}
