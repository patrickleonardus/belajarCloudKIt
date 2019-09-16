//
//  ViewController.swift
//  YourName
//
//  Created by Patrick Leonardus on 10/09/19.
//  Copyright © 2019 Patrick Leonardus. All rights reserved.
//

import UIKit
import CloudKit
import UserNotifications

class ViewController: UIViewController {
    
    
    @IBOutlet weak var tableView: UITableView!
    var arrayName : Array<CKRecord> = []
    var nameTemp = ""
    var textFieldName = UITextField()
    var action = UIAlertAction()
    var actionUpdate = UIAlertAction()
    var refreshControl = UIRefreshControl()

    override func viewDidLoad() {
        tableView.tableFooterView = UIView()
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        refreshControl.addTarget(self, action: #selector(refresh), for: UIControl.Event.valueChanged)
        tableView.addSubview(refreshControl)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        arrayName.removeAll()
        loadData()
        tableView.reloadData()
    }
    
    @objc func validation(){
        if textFieldName.text!.isEmpty {
            action.isEnabled = false
            actionUpdate.isEnabled = false
        }
        else if !(textFieldName.text!.isEmpty) {
            action.isEnabled = true
            actionUpdate.isEnabled = true
        }
    }
    
    @objc func refresh(){
        arrayName.removeAll()
        loadData()
        tableView.reloadData()
        self.refreshControl.endRefreshing()
    }
    
    func saveData(data : CKRecordValue){
        let record = CKRecord(recordType: "Profile")
        record["name"] = data
        
        
        let database = CKContainer.default().publicCloudDatabase
        database.save(record) { (record, error) in
            if error != nil {
                print(error!.localizedDescription + "Error tot")
            }
            else {
                print("Mantap")
            }
        }
    }
    
    func loadData(){
        let container = CKContainer.default()
        let publicDatabase = container.publicCloudDatabase
        let predicate = NSPredicate(value: true)
        
        let query = CKQuery(recordType: "Profile", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        
        publicDatabase.perform(query, inZoneWith: nil) { (results, error) -> Void in
            if error != nil {
                print(error as Any)
            }
            else {
                print(results as Any)
                
                for result in results! {
                    self.arrayName.append(result)
                }
                
                OperationQueue.main.addOperation({ () -> Void in
                    self.tableView.reloadData()
                })
            }
        }
        
    }
    
    @IBAction func btnAddName(_ sender: Any) {
        let alert = UIAlertController(title: "Add Name", message: "Enter your name below", preferredStyle: .alert)
        alert.addTextField { (textField) in
            self.textFieldName = textField
            self.textFieldName.placeholder = "e.g John"
            self.textFieldName.addTarget(self, action: #selector(self.validation), for: UIControl.Event.editingChanged)
        }
        action = (UIAlertAction(title: "Add", style: .default, handler: { (UIAlertAction) in
            
            self.saveData(data: self.textFieldName.text! as CKRecordValue)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: {
                self.arrayName.removeAll()
                self.loadData()
                self.tableView.reloadData()
            })
        }))
        action.isEnabled = false
        alert.addAction(action)
        alert.actions[0].isEnabled = false
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        self.present(alert, animated: true)
    }
    
    
    @IBAction func btnTest(_ sender: Any) {
    }
    
    
    @IBAction func unWindSegueToVC1(sender : UIStoryboardSegue){
    }
    
}


extension ViewController : UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return arrayName.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")
        
        let rec : CKRecord = arrayName[indexPath.row]
        
        cell?.textLabel?.text = rec.value(forKey: "name") as? String
        
        return cell!
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        let container = CKContainer.default()
        let publicDatabase = container.publicCloudDatabase
        
        
        if editingStyle == .delete {
            let rec = arrayName[indexPath.row]
            
            publicDatabase.delete(withRecordID: rec.recordID) { (returnRecord, error) in
                if error != nil {
                    print("Error when delete the data")
                }
                else {
                    DispatchQueue.global(qos: .background).async {
                        self.arrayName.remove(at: indexPath.row)
                        DispatchQueue.main.async {
                            tableView.deleteRows(at: [indexPath], with: .fade)
                        }
                    }
                }
            }
        }
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let alert = UIAlertController(title: "Update your name", message: "input your name below here", preferredStyle: .alert)
        alert.addTextField { (textField) in
            self.textFieldName = textField
            self.textFieldName.placeholder = "e.g John"
            self.textFieldName.addTarget(self, action: #selector(self.validation), for: UIControl.Event.editingChanged)
        }
        
        actionUpdate = UIAlertAction(title: "Update", style: .default, handler: { (UIAlertAction) in
            let container = CKContainer.default()
            let publicDatabase = container.publicCloudDatabase
            
            let rec = self.arrayName[indexPath.row]
            
            publicDatabase.fetch(withRecordID: rec.recordID) { (record, error) in
                if (error != nil) {
                    print("error when fecthing database from cloud kit")
                }
                else {
                    DispatchQueue.main.async {
                         rec.setValue(self.textFieldName.text, forKey: "name")
                    }
                    let database = CKContainer.default().publicCloudDatabase
                    database.save(rec) { (rec, error) in
                        if error != nil {
                            print(error!.localizedDescription + "Error when saving data")
                        }
                        else {
                            print("succesfully saved")
                        }
                    }
                    
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0, execute: {
                self.arrayName.removeAll()
                self.loadData()
                self.tableView.reloadData()
            })
            
            tableView.deselectRow(at: indexPath, animated: true)
        })
        actionUpdate.isEnabled = false
        alert.addAction(actionUpdate)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (UIAlertAction) in
            tableView.deselectRow(at: indexPath, animated: true)
        }))
        self.present(alert, animated: true)
    }
    
}

