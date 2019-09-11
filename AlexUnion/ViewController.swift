//
//  ViewController.swift
//  AlexUnion
//
//  Created by Viktor Puzakov on 9/3/19.
//  Copyright © 2019 Mac. All rights reserved.
//

import UIKit
import MultipeerConnectivity
import CoreData

class ViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    let searchController = UISearchController(searchResultsController: nil)
    
    var song: [Song] = []
    var filteredSong = [Song]()
    var newSong: Song!
    
    var peerID: MCPeerID!
    var mcSession: MCSession!
    var mcAdvertiserAssistant: MCAdvertiserAssistant!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        searchController.hidesNavigationBarDuringPresentation = false
        definesPresentationContext = true
        tableView.tableHeaderView = searchController.searchBar
        setupConnectivity()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchManaged = NSFetchRequest<NSManagedObject>(entityName: "Song")
        do {
            song = try managedContext.fetch(fetchManaged) as? [Song] ?? []
        } catch {
            print("failed fetch")
        }
        tableView.reloadData()
    }
    
    func setupConnectivity() {
        peerID = MCPeerID(displayName: UIDevice.current.name)
        mcSession = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        mcSession.delegate = self
    }

    @IBAction func showConnectivityAction(_ sender: UIBarButtonItem) {
        let actionSheet = UIAlertController(title: "Соединение с другими устройствами", message: "Хотите создать соединение?", preferredStyle: .alert)
        actionSheet.addAction(UIAlertAction(title: "Создать соединение", style: .default, handler: { (action: UIAlertAction) in
            self.mcAdvertiserAssistant = MCAdvertiserAssistant(serviceType: "ba-td", discoveryInfo: nil, session: self.mcSession)
            self.mcAdvertiserAssistant.start()
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Отмена", style: .default, handler: { (action: UIAlertAction) in
        }))
        
        self.present(actionSheet, animated: true, completion: nil)
    }
    
    @IBAction func addNewSongButtonTouched(_ sender: UIButton) {

        let alertController = UIAlertController(title: "Введите текст и исполнителя новой песни", message: nil, preferredStyle: .alert)
        alertController.addTextField { (textfield: UITextField!) in
            textfield.placeholder = "Текст песни"
        }
        alertController.addTextField { (textField) in
            textField.placeholder = "Исполнитель"
        }

        let alertActionSave = UIAlertAction(title: "Сохранить", style: .default) { (_) in
            if let alertTextFieldFirst = alertController.textFields?[0], alertTextFieldFirst.text != "" {
                if let alertTextFieldSecond = alertController.textFields?[1], alertTextFieldSecond.text != "" {
                    self.writeToCoreDataModelSong(text: alertTextFieldFirst.text!, singer: alertTextFieldSecond.text!)
                } else {
                    self.writeToCoreDataModelSong(text: alertTextFieldFirst.text!, singer: nil)
                }
            }
            self.tableView.reloadData()
        }
        let alertActionCancel = UIAlertAction(title: "Отмена", style: .default) { (_) in
            self.navigationController?.popViewController(animated: true)
        }
        alertController.addAction(alertActionSave)
        alertController.addAction(alertActionCancel)
        self.present(alertController, animated: true, completion: nil)
    }
    
    func writeToCoreDataModelSong(text: String, singer: String?) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let managedContext = appDelegate.persistentContainer.viewContext
        self.newSong = NSEntityDescription.insertNewObject(forEntityName: "Song",
                                                                 into: managedContext) as? Song
        self.newSong.text = text
        self.newSong.singer = singer
        song.append(self.newSong)
        do {
            try managedContext.save()
        } catch {
            print("falled save item")
        }
    }
}


extension ViewController: MCBrowserViewControllerDelegate, MCSessionDelegate {
    func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
        dismiss(animated: true, completion: nil)
    }
    
    func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
        dismiss(animated: true, completion: nil)
    }
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state {
        case MCSessionState.connected:
            print("Connected: \(peerID.displayName)")
        case MCSessionState.connecting:
            print("Connecting: \(peerID.displayName)")
        case MCSessionState.notConnected:
            print("Not connected: \(peerID.displayName)")
        @unknown default:
            break
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        
    }
    
    func sendTextOfSong(text: String) {
        if mcSession.connectedPeers.count > 0 {
            if let stringData = text.data(using: .utf8) {
                do {
                    try mcSession.send(stringData, toPeers: mcSession.connectedPeers, with: .reliable)
                } catch let error as NSError {
                    let ac = UIAlertController(title: "Отправка не осуществлена", message: error.localizedDescription, preferredStyle: .alert)
                    ac.addAction(UIAlertAction(title: "OK", style: .default))
                    present(ac, animated: true)
                }
            }
        }
    }
}


extension ViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isFiltering() {
            return filteredSong.count
        }
        return song.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "cell")
        
        if isFiltering() {
            if let singer = filteredSong[indexPath.row].singer {
                cell.textLabel?.text = filteredSong[indexPath.row].text + " (" + singer + ")"
            } else {
            cell.textLabel?.text = filteredSong[indexPath.row].text
            }
        } else {
            if let singer = song[indexPath.row].singer {
                cell.textLabel?.text = song[indexPath.row].text + " (" + singer + ")"
            } else {
                cell.textLabel?.text = song[indexPath.row].text
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView,
                            commit editingStyle: UITableViewCell.EditingStyle,
                            forRowAt indexPath: IndexPath) {
        if editingStyle == UITableViewCell.EditingStyle.delete {
            let alertController = UIAlertController(title: "Вы действительно хотите удалить песню?",
                                                    message: "Песня будет удалена без возможности восстановления",
                                                    preferredStyle: .alert)
            let alertActionDelete = UIAlertAction(title: "Удалить", style: .default) { (_) in
                guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
                let managedContext = appDelegate.persistentContainer.viewContext
                managedContext.delete(self.song[indexPath.row])
                self.song.remove(at: indexPath.row)
                do {
                    try managedContext.save()
                    self.tableView.reloadData()
                } catch {
                    print("Невозможно удалить песню, попробуйте позже")
                }
            }
            let alertActionCancel = UIAlertAction(title: "Отмена", style: .default, handler: nil)
            alertController.addAction(alertActionDelete)
            alertController.addAction(alertActionCancel)
            present(alertController, animated: true, completion: nil)
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var myIndex: Int = 0
        if isFiltering() {
            if let new = song.firstIndex(of: filteredSong[indexPath.row]) {myIndex = new}
        } else {
            myIndex = indexPath.row
        }

        let alertController = UIAlertController(title: "Играем?", message: "Текст: \(song[myIndex].text)", preferredStyle: .alert)
        let alertActionGo = UIAlertAction(title: "Начать", style: .default) { (_) in
            self.sendTextOfSong(text: self.song[myIndex].text)
            let gvc = GameViewController(song: self.song[myIndex], session: self.mcSession)
            self.navigationController?.pushViewController(gvc, animated: true)
        }
        let alertActionCancel = UIAlertAction(title: "Отмена", style: .default) { (_) in
            self.navigationController?.popViewController(animated: true)
        }
        alertController.addAction(alertActionGo)
        alertController.addAction(alertActionCancel)
        self.present(alertController, animated: true, completion: nil)
    }
}


extension ViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        if let new = searchController.searchBar.text {filterContentForSearchText(new)}
    }
    
    func searchbarisEmpty() -> Bool {
        return searchController.searchBar.text?.isEmpty ?? true
    }
    
    func filterContentForSearchText(_ searchText: String, scope: String = "All") {
        filteredSong = song.filter {(song: Song) in
            return song.text.lowercased().contains(searchText.lowercased())
        }
        tableView.reloadData()
    }
    
    func isFiltering() -> Bool {
        return searchController.isActive && !searchbarisEmpty()
    }
}
