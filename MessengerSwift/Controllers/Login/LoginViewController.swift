//
//  LoginViewController.swift
//  MessengerSwift
//
//  Created by Deniz Ata Eş on 6.01.2023.
//

import UIKit
import Firebase
import FBSDKLoginKit
import GoogleSignIn
import JGProgressHUD

class LoginViewController: UIViewController {

    private let spinner = JGProgressHUD(style: .dark)
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.clipsToBounds = true
        return scrollView
    }()
    
    private let emailField: UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .continue
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.gray.cgColor
        field.placeholder = "Email Address..."
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .white
        return field
    }()
    
    
    private let passwordField: UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .done
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "Password..."
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .white
        field.isSecureTextEntry = true
        return field
    }()
    
    private let imageView: UIImageView = {
        let imageview = UIImageView()
        imageview.image = UIImage(named: "logo")
        imageview.contentMode = .scaleAspectFit
        return imageview
    }()
    
    
    private let loginButton: UIButton = {
        let button = UIButton()
        button.setTitle("Log In", for: .normal)
        button.backgroundColor = .link
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.layer.masksToBounds = true
        button.titleLabel?.font = .systemFont(ofSize: 20,weight: .bold)
        return button
    }()
    
    private let facebookLoginButton : FBLoginButton = {
        let button = FBLoginButton()
        button.permissions = ["public_profile", "email"]
        return button
    }()
    
    private let googleLogInButton = GIDSignInButton()
    
    private var loginObserver: NSObjectProtocol?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loginObserver = NotificationCenter.default.addObserver(forName: .didLogInNotification,
                                                               object: nil,
                                                               queue: .main) {[weak self] _ in
            guard let strongSelf = self else { return }
            strongSelf.navigationController?.dismiss(animated: true)
            
        }
        
        
        
        GIDSignIn.sharedInstance()?.presentingViewController = self
        
        
        title = "Log In"
        view.backgroundColor = .white
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Register",
            style: .done,
            target: self,
            action: #selector(didTapRegister))
        
        
        loginButton.addTarget(self, action: #selector(loginButtonTapped), for: .touchUpInside)
        
        emailField.delegate = self
        passwordField.delegate = self
        facebookLoginButton.delegate = self
        //Add Subviews
        view.addSubview(scrollView)
        
        scrollView.addSubview(imageView)
        scrollView.addSubview(emailField)
        scrollView.addSubview(passwordField)
        scrollView.addSubview(loginButton)
        scrollView.addSubview(facebookLoginButton)
        scrollView.addSubview(googleLogInButton)
        
    }

    deinit {
        if loginObserver != nil{
            NotificationCenter.default.removeObserver(loginObserver!)
        }
    }

override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    scrollView.frame = view.bounds //ekranın tamamı
    
    
    let size = view.width/3
    imageView.frame = CGRect(x: (scrollView.width-size)/2,
                             y: 20,
                             width: size,
                             height: size
    )
    
    emailField.frame = CGRect(x: 30,
                              y: imageView.bottom + 10,
                              width: scrollView.width-60,
                              height: 52)
    
    passwordField.frame = CGRect(x: 30,
                                 y: emailField.bottom + 10,
                                 width: scrollView.width-60,
                                 height: 52)
    
    loginButton.frame = CGRect(x: 30,
                               y: passwordField.bottom + 10,
                               width: scrollView.width-60,
                               height: 52)
    
    facebookLoginButton.frame = CGRect(x: 30,
                                       y: loginButton.bottom + 10,
                                       width: scrollView.width-60,
                                       height: 52)
    
    
    googleLogInButton.frame = CGRect(x: 30,
                                     y: facebookLoginButton.bottom + 10,
                                     width: scrollView.width-60,
                                     height: 52)
    
}

@objc private func loginButtonTapped(){
    
    emailField.resignFirstResponder()
    passwordField.resignFirstResponder()
    
    guard let email = emailField.text, let password = passwordField.text, !email.isEmpty, !password.isEmpty, password.count >= 6 else {
        alertUserLoginError()
        return
    }
    spinner.show(in: view)
    
    FirebaseAuth.Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
        
        guard let strongSelf = self else{ return }
        DispatchQueue.main.async {
            strongSelf.spinner.dismiss()
        }
        
        
        guard let result = authResult, error == nil else {
            print("Failed to log in user with email: \(email)")
            return
        }
        strongSelf.navigationController?.dismiss(animated: true)
        let user = result.user
        print("Logged In User: \(user)")
        
    }
    
}

func alertUserLoginError(){
    
    let alert = UIAlertController(
        title: "Woops",
        message: "Please enter all information to log in",
        preferredStyle: .alert)
    alert.addAction(
        UIAlertAction(
            title: "Dismiss",
            style: .cancel)
    )
    present(alert,animated: true)
}

@objc private func didTapRegister() {
    let vc = RegisterViewController()
    vc.title = "Create Account"
    navigationController?.pushViewController(vc, animated: true)
}

}

extension LoginViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailField{
            passwordField.becomeFirstResponder()
        }
        else if textField == passwordField{
            loginButtonTapped()
        }
        return true
    }
}

extension LoginViewController: LoginButtonDelegate {
    func loginButtonDidLogOut(_ loginButton: FBSDKLoginKit.FBLoginButton) {
        //no operation
    }
    
    func loginButton(_ loginButton: FBSDKLoginKit.FBLoginButton, didCompleteWith result: FBSDKLoginKit.LoginManagerLoginResult?, error: Error?) {
        guard let token = result?.token?.tokenString else {
            print("User failed to log in with facebook")
            return
        }
        let facebookRequest = FBSDKLoginKit.GraphRequest(graphPath: "me", parameters: ["fields": "email, first_name, last_name, picture.type(large)"], tokenString: token, version: nil, httpMethod: .get)
        facebookRequest.start { _, result, error in
            guard let result = result as? [String: Any],
                  error == nil  else {
                print("Failed to make facebook graph request")
                return
            }
            
            print(result)
            
            
            guard let firstName = result["first_name"] as? String,
                  let lastName = result["last_name"] as? String,
                  let email = result["email"] as? String,
                  let picture = result["picture"] as? [String: Any],
                  let data = picture["data"] as? [String: Any],
                  let pictureUrl = data["url"] as? String else {
                print("Failed to get email and name from facebook result")
                return
            }
            
            
            DatabaseManager.shared.userExist(with: email) { exists in
                if !exists {
                    let chatUser = ChatAppUser(
                        firstName: firstName,
                        lastName: lastName,
                        emailAddress: email)
                    
                    DatabaseManager.shared.insertUser(with: chatUser) { success in
                        if success {
                            
                            guard let url = URL(string: pictureUrl) else {
                                return
                            }
                            URLSession.shared.dataTask(with: url, completionHandler: { data,_, _ in
                                guard let data = data else {
                                    return
                                }
                                let fileName = chatUser.profilePictureFileName
                                StorageManager.shared.uploadProfilePicture(with: data, fileName: fileName, completion: { result in
                                    switch result {
                                    case .success(let downloadUrl):
                                        UserDefaults.standard.set(downloadUrl, forKey: "")
                                        print(downloadUrl)
                                    case .failure(let error):
                                        print("Storage manager error : \(error)")
                                    }
                                })
                            }).resume()
                        }
                    }
                }
                
                let credential = FacebookAuthProvider.credential(withAccessToken: token)
                FirebaseAuth.Auth.auth().signIn(with: credential) { [weak self] authResult, error in
                    guard let strongSelf = self else{ return }
                    guard authResult != nil, error == nil else{
                        if let error = error {
                            print("Facebook credential login failed, MFA may be need - \(error)")
                        }
                        return
                    }
                    print("Succesfully logged in with Facebook")
                    strongSelf.navigationController?.dismiss(animated: true)
                }
            }
            
            
        }
        
    }
    
}
