//
//  HomeScreenViewController.swift
//  AugmentedRealityAppPOC
//
//  Created by user on 07/06/24.
//

import UIKit
import QuartzCore

class HomeScreenViewController: UIViewController {
    
    //MARK: IB Outlets
    @IBOutlet weak var homeBgView: UIView!
    @IBOutlet weak var appIconImage: UIImageView!
    @IBOutlet weak var scanButton: UIButton!
    @IBOutlet weak var retrieveButton: UIButton!
    
    //MARK: variables
    let gradientColors: [CGColor] = [
        UIColor(red: 132/255, green: 88/255, blue: 255/255, alpha: 0.45).cgColor,
        UIColor(red: 240/255, green: 75/255, blue: 113/255, alpha: 0.45).cgColor
    ]
    let gradientColorsForButtons: [CGColor] = [
        UIColor(red: 132/255, green: 88/255, blue: 255/255, alpha: 0.75).cgColor,
        UIColor(red: 240/255, green: 75/255, blue: 113/255, alpha: 0.75).cgColor
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpUI()
        // Additional setup after loading the view.
    }
    
    //MARK: IB Actions
    @IBAction func scanButtonPressed(_ sender: UIButton) {
        let scanVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ScanViewController") as! ScanViewController
        scanVC.mode = .scanning
        navigationController?.pushViewController(scanVC, animated: true)
    }
    
    @IBAction func retrieveButtonPressed(_ sender: UIButton) {
        let scanVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ScanViewController") as! ScanViewController
        scanVC.mode = .retrieving
        navigationController?.pushViewController(scanVC, animated: true)
    }
    
    //MARK: function to setup UI
    func setUpUI() {
        customizeButton(scanButton)
        customizeButton(retrieveButton)
        addGradientToView(view: self.homeBgView, colors: gradientColors)
        addGradientToView(view: self.scanButton, colors: gradientColorsForButtons)
        addGradientToView(view: self.retrieveButton, colors: gradientColorsForButtons)
    }
    
    //MARK: function to customise buttons
    func customizeButton(_ button: UIButton) {
        button.layer.cornerRadius = 20
        button.clipsToBounds = true
        button.backgroundColor = UIColor.systemGray4
    }
    
    //MARK: function to add gradient background
    func addGradientToView(view: UIView, colors: [CGColor]) {
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = view.bounds
        gradientLayer.colors = colors
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 1.0, y: 1.0)
        
        view.layer.insertSublayer(gradientLayer, at: 0)
    }
}
