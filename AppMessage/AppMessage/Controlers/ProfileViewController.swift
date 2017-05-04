//
//  ProfileViewController.swift
//  
//
//  Created by Jake Weiss on 2/22/17.
//
//

import UIKit
import CloudKit
import EVCloudKitDao
import MessageUI

class ProfileViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, MFMessageComposeViewControllerDelegate {
    
    @IBOutlet weak var crown: UIImageView!
    @IBOutlet var label: UILabel!
    @IBOutlet var scoreLabel: UILabel!
    @IBOutlet var scoreboardLabel: UILabel?
        
    @IBOutlet weak var scoreboardTable: UITableView!
    
    let cellReuseIdentifier = "cell"
    var gameController: GameController? = nil
    var users:[GameUser] = []
    
    override func viewDidLoad() {
        let topBar: UINavigationBar = UINavigationBar(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 60))
        topBar.tintColor = UIColor.white
        topBar.barStyle = UIBarStyle.blackOpaque
        self.view.addSubview(topBar)
        let barItem = UINavigationItem(title: "Profile")
        let back = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.camera, target: nil, action: #selector(loadCamera))
        barItem.rightBarButtonItem = back
        topBar.setItems([barItem], animated: false)
        
        self.scoreboardTable.register(UITableViewCell.self, forCellReuseIdentifier: cellReuseIdentifier)
        scoreboardTable.delegate = self
        scoreboardTable.dataSource = self
        
        initializeCommunication()
        
        label.text = getMyName()
    
        EVCloudData.publicDB.dao.query(GameUser(), predicate: NSPredicate(format: "User_ID == '\(getMyRecordID())'"),
           completionHandler: { results, stats in
            EVLog("query : result count = \(results.count)")
            if (results.count == 1) {
                print("setting user...")
                let user = results[0]
                self.scoreLabel.text = String(user.Score)
                self.scoreLabel?.font = UIFont(name: "Avenir-Black", size: 50)
            }
            return true
        }, errorHandler: { error in
            EVLog("<--- ERROR query User")
        })
    }
    
    func initializeCommunication(){
        EVCloudData.publicDB.connect(GameUser(), predicate: NSPredicate(value: true), orderBy: Descending(field: "Score"),filterId: "Score",
                                     completionHandler: { results, status in
                                        EVLog("Game User results = \(results.count)")
                                        if results.count > 0 {
                                            // TODO check for in progress votes
                                        }
                                        self.users = results
                                        self.scoreboardTable.reloadData()
                                        var position = 1
                                        var LeaderBoard = ""
                                        for user in results{
                                            LeaderBoard = LeaderBoard + "\(position).    \(user.Name)  \(user.Score)\n"
                                            position+=1
                                        }
                                        self.scoreboardLabel?.text = LeaderBoard
                                        return true
        }, insertedHandler: { item in
            EVLog("USER VOTE inserted " + item.recordID.recordName)
            //self.HandleNewUserVote(vote: item)
            self.updateGameUsers()
            //self.users.insert(item, at: 0)
        }, updatedHandler: { item, dataIndex in
            NSLog("USER VOTE updated (shouldn't happen)" + item.recordID.recordName + " name:" + item.Name + " score:" + String(item.Score) + " index:" + String(dataIndex))
            self.updateGameUsers()
            if (item.User_ID == getMyRecordID()) {
                self.scoreLabel.text = String(item.Score)
            }
        }, deletedHandler: { recordId, dataIndex in
            EVLog("USER VOTE deleted!!! : \(recordId)")
            //self.LocalGroupState = nil
        }, dataChangedHandler: {
            EVLog("USER VOTE data changed!")
        }, errorHandler: { error in
            print("USER VOTE ERROR")
//            switch EVCloudKitDao.handleCloudKitErrorAs(error, retryAttempt: retryCount) {
//            case .retry(let timeToWait):
//                Async.background(after: timeToWait) {
//                    self.initializeCommunication(retryCount + 1)
//                }
//            case .fail:
//                Helper.showError("Could not load groupdata: \(error.localizedDescription)")
//            default: // For here there is no need to handle the .Success, and .RecoverableError
//                break
//            }
        });

    }
    
    func updateGameUsers(){
        EVCloudData.publicDB.dao.query(GameUser(), predicate: NSPredicate(value: true), orderBy: Descending(field: "Score"),
                                       completionHandler: { results, stats in
                                        
                                        self.users = results
                                        self.scoreboardTable.reloadData()
                                        if (self.users[0].Name == getMyName()){
                                            self.label.text = getMyName() + " 👑"
                                        }
                                        else{
                                            self.label.text = getMyName()
                                        }
                                        return true
        }, errorHandler: { error in
            EVLog("<--- ERROR query User")
        })
    }
    
    // number of rows in table view
    func tableView(_ scoreboardTable: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.users.count
    }
    
    // create a cell for each table view row
    func tableView(_ scoreboardTable: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // create a new cell if needed or reuse an old one
        let cell:UITableViewCell = self.scoreboardTable.dequeueReusableCell(withIdentifier: cellReuseIdentifier) as UITableViewCell!
        cell.selectionStyle = UITableViewCellSelectionStyle.none
        let maxSpace = 24
        var blanks = 1
        if (self.users[indexPath.row].Name.characters.count > maxSpace) {blanks = 1}
        else {blanks = maxSpace - self.users[indexPath.row].Name.characters.count}

        var text = self.users[indexPath.row].Name
        for _ in 1...blanks{
            text += " "
        }
        cell.textLabel?.text = text + "\(self.users[indexPath.row].Score)"
        cell.textLabel?.font = UIFont(name: "Courier", size: 16)
        if (self.users[indexPath.row].Name == getMyName()){
            cell.textLabel?.font = UIFont(name: "Courier-Bold", size: 16)
        }
        return cell
    }
    
    // method to run when table view cell is tapped
    func tableView(_ scoreboardTable: UITableView, didSelectRowAt indexPath: IndexPath) {
                print("You tapped cell number \(indexPath.row).")
    }

    
    func loadCamera() {
        NotificationCenter.default.post(name: Notification.Name(rawValue:"loadCamera"), object: nil)
    }
    
    @IBAction func addFriend(sender: UIButton) {
        if MFMessageComposeViewController.canSendText() == true {
        //let recipients:[String] = [""]
        let messageController = MFMessageComposeViewController()
        messageController.messageComposeDelegate  = self
        //messageController.recipients = recipients
        messageController.body = "Join me and " + GLOBAL_GROUP_NAME + " in our Spotted game!\n" + "iotSpotted://?token=" + (self.gameController?.LocalGroupState.recordID.recordName)!
        self.present(messageController, animated: true, completion: nil)
    } else {
        //handle text messaging not available
    }
    }

    
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if (self.users[0].Name == getMyName()){
            self.label.text = getMyName() + " 👑"
        }
        else{
            self.label.text = getMyName()
        }

    }
}

