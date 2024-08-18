//
//  Entity+CoreDataProperties.swift
//  PushesLog
//
//  Created by Benjamin on 18/08/2024.
//
//

import Foundation
import CoreData


extension Entity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Entity> {
        return NSFetchRequest<Entity>(entityName: "Entity")
    }

    @NSManaged public var date: Date?
    @NSManaged public var value: Int64

}

extension Entity : Identifiable {

}
