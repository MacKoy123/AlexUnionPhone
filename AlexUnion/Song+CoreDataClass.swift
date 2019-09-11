//
//  Song+CoreDataClass.swift
//  AlexUnion
//
//  Created by Viktor Puzakov on 9/3/19.
//  Copyright © 2019 Mac. All rights reserved.
//
//

import Foundation
import CoreData


public class Song: NSManagedObject {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Song> {
        return NSFetchRequest<Song>(entityName: "Song")
    }
    
    @NSManaged public var text: String
    @NSManaged public var singer: String?
}
