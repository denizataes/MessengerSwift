import UIKit
import MessageKit
import InputBarAccessoryView


struct Message: MessageType{
    public var sender: MessageKit.SenderType
    public var messageId: String
    public var sentDate: Date
    public var kind: MessageKit.MessageKind
}

extension MessageKind {
    var messageKindString: String {
        switch self {
            
        case .text(_):
            return "text"
        case .attributedText(_):
            return "attributed_text"
        case .photo(_):
            return "photo"
        case .video(_):
            return "video"
        case .location(_):
            return "location"
        case .emoji(_):
            return "emoji"
        case .audio(_):
            return "audio"
        case .contact(_):
            return "contact"
        case .linkPreview(_):
            return "link"
        case .custom(_):
            return "custom"
        }
    }
}

struct Sender: SenderType{
    public var photoURL: String
    public var senderId: String
    public var displayName: String
}

class ChatViewController: MessagesViewController {
    
    public static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .long
        formatter.locale = .current
        return formatter
    }()
    
    public let otherUserEmail: String
    
    private let conversationId: String?
    public var isNewConversation = false
    
    private var messages = [Message]()
    
    private var selfSender: Sender? {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String
        else {
            return nil
        }
        
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        return Sender(photoURL: "",
                      senderId: safeEmail,
                      displayName: "Me")
    }


    init(with email: String, id: String?){
        self.conversationId = id
        self.otherUserEmail = email
        super.init(nibName: nil, bundle: nil)

    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messageInputBar.delegate = self
        
    }
    
    private func listenforMessages(id: String, shouldScrollToBottom: Bool){
        DatabaseManager.shared.getAllMessagesForConversation(with: id) {[weak self] result in
            switch result{
            case .success(let messages):
                print("success in getting messages")
                guard !messages.isEmpty else {
                    return
                }
                
                self?.messages = messages
                
                DispatchQueue.main.async {
                    self?.messagesCollectionView.reloadDataAndKeepOffset()

                    if shouldScrollToBottom{
                        self?.messagesCollectionView.scrollToLastItem()
                    }

                }
            case .failure(let error):
                print("failed to get messages: \(error)")
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        messageInputBar.inputTextView.becomeFirstResponder() 
        if let conversationId = conversationId {
            listenforMessages(id: conversationId, shouldScrollToBottom: true)
        }
    }
    
}
extension ChatViewController: InputBarAccessoryViewDelegate{
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        guard !text.replacingOccurrences(of: " ", with: "").isEmpty,
              let selfsender = self.selfSender,
              let messageId = createMessageId() else {
            return
        }
        
        // Send Message
        let message = Message(sender: selfsender,
                              messageId: messageId,
                              sentDate: Date(),
                              kind: .text(text))
        if isNewConversation {

            DatabaseManager.shared.createNewConversation(with: otherUserEmail, name: self.title ?? "User", firstMessage: message) {[weak self] success in
                if success {
                    print("message sent")
                    self?.isNewConversation = false
                }
                else{
                    print("failed to send")
                }
            }
        }
        else{
            guard let conversationId = conversationId,
                  let name = self.title else{
                return
            }
            DatabaseManager.shared.sendMessage(to: conversationId, otherUserEmail: otherUserEmail, name: name, newMessage: message) { success in
                if success
                {
                    print("message sent")
                }
                else{
                    print("failed to send")
                }
            }
        }
    }
    
    private func createMessageId() -> String?{
        
        guard let currentUserEmail = UserDefaults.standard.value(forKey: "email") as? String
        else {
            return nil
        }
        
        let safeCurrentEmail = DatabaseManager.safeEmail(emailAddress: currentUserEmail)
        
    
        let dateString = Self.dateFormatter.string(from: Date())
        let newIdentifier = "\(otherUserEmail)_\(safeCurrentEmail)_\(dateString)"
        
        print("Created MessageId : \(newIdentifier)")
        return newIdentifier
    }
}

extension ChatViewController: MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate{
    
    func currentSender() -> MessageKit.SenderType {
        if let sender = selfSender{
            return sender
        }
        fatalError("Self sender is nil email should bu cached !!!")
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessageKit.MessagesCollectionView) -> MessageKit.MessageType {
        return messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessageKit.MessagesCollectionView) -> Int {
        messages.count
    }
    
}
