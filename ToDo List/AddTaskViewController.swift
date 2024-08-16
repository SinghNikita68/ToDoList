//
//  AddTaskViewController.swift
//  ToDo List
//
//  Created by Nikita Singh on 13/08/24.
//

import UIKit
import CoreData

class AddTaskViewController: UIViewController, UITextViewDelegate {
    
    @IBOutlet weak var titleField: UITextField!
    
    @IBOutlet weak var detailField: UITextView!
    
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    
    var task: Task?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Styling the text view
        var borderColor : UIColor = UIColor(red: 0.85, green: 0.85, blue: 0.85, alpha: 1.0)
        detailField.layer.borderWidth = 0.5
        detailField.layer.borderColor = borderColor.cgColor
        detailField.layer.cornerRadius = 1
        
        titleField.autocapitalizationType = .words
        titleField.becomeFirstResponder() // Open keyboard on load
        
        if task != nil {
            navigationItem.title = "Edit Task" // Update navigation title
            // Update fields with task details
            titleField.text = task?.title
            detailField.text = task?.details
        }
        
        detailField.delegate = self
        
        // Add tap gesture on view to hide the keyboard
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        view.addGestureRecognizer(gestureRecognizer)
        
        // Add observer for keyboard show and hide
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    // Save the task when back button is pressed
    override func viewWillDisappear(_ animated: Bool) {
        saveData()
        view.endEditing(true) // Hide keyboard
    }
    
    // Save the task whenever the title field changes
    @IBAction func titleFieldDidChange(_ sender: UITextField) {
        saveData()
    }
    
    // Save the task whenever the detail field changes
    func textViewDidChange(_ textView: UITextView) {
        print("textViewDidChange")
        saveData()
    }
    
    // Save data in core data
    func saveData () {
        if task == nil   && (titleField.text != "" || detailField.text != "") {
            // If the task is new, create one and save
            if let context = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer.viewContext {
                task = Task(context: context)
                task?.taskId = UUID()
                task?.title = titleField.text
                task?.details = detailField.text
                task?.status = false
            }
            
            (UIApplication.shared.delegate as? AppDelegate)?.saveContext()
        }
        else{
            // If task is already created, update the task
            task?.title = titleField.text
            task?.details = detailField.text
            (UIApplication.shared.delegate as? AppDelegate)?.saveContext()
        }
    }
    
    // To Hide keyboard on tap on view
    @objc func hideKeyboard() {
        view.endEditing(true)
        bottomConstraint.constant = 16
    }
    
    // To move the view up when keyboard is shown
    @objc func keyboardWillShow(_ notification: Notification) {
        if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardRectangle = keyboardFrame.cgRectValue
            let keyboardHeight = keyboardRectangle.height
            
            bottomConstraint.constant = keyboardHeight
        }
    }
    
    // To move the view down when keyboard is hidden
    @objc func keyboardWillHide(_ notification: Notification) {
        bottomConstraint.constant = 16
    }
    
}
