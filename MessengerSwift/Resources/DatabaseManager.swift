//
//  DatabaseManager.swift
//  MessengerSwift
//
//  Created by Deniz Ata Eş on 25.01.2023.
//

import Foundation
import FirebaseDatabase

final class DatabaseManager {
    
    static let shared = DatabaseManager()
    
    private let database = Database.database().reference()
    

}
// MARK: - Account Management
extension DatabaseManager{
    public func userExist(with email: String,
                          completion: @escaping ((Bool) -> Void)){
        var safeEmail = email.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        
        database.child(safeEmail).observeSingleEvent(of: .value) { snapshot in
            guard snapshot.value as? String != nil else {
                completion(false)
                return
            }
            
            completion(true)
            
        }
    }
    ///Inserts new user to database
    public func insertUser(with user: ChatAppUser, completion: @escaping (Bool) -> Void){
        database.child(user.safeEmail).setValue([
            "first_name" : user.firstName,
            "last_name": user.lastName]) { error, _ in
                guard error == nil else{
                    print("failed to write to database")
                    completion(false)
                    return
                }
                completion(true)
            }
    }
    
    
}


struct ChatAppUser {
    let firstName: String
    let lastName: String
    let emailAddress: String
    var safeEmail: String {
        var safeEmail = emailAddress.replacingOccurrences(of: ".", with:   "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
    var profilePictureFileName: String {
        return "\(safeEmail)_profile_picture.png"
    }
}
