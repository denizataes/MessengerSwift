//
//  StorageManager.swift
//  MessengerSwift
//
//  Created by Deniz Ata Eş on 29.01.2023.
//

import Foundation
import FirebaseStorage

final class StorageManager {
    
    static let shared = StorageManager()
    
    private let storage = Storage.storage().reference()
    
    public typealias UploadPictureCompletion = (Result<String, Error>) -> Void
    
    /*
     /images/denizataes-hotmail-com-profile_picture.png
     */
    
    ///Uploads picture to firebase storage and returns completion with url string to downlaod
    public func uploadProfilePicture(with data: Data,fileName: String,completion: @escaping UploadPictureCompletion){
        storage.child("images/\(fileName)").putData(data,metadata: nil) { metadata, error in
            
            guard error == nil else {
                print("failed to upload data to firebase for picture")
                completion(.failure(StorageErrors.failedToUpload))
                return
            }
            
            self.storage.child("images/\(fileName)").downloadURL { url, error in
                
                guard let url = url else {
                    print("Failed to get download url")
                    completion(.failure(StorageErrors.failedToGetDownloadUrl))
                    return
                }
                
                let urlString = url.absoluteString
                print("download URL returned: \(urlString)")
                completion(.success(urlString))
                
            }
            
        }
    }
    
    public func downloadURL(for path: String,  completion: @escaping (Result<URL, Error>) -> Void){
        let reference = storage.child(path)
        
        reference.downloadURL { url, error in
            guard let url = url, error == nil else {
                completion(.failure(StorageErrors.failedToGetDownloadUrl))
                return
            }
            
            completion(.success(url))
        }
        
    }
    
    
    public enum StorageErrors: Error{
        case failedToUpload
        case failedToGetDownloadUrl
    }
    
}
