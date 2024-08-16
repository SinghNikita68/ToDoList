//
//  ListViewController.swift
//  ToDo List
//
//  Created by Nikita Singh on 13/08/24.
//

import UIKit
import CoreData
import UserNotifications

class ListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UNUserNotificationCenterDelegate  {
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var listTableView: UITableView!
    @IBOutlet weak var addTaskButton: UIButton!
    @IBOutlet weak var listBottomConstraint: NSLayoutConstraint!
    
    var tasks: [Task] = []
    
    override func viewWillAppear(_ animated: Bool) {
        print("viewWillAppear")
        // Fetch tasks from Core Data
        if let context =  (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer.viewContext {
            let request: NSFetchRequest<Task> = Task.fetchRequest()
            
            if let tasksFromCoreData = try? context.fetch(request) {
                tasks = tasksFromCoreData
                tasks.reverse()
                listTableView.reloadData()
                
                // Check if there are any pending tasks then schedule a local notification
                let predicate = NSPredicate(format: "status == %@", NSNumber(value: false))
                request.predicate = predicate
                do {
                    let pendingTasks = try context.fetch(request)
                    if(pendingTasks.count > 0){
                        scheduleLocalNotification()
                    }
                } catch {
                    print("Error fetching tasks: \(error)")
                }
                
                // Show a message if there are no tasks
                showEmptyMessage()
            }
        }
        
        // Empty Search box
        searchBar.text = ""
        
        // To add observer for keyboard show and hide
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        // To add tap gesture on the header to close the keyboard
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        self.navigationController?.navigationBar.addGestureRecognizer(tapGesture)
        
        //To set the Back button title to empty
        navigationItem.backBarButtonItem = UIBarButtonItem(
            title: "", style: .plain, target: nil, action: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        listTableView.delegate = self
        listTableView.dataSource = self
        
        // Request permission for local notifications
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { (granted, error) in
            if granted {
                print("Local notification permission granted")
            } else {
                print("Local notification permission denied")
            }
        }
        
        UNUserNotificationCenter.current().delegate = self
    }
    
    
    
    // To move the view up when keyboard is shown
    @objc func keyboardWillShow(_ notification: Notification) {
        if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardRectangle = keyboardFrame.cgRectValue
            let keyboardHeight = keyboardRectangle.height
            
            listBottomConstraint.constant = keyboardHeight
        }
    }
    
    // To move the view down when keyboard is hidden
    @objc func keyboardWillHide(_ notification: Notification) {
        listBottomConstraint.constant = 0
    }
    
    // To hide the keyboard on tap on the header
    @objc func hideKeyboard() {
        view.endEditing(true)
        listBottomConstraint.constant = 0
    }
    
    // Return the no of cells of the table view
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tasks.count
    }
    
    // Set the cell content
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "listCell") as? TaskTableViewCell {
            let task = tasks[indexPath.row]
            cell.titleLabel?.text = task.title
            cell.detailLabel?.text = task.details
            
            // Add Icon
            let iconImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
            iconImageView.contentMode = .scaleAspectFit
            if task.status {
                iconImageView.image = UIImage(named: "completed")
            } else {
                iconImageView.image = UIImage(named: "pending")
            }
            cell.accessoryView = iconImageView
            
            return cell
        } else {
            return UITableViewCell()
        }
    }
    
    // Set the height of the cell
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    
    // Add task button action
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let task = tasks[indexPath.row]
        performSegue(withIdentifier: "addTaskSegue", sender: task)
    }
    
    // Prepare for segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let taskVC = segue.destination as? AddTaskViewController {
            if let entryToBeSent = sender as? Task {
                taskVC.task = entryToBeSent
            }
        }
    }
    
    // Add Left swipe gesture to delete
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { (action, view, completionHandler) in
            
            let task = self.tasks[indexPath.row]
            if let context = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer.viewContext {
                
                let confirmDeleteAlert = UIAlertController(title: "Confirm Deletion", message: "Are you sure you want to delete this task?", preferredStyle: .alert)
                
                let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { (action) in
                    context.delete(task)
                    do {
                        try context.save()
                        self.tasks.remove(at: indexPath.row)
                        tableView.deleteRows(at: [indexPath], with: .fade)
                        self.showEmptyMessage()
                        
                    } catch {
                        print("Error deleting task: \(error)")
                    }
                }
                
                let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
                
                confirmDeleteAlert.addAction(deleteAction)
                confirmDeleteAlert.addAction(cancelAction)
                self.present(confirmDeleteAlert, animated: true, completion: nil)
            }
            completionHandler(true)
        }
        deleteAction.backgroundColor = .red
        deleteAction.image = UIImage(systemName: "trash")
        
        let configuration = UISwipeActionsConfiguration(actions: [deleteAction])
        return configuration
    }
    
    // Add right swipe gesture to mark task as completed
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let task = tasks[indexPath.row]
        
        guard !task.status else {
            return nil
        }
        
        let tickAction = UIContextualAction(style: .normal, title: "Mark Completed") { (action, view, completionHandler) in
            
            if let context = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer.viewContext {
                task.status = true
                
                do {
                    try context.save()
                    tableView.reloadData()
                } catch {
                    print("Error marking task as completed: \(error)")
                }
            }
            completionHandler(true)
        }
        
        tickAction.backgroundColor = .systemGreen
        tickAction.image = UIImage(systemName: "checkmark")
        
        let configuration = UISwipeActionsConfiguration(actions: [tickAction])
        return configuration
        
    }
    
    // Function to schedule a local notification
    func scheduleLocalNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Task Reminder"
        content.body = "Hey! You have some pending tasks left to complete."
        content.sound = UNNotificationSound.default
        
        // Set the trigger time to be 8AM for every day
        var dateComponents = DateComponents()
        dateComponents.hour = 8
        dateComponents.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        // Create the request for the notification
        let request = UNNotificationRequest(identifier: "TaskReminder", content: content, trigger: trigger)
        
        // Schedule the notification
        UNUserNotificationCenter.current().add(request) { (error) in
            if let error = error {
                print("Error scheduling local notification: \(error)")
            } else {
                print("Local notification scheduled successfully")
            }
        }
    }
    
    // To handle foreground notifications
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let alertController = UIAlertController(title: notification.request.content.title, message: notification.request.content.body, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(okAction)
        self.present(alertController, animated: true, completion: nil)
        completionHandler([.alert, .sound, .badge])
    }
    
    func showEmptyMessage(){
        if tasks.isEmpty {
            let noDataLabel = UILabel(frame: CGRect(x: 0, y: 0, width: listTableView.bounds.size.width, height: listTableView.bounds.size.height))
            noDataLabel.text = "Add tasks to get started!"
            noDataLabel.textAlignment = .center
            noDataLabel.textColor = .gray
            listTableView.backgroundView = noDataLabel
            searchBar.isHidden = true
        } else {
            listTableView.backgroundView = nil
            searchBar.isHidden = false
        }
    }
    
}

// Search bar delegate methods
extension ListViewController: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if let context = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer.viewContext {
            let request: NSFetchRequest<Task> = Task.fetchRequest()
            if !searchText.isEmpty {
                let predicate = NSPredicate(format: "title CONTAINS[cd] %@", searchText)
                request.predicate = predicate
            }
            
            
            if searchBar.text == nil || searchBar.text == ""
            {
                searchBar.perform(#selector(self.resignFirstResponder), with: nil, afterDelay: 0.1)
            }
            do {
                tasks = try context.fetch(request)
                if tasks.isEmpty {
                    showNoResultsMessage()
                } else {
                    hideNoResultsMessage()
                }
                listTableView.reloadData()
            } catch {
                print("Error fetching tasks: \(error)")
            }
            
            
        }
        
    }
    
    func showNoResultsMessage() {
        let noResultsLabel = UILabel(frame: CGRect(x: 0, y: searchBar.frame.maxY, width: listTableView.bounds.size.width, height: 30))
        noResultsLabel.text = "No results found"
        noResultsLabel.textAlignment = .center
        noResultsLabel.textColor = .gray
        noResultsLabel.tag = 999
        listTableView.addSubview(noResultsLabel)
    }
    
    func hideNoResultsMessage() {
        if let noResultsLabel = listTableView.viewWithTag(999) {
            noResultsLabel.removeFromSuperview()
        }
    }
}

