//
//  ChatViewController.swift
//  Flash Chat iOS13
//
//  Created by Angela Yu on 21/10/2019.
//  Copyright © 2019 Angela Yu. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class ChatViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var messageTextfield: UITextField!
    
    let db = Firestore.firestore()
    
    var messages: [Message] = [
        Message(sender: "1@2.com", body: "Hey!!"),
        Message(sender: "a@b.com", body: "Hello"),
        Message(sender: "1@2.com", body: "How are you?")
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        
        title = "⚡️FlashChat"
        navigationItem.hidesBackButton = true
        
        // Register new defined Cell (MessageCell) with its NibName and Identifier
        tableView.register(UINib(nibName: K.cellNibName, bundle: nil), forCellReuseIdentifier: K.cellIdentifier)
        
        loadMessages()
    }
    
    /// Load all messages from FireStore and Show in screen
    func loadMessages() {
        db.collection(K.FStore.collectionName)
            .order(by: K.FStore.dateField) // Order Docs
            .addSnapshotListener { querySnapshot, error in // Use Listner to trigger when new data is come up
            self.messages = []
            if let e = error {
                print("There was an issue retrieving data from FireStore. \(e)")
            } else {
                if let documents = querySnapshot?.documents {
                    for doc in documents {
                        if let sender = doc[K.FStore.senderField] as? String, let body = doc[K.FStore.bodyField] as? String {
                            let newMessage = Message(sender: sender, body: body)
                            self.messages.append(newMessage)
                            
                            // Reload Table and scroll to the last message (in main thread)
                            DispatchQueue.main.async {
                                self.tableView.reloadData()
                                
                                let indexPath = IndexPath(row: self.messages.count - 1, section: 0)
                                self.tableView.scrollToRow(at: indexPath, at: .top, animated: true)
                            }
                        }
                    }
                }
            }
        }
    }
    
    /// Send message by adding document to FireStore
    @IBAction func sendPressed(_ sender: UIButton) {
        if let body = messageTextfield.text, let sender = Auth.auth().currentUser?.email {
            messageTextfield.text = ""
            db.collection(K.FStore.collectionName)
                .addDocument(data: [
                    K.FStore.senderField: sender,
                    K.FStore.bodyField: body,
                    K.FStore.dateField: Date().timeIntervalSince1970,
                ]) { error in
                if let e = error {
                    print("There was an issue saving data to Firestore. \(e)")
                } else {
                    print("Successfuly saved data")
                }
            }
        }
    }
    
    @IBAction func logOutPressed(_ sender: UIBarButtonItem) {
        do {
            try Auth.auth().signOut()
            // Pop until find the root path (Welcome Screen)
            navigationController?.popToRootViewController(animated: true)
        } catch let signOutError as NSError {
            print("Error signing out: %@", signOutError)
        }
    }
    
}

/// For Setting data source of the table
extension ChatViewController: UITableViewDataSource {
    
    /// Set number of rows
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    /// Create an each cell (MessageCell)
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let message = messages[indexPath.row]
        
        // Get a cell with specific identifier
        let cell = tableView.dequeueReusableCell(withIdentifier: K.cellIdentifier, for: indexPath) as! MessageCell
        cell.label.text = message.body
        
        // If message is from current user
        if message.sender == Auth.auth().currentUser?.email {
            cell.leftImageView.isHidden = true
            cell.rightImageView.isHidden = false
            cell.messageBubble.backgroundColor = UIColor(named: K.BrandColors.purple)
            cell.label.textColor = UIColor(named: K.BrandColors.lightPurple)
        }
        // Else
        else {
            cell.leftImageView.isHidden = false
            cell.rightImageView.isHidden = true
            cell.messageBubble.backgroundColor = UIColor(named: K.BrandColors.lightPurple)
            cell.label.textColor = UIColor(named: K.BrandColors.purple)
        }
        
        return cell
        
    }
    
    
}
