//
//  ProfileViewController.swift
//  MessengerSwift
//
//  Created by Deniz Ata Eş on 6.01.2023.
//

import UIKit
import FirebaseAuth
import FBSDKLoginKit
import SDWebImage
import GoogleSignIn

enum ProfileViewModelType{
    case info, logout
}

struct ProfileViewModel{
    let viewModelType: ProfileViewModelType
    let title: String
    let handler: (() -> Void)?
}

class ProfileViewController: UIViewController {
    
    @IBOutlet var tableView: UITableView!
    var data = [ProfileViewModel]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(ProfileTableViewCell.self, forCellReuseIdentifier: ProfileTableViewCell.identifier)
        data.append(ProfileViewModel(viewModelType: .info, title: "Name: \(UserDefaults.standard.value(forKey: "name") as? String ?? "No Name" )", handler: nil))
        
        data.append(ProfileViewModel(viewModelType: .info, title: "Email: \(UserDefaults.standard.value(forKey: "email") as? String ?? "No Email" )", handler: nil))
        
        data.append(ProfileViewModel(viewModelType: .logout, title: "Log Out", handler: {
            [weak self] in
            
            guard let strongSelf = self else{
                return
            }
            
            let actionSheet = UIAlertController(title: "",
                                                message: "",
                                                preferredStyle: .actionSheet)
            actionSheet.addAction(UIAlertAction(title: "Log Out",
                                                style: .destructive,handler: { [weak self] _ in
                guard let strongSelf = self else {return}
                
                UserDefaults.standard.setValue(nil, forKey: "name")
                UserDefaults.standard.setValue(nil, forKey: "email")
                
                //Log Out Facebook
                
                FBSDKLoginKit.LoginManager().logOut()
                GIDSignIn.sharedInstance()?.signOut()
                do{
                    try FirebaseAuth.Auth.auth().signOut()
                    let vc = LoginViewController()
                    let nav = UINavigationController(rootViewController: vc)
                    nav.modalPresentationStyle = .fullScreen
                    strongSelf.present(nav,animated: true)
                }catch{
                    print("Failed to log out")
                }
            }))
            
            actionSheet.addAction(.init(title: "Cancel", style: .cancel))
            
            strongSelf.present(actionSheet, animated: true)
            
            
            
        }))
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableHeaderView = createTableHeader()
    }
    
    func createTableHeader() -> UIView? {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else{
            return nil
        }
        
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        let filename = safeEmail + "_profile_picture.png"
        
        let path = "images/" + filename
        
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: self.view.width, height: 300))
        
        headerView.backgroundColor = .link
        let imageView = UIImageView(frame: CGRect(x: (headerView.width-150) / 2, y: 75, width: 150, height: 150))
        
        
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = .white
        imageView.layer.borderColor = UIColor.white.cgColor
        imageView.layer.borderWidth = 3
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = imageView.width/2
        headerView.addSubview(imageView)
        
        StorageManager.shared.downloadURL(for: path) { result in
            switch result{
                
            case .success(let url):
                imageView.sd_setImage(with: url,completed: nil)
                
            case .failure(let error):
                print("failed to get download url: \(error)")
                
            }
        }
        
        return headerView
    }
}
extension ProfileViewController: UITableViewDelegate, UITableViewDataSource{
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let viewModel = data[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: ProfileTableViewCell.identifier,
                                                 for: indexPath) as! ProfileTableViewCell
        cell.setUp(with: viewModel)
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        data[indexPath.row].handler?()
    }
}

class ProfileTableViewCell: UITableViewCell{
    
    static let identifier = "ProfileTableViewCell"
    
    public func setUp(with viewModel: ProfileViewModel){
        self.textLabel?.text = viewModel.title
        switch viewModel.viewModelType{
        case .info:
            self.textLabel?.textAlignment = .left
            self.selectionStyle = .none
            
        case .logout:
            self.textLabel?.textColor = .red
            self.textLabel?.textAlignment = .center
        }
    }
}
