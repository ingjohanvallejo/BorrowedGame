//
//  GamesViewController.swift
//  queRULE
//
//  Created by Johan Vallejo on 14/12/16.
//  Copyright © 2016 kijho. All rights reserved.
//

import UIKit
import CoreData

class GamesViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    @IBOutlet weak var collectionView : UICollectionView!
    @IBOutlet weak var filterControl : UISegmentedControl!

    var managedObjectContext : NSManagedObjectContext? = nil
    var listGames : [Game] = [Game]()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.

        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.alwaysBounceVertical = true
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        performGamesQuery()
    }

    @IBAction func filterChanged(_ sender: UISegmentedControl) {
        performGamesQuery()
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if self.listGames.count == 0 {
            let imageView = UIImageView(image: UIImage(named: "img_empty_screen"))
            imageView.contentMode = .center
            collectionView.backgroundView = imageView
        } else {
            collectionView.backgroundView = UIView()
        }
        return listGames.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "GameCell", for: indexPath) as! GameCollectionViewCell
        let game = listGames[indexPath.row]
        cell.lblNameGame.text = game.title
        var highlightColor = #colorLiteral(red: 0.8784313725, green: 0.2117647059, blue: 0.1843137255, alpha: 1)
        if !game.borrowed {
            highlightColor  = #colorLiteral(red: 0.2039215686, green: 0.5960784314, blue: 0.8588235294, alpha: 1)
        }
        cell.lblBorrowed.attributedText = self.formatColor(string: "Prestado: \(game.borrowed ? "SI" : "NO")", color: highlightColor)
        if let borrowedTo =  game.borrowedTo {
            cell.lblBorrowedTo.attributedText = self.formatColor(string: "A: \(borrowedTo)", color: highlightColor)
        } else {
            cell.lblBorrowedTo.attributedText = self.formatColor(string: "A: --", color: highlightColor)
        }
        if let borrowedDate =  game.borrowedDate as? Date {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd/MM/yyyy"
            cell.lblDate.attributedText = self.formatColor(string: "Fecha: \(dateFormatter.string(from: borrowedDate))", color: highlightColor)
        } else {
            cell.lblDate.attributedText = self.formatColor(string: "Fecha: --", color: highlightColor)
        }
        if let image = game.image as? Data {
            cell.imgGame.image = UIImage(data: image)
        }

        //Relieves
        cell.layer.masksToBounds = false
        cell.layer.shadowOffset = CGSize(width: 1, height: 1)
        cell.layer.shadowColor = UIColor.black.cgColor
        cell.layer.shadowRadius = 2.0
        cell.layer.shadowOpacity = 0.2

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {

        return CGSize(width: self.view.frame.width - 20, height: 120.0)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        performSegue(withIdentifier: "editGameSegue", sender: self)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        if (offsetY < -120) {
            performSegue(withIdentifier: "addGameSegue", sender: self)
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "addGameSegue" {
            let addNavVC = segue.destination as! UINavigationController
            let addVC = addNavVC.topViewController as! AddGameViewController
            addVC.manageObjectContext = self.managedObjectContext
            addVC.delegate = self
        }
        if segue.identifier == "editGameSegue" {
            let editGameVC = segue.destination as! AddGameViewController
            editGameVC.manageObjectContext = self.managedObjectContext
            let selectedIndex = collectionView.indexPathsForSelectedItems?.first?.row
            let game = listGames[selectedIndex!]
            editGameVC.game = game
            editGameVC.delegate = self
        }
    }

    //Hacer texto con varios colores
    func formatColor(string: String, color: UIColor) -> NSMutableAttributedString {
        let length = string.characters.count
        let colonPosition = string.indexOf(target: ":")!
        let myMutableString = NSMutableAttributedString(string: string, attributes: nil)
        myMutableString.addAttribute(NSForegroundColorAttributeName,
                                      value: color,
                                      range: NSRange(location: 0, length: length))
        myMutableString.addAttribute(NSForegroundColorAttributeName,
                                      value: UIColor.black,
                                      range: NSRange(location: 0, length: colonPosition + 1))
        return myMutableString
    }

    func performGamesQuery() {
        let request :  NSFetchRequest<Game> = Game.fetchRequest()
        let sortByDate = NSSortDescriptor(key: "dateCreate", ascending: false)
        request.sortDescriptors = [sortByDate]
        if filterControl.selectedSegmentIndex == 0 {
            //Consulta
            let predicate = NSPredicate(format: "borrowed = true")
            request.predicate = predicate
        }
        do {
            let fetchesGames = try managedObjectContext?.fetch(request)
            if let fetchesGames = fetchesGames {
                listGames = fetchesGames
                self.collectionView.reloadData()
            }
        } catch  {
            print("Error recuperando datos de CoreData")
        }
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

//Hacer texto con varios colores
extension String {
    func indexOf(target: String) -> Int? {
        if let range = self.range(of: target) {
            return distance(from: self.startIndex, to: range.lowerBound)
        }
        return nil
    }
}

extension GamesViewController : AddGameViewControllerDelegate {
    func didAddGame() {
        self.collectionView.reloadData()
    }
}
