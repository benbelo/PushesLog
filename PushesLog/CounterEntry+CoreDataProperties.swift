//
//  CounterEntry+CoreDataProperties.swift
//  PushesLog
//
//  Created by Benjamin on 18/08/2024.
//
//

import Foundation
import CoreData


extension CounterEntry {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CounterEntry> {
        return NSFetchRequest<CounterEntry>(entityName: "CounterEntry")
    }

    @NSManaged public var date: Date?
    @NSManaged public var value: Int64

}

extension CounterEntry : Identifiable {

}
