//
//  AddGameViewController.swift
//  queRULE
//
//  Created by Johan Vallejo on 14/12/16.
//  Copyright © 2016 kijho. All rights reserved.
//

import UIKit
import CoreData
import AVFoundation

protocol AddGameViewControllerDelegate {
    func didAddGame()
}

class AddGameViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet var imgGame: UIImageView!
    @IBOutlet var switchBorrowed: UISwitch!
    @IBOutlet var txtTitle: UITextField!
    @IBOutlet var txtBorrowedTo: UITextField!
    @IBOutlet var txtBorrowedDate: UITextField!
    @IBOutlet var btnDeleteGame: UIButton!

    var manageObjectContext : NSManagedObjectContext? = nil
    var imagePickerController = UIImagePickerController()
    var cameraPermissions : Bool = false
    var delegate : AddGameViewControllerDelegate?
    var game : Game? = nil
    var datePicker : UIDatePicker!
    let dateFormatter = DateFormatter()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.

        dateFormatter.dateFormat = "dd/MM/yyyy"

        //KeyBoard
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: Notification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: Notification.Name.UIKeyboardWillHide, object: nil)

        //Cuando se presione cualquier parte de la pantalla se esconde el teclado
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(viewTapped))
        self.view.addGestureRecognizer(tapGesture)

        //Se agrega un gesto a la imagen para que cuando esta se presione despliegue un alertSheet
        let takePictureGesture = UITapGestureRecognizer(target: self, action: #selector(takePictureTapped))
        self.imgGame.addGestureRecognizer(takePictureGesture)

        imagePickerController.delegate = self
        imagePickerController.allowsEditing = true

        //Se crea el datepicker para seleccionar la fecha
        datePicker = UIDatePicker(frame: CGRect(x: 0, y: 210, width: 320, height: 216))
        datePicker.datePickerMode = .date
        datePicker.addTarget(self, action: #selector(datePickerChangedValue), for: .valueChanged)
        txtBorrowedDate.inputView = datePicker

        if game == nil {
            self.title = "Añadir Juego"
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelButtonPressed))
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveButtonPressed))
            self.btnDeleteGame.isHidden = true
            self.switchBorrowed.isOn = false
        } else {
            self.title = "Detalles"
            self.txtTitle.text = game?.title
            if let borrowed = game?.borrowed {
                self.switchBorrowed.isOn = borrowed
            }
            self.txtBorrowedTo.text = game?.borrowedTo
            if let borrowedDate = game?.borrowedDate as? Date {
                self.txtBorrowedDate.text = dateFormatter.string(from: borrowedDate)
            }
            if let imageData = game?.image as? Data {
                self.imgGame.image = UIImage(data: imageData)
            }
            self.btnDeleteGame.isHidden = false
        }
        if !switchBorrowed.isOn {
            txtBorrowedTo.isEnabled = false
            txtBorrowedDate.isEnabled = false
        }

    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        checkPermissions()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if game != nil {
            saveGame()
        }
    }

    func keyboardWillShow(notification: NSNotification) {
        let info = notification.userInfo!
        let keyboardFrame : CGRect = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        let keyboardTime = (info[UIKeyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue
        UIView.animate(withDuration: keyboardTime) {
            self.view.frame.origin.y = -(keyboardFrame.height)
        }
    }

    func keyboardWillHide(notification: NSNotification) {
        let info = notification.userInfo!
        let keyboardTime = (info[UIKeyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue
        UIView.animate(withDuration: keyboardTime) {
            self.view.frame.origin.y = 0
        }
    }

    func viewTapped() {
        for view in self.view.subviews {
            if let textField = view as? UITextField {
                textField.resignFirstResponder()
            }
        }
    }

    func checkPermissions() {
        let cameraMediaType = AVMediaTypeVideo
        let cameraAuthorisationStatus = AVCaptureDevice.authorizationStatus(forMediaType: cameraMediaType)
        switch cameraAuthorisationStatus {
        case .authorized:
            cameraPermissions = true
        case .restricted:
            cameraPermissions = false
        case .denied:
            cameraPermissions = false
        case .notDetermined:
            AVCaptureDevice.requestAccess(forMediaType: cameraMediaType, completionHandler: { (granted) in
                self.cameraPermissions = granted
            })
        }
    }

    func takePictureTapped() {
        guard cameraPermissions else {
            let permissionsAlertController = UIAlertController(title: "Permisos", message: "No tiene permisos para acceder a la camara del dispositivo. Puede cambiar esta información en la app de ajustes de iOS", preferredStyle: .alert)
            let permissionsAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
            permissionsAlertController.addAction(permissionsAction)
            self.present(permissionsAlertController, animated: true, completion: nil)
            return
        }
        let alertController = UIAlertController(title: "Añadir foto del dispositivo", message: "", preferredStyle: .actionSheet)
        let cameraAction = UIAlertAction(title: "Camara", style: .default) { (alertAction) in
            self.imagePickerController.sourceType = .camera
            self.present(self.imagePickerController, animated: true, completion: nil)
        }
        let photoLibraryAction = UIAlertAction(title: "Libreria de Fotos", style: .default) { (alertAction) in
            self.imagePickerController.sourceType = .photoLibrary
            self.present(self.imagePickerController, animated: true, completion: nil)
        }
        let cancelAction = UIAlertAction(title: "Cancelar", style: .cancel, handler: nil)
        if UIImagePickerController.isCameraDeviceAvailable(.rear) {
            alertController.addAction(cameraAction)
        }
        alertController.addAction(photoLibraryAction)
        alertController.addAction(cancelAction)
        self.present(alertController, animated: true, completion: nil)
    }

    func datePickerChangedValue(picker: UIDatePicker) {
        txtBorrowedDate.text = dateFormatter.string(from: picker.date)
    }

    func cancelButtonPressed() {
        dismiss(animated: true, completion: nil)
    }

    func saveButtonPressed() {
        saveGame()
        dismiss(animated: true, completion: nil)
    }

    func saveGame() {
        if let context = self.manageObjectContext {
            var editedGame : Game? = nil
            if game == nil {
                editedGame = Game(context: context)
            } else {
                editedGame = game
            }
            if let editedGame = editedGame {
                editedGame.dateCreate = NSDate()
                editedGame.title = title
                editedGame.borrowed = switchBorrowed.isOn
                if let image = imgGame.image {
                    editedGame.image = UIImagePNGRepresentation(image) as NSData?
                } else {
                    editedGame.image = NSData()
                }
                if editedGame.borrowed {
                    if let borrowedTo = txtBorrowedTo.text {
                        editedGame.borrowedTo = borrowedTo.uppercased()
                    }
                    if let strDate = txtBorrowedDate.text {
                        editedGame.borrowedDate = dateFormatter.date(from: strDate) as NSDate?
                    }
                } else {
                    editedGame.borrowedTo = nil
                    editedGame.borrowedDate = nil
                }

                do {
                    try context.save()
                    self.delegate?.didAddGame()
                } catch {
                    print("Ha habido un error al guardar en CoreData")
                }
            }
        }
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let pickedImage =  info[UIImagePickerControllerEditedImage] as? UIImage {
            self.imgGame.image = pickedImage
        }
        picker.dismiss(animated: true, completion: nil)
    }

    @IBAction func deletedPressed(_ sender: UIButton) {
        if let context = self.manageObjectContext {
            context.delete(game!)
            game = nil
            delegate?.didAddGame()
            let _ = navigationController?.popViewController(animated: true)
        }
    }

    @IBAction func switchValueChanged(_ sender: UISwitch) {
        if sender.isOn {
            txtBorrowedTo.isEnabled = true
            txtBorrowedDate.isEnabled = true
            txtBorrowedDate.text = dateFormatter.string(from: Date())
        } else {
            txtBorrowedTo.isEnabled = false
            txtBorrowedDate.isEnabled = false
            txtBorrowedTo.text = ""
            txtBorrowedDate.text = ""
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
