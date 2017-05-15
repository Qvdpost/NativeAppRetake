//
//  AccountDetailsViewController.swift
//  Quintenvanderpost-pset6
//
//  Created by Quinten on 15/05/2017.
//  Copyright © 2017 Quinten van der Post. All rights reserved.
//

import UIKit
import Firebase

class AccountDetailsViewController: UIViewController, UITextFieldDelegate {
    
    // MARK: Constants
    let baseRef = FIRDatabase.database().reference()
    
    // MARK: Properties
    var userRef: FIRDatabaseReference!
    var user: User!
    var nicknameText: String = ""
    var activeTextField = UITextField()
//    var credential: FIRAuthCredential
    
    // MARK: Outlets
    @IBOutlet weak var nickName: UITextField!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var currentPassword: UITextField!
    @IBOutlet weak var newPassword: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Account Details"
        userRef.observeSingleEvent(of: .value, with: { (snapshot) in
            // Get user value
            let value = snapshot.value as? NSDictionary
            self.nicknameText = value?["Nickname"] as? String ?? ""
            self.nickName.text = self.nicknameText
        })
        
        nickName.delegate = self
        nickName.tag = 0
        
        currentPassword.delegate = self
        currentPassword.tag = 1
        
        newPassword.delegate = self
        newPassword.tag = 2
        
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(AccountDetailsViewController.hideKeyboard))
        tapGesture.cancelsTouchesInView = true
        scrollView.addGestureRecognizer(tapGesture)
        
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(AccountDetailsViewController.keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(AccountDetailsViewController.keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)

        // Do any additional setup after loading the view.
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        self.activeTextField = textField
        switch textField.tag {
        case 0:
            self.constructEditButtons()
        case 1:
            self.constructEditButtons()
        case 2:
            self.constructEditButtons()
        default:
            print("This is not a textfield")
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        
        switch textField.tag {
        case 0:
            textField.text = self.nicknameText
            self.deconstructEditButtons()
        case 1:
            self.deconstructEditButtons()
            if self.activeTextField.tag != 2 {
                textField.text = ""
                newPassword.text = ""
            }
        case 2:
            self.deconstructEditButtons()
            if self.activeTextField.tag != 1 {
                textField.text = ""
                currentPassword.text = ""
            }
        default:
            print("This is not a textfield")
        }
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        self.activeTextField = textField
        return true
    }
    
    func cancelButtonTapped() {
        
        self.activeTextField.text = ""
        self.activeTextField.resignFirstResponder()
    }
    
    func doneButtonTapped() {
        
        switch self.activeTextField.tag {
        case 0:
            if let newNickname = activeTextField.text, newNickname != ""{
                updateNickname(newNickname: newNickname)
            } else {
//                Throw an alert!!
            }
            self.activeTextField.resignFirstResponder()
        case 1:
            self.newPassword.becomeFirstResponder()
        case 2:
            self.updatePassword(newPassword: self.activeTextField.text!)
        default:
            print("Implement more cases!!")
        }
    }
    
    func updatePassword(newPassword: String) {
        
        if reauthUser() {
            
            FIRAuth.auth()?.currentUser?.updatePassword(newPassword) { (error) in
                print("Could not update password")
            }
            self.newPassword.text = ""
            self.currentPassword.text = ""
            self.activeTextField.resignFirstResponder()
        }
        
    }
    
    func reauthUser() -> Bool {
        
        let curUser = FIRAuth.auth()?.currentUser
        var credential: FIRAuthCredential
        
        credential = FIREmailPasswordAuthProvider.credential(withEmail: user.email, password: self.currentPassword.text!)
        var success = false
        curUser?.reauthenticate(with: credential) { error in
            if let error = error {
                print("Login credentials incorrect!")
                print(error)
            } else {
                success = true
            }
        }
        return success
    }
    
    func updateNickname(newNickname: String) {
        
        userRef.child("Nickname").setValue(newNickname)
        self.nicknameText = newNickname
    }
    
    func constructEditButtons() {
        
        let cancelButton = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(self.cancelButtonTapped))
        let doneButton = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(self.doneButtonTapped))
        self.navigationItem.setHidesBackButton(true, animated: true)
        self.navigationItem.setLeftBarButton(cancelButton, animated: true)
        self.navigationItem.setRightBarButton(doneButton, animated: true)
    }
    
    func deconstructEditButtons() {
        
        self.navigationItem.leftBarButtonItem = nil
        self.navigationItem.rightBarButtonItem = nil
        self.navigationItem.setHidesBackButton(false, animated: true)
    }
    
    func hideKeyboard() {
        self.view.endEditing(true)
    }
    
    func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            if self.bottomConstraint.constant < keyboardSize.height{
                UIView.animate(withDuration: 1, animations: {
                    self.bottomConstraint.constant += keyboardSize.height
                    self.view.layoutIfNeeded()
                })
            }
        }
    }
    
    func keyboardWillHide(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            if self.bottomConstraint.constant >= keyboardSize.height {
                UIView.animate(withDuration: 1, animations: {
                    self.bottomConstraint.constant -= keyboardSize.height
                    self.view.layoutIfNeeded()
                })
            }
        }
    }

    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}