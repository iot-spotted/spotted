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

class ProfileViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet var label: UILabel?
    @IBOutlet var scoreLabel: UILabel?
    @IBOutlet var scoreboardLabel: UILabel?
        
    @IBOutlet weak var scoreboardTable: UITableView!
    
    let cellReuseIdentifier = "cell"
    var users:[GameUser] = []
    
    override func viewDidLoad() {
        let topBar: UINavigationBar = UINavigationBar(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 60))
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
        
        label?.text = getMyName()
    
        EVCloudData.publicDB.dao.query(GameUser(), predicate: NSPredicate(format: "User_ID == '\(getMyRecordID())'"),
           completionHandler: { results, stats in
            EVLog("query : result count = \(results.count)")
            if (results.count == 1) {
                print("setting user...")
                let user = results[0]
                self.scoreLabel?.text = String(user.Score)
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
            self.users.insert(item, at: 0)
        }, updatedHandler: { item, dataIndex in
            NSLog("USER VOTE updated (shouldn't happen)" + item.recordID.recordName + " name:" + item.Name + " score:" + String(item.Score) + " index:" + String(dataIndex))
            if (item.User_ID == getMyRecordID()) {
                self.scoreLabel?.text = String(item.Score)
            }
            self.users[dataIndex] = item
            self.scoreboardTable.reloadData()
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
    
    // number of rows in table view
    func tableView(_ scoreboardTable: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.users.count
    }
    
    // create a cell for each table view row
    func tableView(_ scoreboardTable: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // create a new cell if needed or reuse an old one
        let cell:UITableViewCell = self.scoreboardTable.dequeueReusableCell(withIdentifier: cellReuseIdentifier) as UITableViewCell!
        
        // set the text from the data model
        cell.textLabel?.text = "\(self.users[indexPath.row].Name)   \(self.users[indexPath.row].Score)"
        
        return cell
    }
    
    // method to run when table view cell is tapped
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("You tapped cell number \(indexPath.row).")
    }

    
    func loadCamera() {
        NotificationCenter.default.post(name: Notification.Name(rawValue:"loadCamera"), object: nil)
    }
}

