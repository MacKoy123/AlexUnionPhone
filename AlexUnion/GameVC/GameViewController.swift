//
//  GameViewController.swift
//  AlexUnion
//
//  Created by Viktor Puzakov on 9/4/19.
//  Copyright © 2019 Mac. All rights reserved.
//

import UIKit
import MultipeerConnectivity

class GameViewController: UIViewController {

    @IBOutlet weak var songText: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var oneCharacter: UILabel!
    @IBOutlet weak var twoCharacter: UILabel!
    @IBOutlet weak var threeCharacter: UILabel!
    @IBOutlet weak var fourCharacter: UILabel!
    @IBOutlet weak var fiveCharacter: UILabel!
    @IBOutlet weak var sixCharacter: UILabel!
    
    var buttonTouchedCharacters: [Character] = []
    
    var buttonTouchedCount: Int = 0
    
    var song: Song
    
    var isAnswered: Bool = false
    
    var mcSession: MCSession
    var timer = Timer()
    
    var textSongCharacters: Set<Character> {
        return Set(song.text.uppercased())
    }
    
    var textSongWords: [String.SubSequence] {
        return song.text.split(separator: " ")
    }
    
    
    init(song: Song, session: MCSession) {
        self.song = song
        self.mcSession = session
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.hidesBackButton = true
        let newBackButton = UIBarButtonItem(title: "Стоп", style: .plain, target: self, action: #selector(back(sender:)))
        self.navigationItem.leftBarButtonItem = newBackButton
        let answerButton = UIBarButtonItem(title: "Ответ", style: .plain, target: self, action: #selector(answer(sender:)))
        self.navigationItem.leftBarButtonItem = newBackButton
        self.navigationItem.rightBarButtonItem = answerButton
        self.navigationItem.title = song.singer ?? " "
        songText.text = song.text
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib(nibName: "GameTableViewCell", bundle: nil), forCellReuseIdentifier: "tbCell")
    }
    
    func numberCharacterSetValue(label: UILabel, letter: String) {
        label.text = letter
        
        if textSongCharacters.contains(Character(letter)) {
            label.textColor = UIColor.green
        } else {
            label.textColor = UIColor.red
        }
    }
    
    @objc func back(sender: UIBarButtonItem) {
        if buttonTouchedCount == 6 || isAnswered {
            self.sendCharacters(text: "endThisGame")
            self.navigationController?.popViewController(animated: true)
        } else {
            let alertController = UIAlertController(title: "Выйти из игры?", message: nil, preferredStyle: .alert)
            let alertActionGo = UIAlertAction(title: "Выйти", style: .default) { (_) in
                self.sendCharacters(text: "endThisGame")
                self.navigationController?.popViewController(animated: true)
            }
            let alertActionCancel = UIAlertAction(title: "Отмена", style: .default, handler: nil)
            alertController.addAction(alertActionGo)
            alertController.addAction(alertActionCancel)
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    @objc func answer(sender: UIBarButtonItem) {
        timer.invalidate()
        title = song.singer ?? " "
        buttonTouchedCharacters = Array(Set(song.text.uppercased()))
        isAnswered = true
        sendCharacters(text: "getAnswerPlease")
        tableView.reloadData()
    }
    
    @IBAction func letterButtonTouched(_ sender: UIButton) {
        if isAnswered { return }
        guard let letter = sender.currentTitle else { return }
        if buttonTouchedCharacters.contains(Character(letter)) || buttonTouchedCount >= 6 {
            return
        } else {
            buttonTouchedCount += 1
            buttonTouchedCharacters.append(Character(letter))
            sendCharacters(text: letter)
            switch buttonTouchedCount {
            case 1: numberCharacterSetValue(label: oneCharacter, letter: letter)
            case 2: numberCharacterSetValue(label: twoCharacter, letter: letter)
            case 3:
                numberCharacterSetValue(label: threeCharacter, letter: letter)
                timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(timerUpdate1Min), userInfo: NSDate(), repeats: true)
            case 4: numberCharacterSetValue(label: fourCharacter, letter: letter)
                timer.invalidate()
                title = song.singer ?? " "
            case 5: numberCharacterSetValue(label: fiveCharacter, letter: letter)
                timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(timerUpdate30Sec), userInfo: NSDate(), repeats: true)
            case 6: numberCharacterSetValue(label: sixCharacter, letter: letter)
                timer.invalidate()
                title = song.singer ?? " "
                timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(timerUpdate30Sec), userInfo: NSDate(), repeats: true)
            default: break
            }
            if textSongCharacters.contains(Character(letter)) {
                sender.setTitleColor(.green, for: .normal)
                sender.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
            } else {
                sender.setTitleColor(.red, for: .normal)
                sender.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
            }
            tableView.reloadData()
        }
    }
    
    func sendCharacters(text: String) {
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
    
    @objc func timerUpdate1Min() {
        let elapsed = -(self.timer.userInfo as! NSDate).timeIntervalSinceNow
        if elapsed < 60 {
            title = String(format: "%.0f", elapsed)
        }
        if elapsed > 60 {
            timeIsEnded()
        }
    }
    
    @objc func timerUpdate30Sec() {
        let elapsed = -(self.timer.userInfo as! NSDate).timeIntervalSinceNow
        if elapsed < 30 {
            title = String(format: "%.0f", elapsed)
        }
        if elapsed > 30 {
            timeIsEnded()
        }
    }
    
    func timeIsEnded() {
        timer.invalidate()
        title = song.singer ?? " "
        let alertController = UIAlertController(title: "Время вышло", message: nil, preferredStyle: .alert)
        let alertActionCancel = UIAlertAction(title: "ОК", style: .default)
        alertController.addAction(alertActionCancel)
        self.present(alertController, animated: true, completion: nil)
    }
}

extension GameViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return textSongWords.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: GameTableViewCell = tableView.dequeueReusableCell(withIdentifier: "tbCell", for: indexPath) as! GameTableViewCell
        cell.word = String(textSongWords[indexPath.row])
        cell.buttonTouchedCharacters = self.buttonTouchedCharacters
        return cell
    }
}
