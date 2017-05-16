//
//  LoginController.swift
//  Quintenvanderpost-pset6
//
//  Created by Quinten van der Post on 11/12/2016.
//  Copyright © 2016 Quinten van der Post. All rights reserved.
//

import UIKit
import Firebase
import SwiftyJSON

class LoginController: UIViewController, UITextFieldDelegate  {
    
    // MARK: Outlets
    @IBOutlet weak var loginEmail: UITextField!
    @IBOutlet weak var loginPass: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        loginPass.delegate = self
        loginPass.tag = 0
        FIRAuth.auth()!.addStateDidChangeListener() { auth, user in
            if user != nil {
                self.performSegue(withIdentifier: "segueLogin", sender: nil)
            }
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Hide the navigation bar on the this view controller
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Show the navigation bar on other view controllers
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        if textField.tag == 0 {
            loginDidTouch(self)
        }
        loginDidTouch(self)
        return true
    }
    
    func loginUser(login: String, password: String) {
        
        FIRAuth.auth()!.signIn(withEmail: login,
                               password: password) { (user, error) in
                                let alert = UIAlertController(title: "Oops!",
                                                              message: "This combination of login and password does not match any user in the database.",
                                                              preferredStyle: .alert)
                                alert.addAction(UIAlertAction(title: "Continue", style: .default))
                                self.present(alert,animated: true, completion: nil)
        }
    }
    
    @IBAction func loginDidTouch(_ sender: AnyObject) {
        self.loginUser(login: loginEmail.text!, password: loginPass.text!)
    }
    
    @IBAction func registerDidTouch(_ sender: AnyObject) {
        let alert = UIAlertController(title: "Registration",
                                      message: "Register a new account",
                                      preferredStyle: .alert)
        alert.addTextField { (textField) in
            textField.placeholder = "User Email"
        }
        alert.addTextField { (textField) in
            textField.placeholder = "Password"
            textField.isSecureTextEntry = true
        }
        let emailField = alert.textFields![0]
        let passwordField = alert.textFields![1]
        
        
        let saveAction = UIAlertAction(title: "Add", style: .default) { _ in
            guard emailField.text != nil, passwordField.text != nil else { return }
                // TODO: Implement GitAPI and make classes
                FIRAuth.auth()!.createUser(withEmail: emailField.text!,
                                           password: passwordField.text!) { user, error in
                                                if error == nil {
                                                let ref : FIRDatabaseReference!
                                                ref = FIRDatabase.database().reference()
                                                ref.child("users").child(user!.uid).setValue([
                                                        "Email": emailField.text!,
                                                        "Nickname": emailField.text!,
                                                        "Repos": [],
                                                        "PostCount": 0])
                                                self.loginUser(login: emailField.text!, password: passwordField.text!)
                                                } else {
                                                    let alert = UIAlertController(title: "Oops!",
                                                                                  message: "These credentials are not allowed.",
                                                                                  preferredStyle: .alert)
                                                    alert.addAction(UIAlertAction(title: "Continue", style: .default))
                                                    self.present(alert,animated: true, completion: nil)
                                            }
                                        }
                                       
        }
        
        let cancelAction = UIAlertAction(title: "Cancel",
                                         style: .default)

    
        alert.addAction(saveAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true, completion: nil)
    }
}
