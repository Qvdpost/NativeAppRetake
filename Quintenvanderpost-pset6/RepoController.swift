//
//  RepoController.swift
//  Quintenvanderpost-pset6
//
//  Created by Quinten van der Post on 11/12/2016.
//  Copyright © 2016 Quinten van der Post. All rights reserved.
//

import UIKit
import Firebase
import SwiftyJSON
import AZDropdownMenu

class RepoController: UITableViewController {
    
    // MARK Outlets:
    @IBOutlet var repoTable: UITableView!
    
    // Mark dropdown:
    let titles = ["Account details", "Logout"]
    
    
    // MARK Constants:
    let baseRef = FIRDatabase.database().reference()
    let ref = FIRDatabase.database().reference(withPath: "repo-list")
    let usersRef = FIRDatabase.database().reference(withPath: "online")
    
    // MARK: Properties
    var repos: [Repo] = []
    var user: User!
    var userRef: FIRDatabaseReference!
    var menu: AZDropdownMenu!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Your Repositories"
        
        // Construct dropdown menu and button
        self.constructMenu()
        let button = UIBarButtonItem(image: UIImage(named: "options"), style: .plain, target: self, action: #selector(RepoController.showDropdown))
        navigationItem.leftBarButtonItem = button
        
        // Initialize User info
        let userID = FIRAuth.auth()?.currentUser?.uid
        self.userRef = baseRef.child("users").child(userID!)
        
        // Listener event for online users.
        FIRAuth.auth()!.addStateDidChangeListener { auth, user in
            guard let user = user else { return }
            self.user = User(authData: user)
            let currentUserRef = self.usersRef.child(self.user.uid)
            currentUserRef.setValue(self.user.email)
            currentUserRef.onDisconnectRemoveValue()
        }

        // Synchronize Data to tableView
        userRef.child("savedRepos").observe(.value, with: { snapshot in
            var repoIDs = [String]()
            let repoDict = snapshot.value as? [String : Bool] ?? [:]
            for (repoID, bool) in repoDict {
                if bool == true {
                    repoIDs.append(repoID)
                }
            }
            var repoList: [Repo] = []
            for repoID in repoIDs {
                self.ref.child(repoID).observeSingleEvent(of: .value, with: { (snapshot) in
                    let repo = Repo(snapshot: snapshot)
                    repoList.append(repo)
                    self.repos = repoList
                    self.repoTable.reloadData()
                })
            }
        })
        
        // Placeholder values for tableView
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 60
    }
    
    // Mark: Functions
    
    func gitRepoSearch(owner: String, name: String) -> JSON {
        
        // Search git for specified repository and return data as json.
        let url = URL(string: "https://api.github.com/search/repositories?q=\(owner)/\(name)")!
        let data = try? Data(contentsOf: url)
        let json = JSON(data: data!)

        return json
    }
    
    // Adds a github repository or alerts if no matching/alike repository is found.
    @IBAction func addButtonDidTouch(_ sender: AnyObject) {
        
        let notFoundAlert = UIAlertController(title: "Oops!",
                                              message: "Could not find specified repository. :(",
                                              preferredStyle: .alert)
        
        let alert = UIAlertController(title: "Git Repo",
                                      message: "Add a repository",
                                      preferredStyle: .alert)
        
        alert.addTextField { (textField) in
            textField.placeholder = "Github Repo Owner"
        }
        alert.addTextField { (textField) in
            textField.placeholder = "Github Repo Name"
        }
        
        let gitOwner = alert.textFields![0]
        let gitRepo = alert.textFields![1]
        
        let saveAction = UIAlertAction(title: "Add", style: .default) { _ in
            guard gitOwner.text != nil, gitRepo.text != nil else { return }

            let repoJson = self.gitRepoSearch(owner: gitOwner.text!, name: gitRepo.text!)
            // If json is empty no repo was found.
            guard repoJson["total_count"] != 0 else {
                
                self.present(notFoundAlert, animated: true, completion: nil)
                return
            }
            
            let name = repoJson["items"][0]["name"].stringValue
            let description = repoJson["items"][0]["description"].stringValue
            let owner = repoJson["items"][0]["owner"]["login"].stringValue
            let url = repoJson["items"][0]["owner"]["html_url"].stringValue
            let updateDate = repoJson["items"][0]["updated_at"].stringValue
            let id = repoJson["items"][0]["id"].intValue
            let stringID = String(id)
                                        
            let repo = Repo(name: name, description: description, owner: owner, url: url, updateDate: updateDate, id: id)

            // If repo was already in database, no database adding is required.
            self.ref.child(stringID).observeSingleEvent(of: .value, with: { (snapshot) in
                if snapshot.exists() == false {
                    
                    self.ref.updateChildValues([stringID : (repo.toAnyObject())])
                }
                
                // Update users saved repos.
                self.userRef.child("savedRepos/\(stringID)").setValue(true)
            })
            
        }
        
        let cancelAction = UIAlertAction(title: "Cancel",
                                         style: .default)
        
        let abortAction = UIAlertAction(title: "Abort",
                                        style: .default)
        
        // If repo was not found; allow for another try at searching without losing textfields.
        let retryAction = UIAlertAction(title: "Retry", style: .default) { _ in guard gitOwner.text != nil, gitRepo.text != nil else { return }
            alert.textFields![0].text = gitOwner.text
            alert.textFields![1].text = gitRepo.text
            self.present(alert, animated: true, completion: nil)
        }
        
        alert.addAction(saveAction)
        alert.addAction(cancelAction)
        notFoundAlert.addAction(retryAction)
        notFoundAlert.addAction(abortAction)
        
        present(alert, animated: true, completion: nil)
    }

    @IBAction func logoutDidTouch(_ sender: AnyObject) {
        try! FIRAuth.auth()!.signOut()
        performSegue(withIdentifier: "segueToLoginController", sender: nil)
    }
    
    func logoutUser() {
        
        try! FIRAuth.auth()!.signOut()
        performSegue(withIdentifier: "segueToLoginController", sender: nil)
    }
    
    
    // Constructs a dropdown menu.
    func constructMenu() {
        
        menu = AZDropdownMenu(titles: titles)
        menu.cellTapHandler = { [weak self] (indexPath: IndexPath) -> Void in
            let title: String = self!.titles[indexPath.row]
            switch  title {
            case "Account details":
                self?.performSegue(withIdentifier: "segueToAccountDetailsViewController", sender: title)
            case "Logout":
                self?.logoutUser()
            default:
                print("Err don't get this")
            }
            
        }
    }
    
    func showDropdown() {
        if (self.menu?.isDescendant(of: self.view) == true) {
            self.menu?.hideMenu()
        } else {
            self.menu?.showMenuFromView(self.view)
        }
    }
    
    

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return repos.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = repoTable.dequeueReusableCell(withIdentifier: "RepoCell", for: indexPath) as! RepoCell
        let repo = repos[indexPath.row]
     
        cell.name.text = repo.name
        cell.name.font = UIFont.boldSystemFont(ofSize: 16.0)
        
        // Add placeholder dashes for empty descriptions.
        if repo.description != "" {
            cell.repoDescription.text = repo.description
        } else {
            cell.repoDescription.text = "--------"
        }
        cell.repoDescription.font = UIFont.italicSystemFont(ofSize: 14.0)
        cell.updateDate.text = repo.owner
     
        return cell
    }
    

    
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete {
            let repo = repos[indexPath.row]
            let repoID = repo.id
            userRef.child("savedRepos/\(repoID)").setValue(false)
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let selectedRow = repoTable.indexPathForSelectedRow
        performSegue(withIdentifier: "segueToMCController", sender: selectedRow)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "segueToMCController" {
            
            let indexPath = self.repoTable.indexPathForSelectedRow
            let repo = repos[(indexPath?.row)!]
            let destination = segue.destination as! MCViewController
            
            destination.repo = repo
            destination.user = self.user
            destination.userRef = self.userRef
        }
        else if segue.identifier == "segueToAccountDetailsViewController" {
            
            let destination = segue.destination as! AccountDetailsViewController
            
            destination.user = self.user
            destination.userRef = self.userRef
        }
    }

}
