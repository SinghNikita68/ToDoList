//
//  Task+CoreDataProperties.swift
//  ToDo List
//
//  Created by Nikita Singh on 13/08/24.
//
//

import Foundation
import CoreData


extension Task {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Task> {
        return NSFetchRequest<Task>(entityName: "Task")
    }

    @NSManaged public var title: String?
    @NSManaged public var details: String?
    @NSManaged public var status: Bool
    @NSManaged public var taskId: UUID?
}

extension Task : Identifiable {

}
