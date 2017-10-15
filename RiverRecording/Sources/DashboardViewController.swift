//
//  DashboardViewController.swift
//  RiverRecording
//
//  Created by Marquez on 02/10/2016.
//  Copyright © 2016 Marquez Kim. All rights reserved.
//

import Foundation
import UIKit
import Floaty

class DashboardViewController : UIViewController {
    
    let fab = Floaty()
    
    override func viewDidLoad() {
        
        initButton()
        
    }
    
    func initButton() {
        fab.size = 54
        fab.buttonColor = UIColor(red: 170/255.0, green: 50/255.0, blue: 55/255.0, alpha: 1)
        fab.openAnimationType = .slideLeft
        
        //Record, Category, Edit, Search
        fab.addItem("Record", icon: UIImage(named: "btn_dash_menu_record")!, handler: {item in
            let alert = UIAlertController(title: "Recording", message: "Will you start to record?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Continue", style: .default, handler: { action in
                self.moveToRecordingView()
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
            
        })
        fab.addItem("Category", icon: UIImage(named: "btn_dash_menu_category")!)
        fab.addItem("Edit", icon: UIImage(named: "btn_dash_menu_edit")!)
        fab.addItem("Search", icon: UIImage(named: "btn_dash_menu_search")!) { _ in
            self.performSegue(withIdentifier: "goToSearchVC", sender: nil)
        }
        
        
        self.view.addSubview(fab)
    }
    
    func moveToRecordingView() {
        let recordingViewController = storyboard?.instantiateViewController(withIdentifier: "RecordingViewController")
        self.navigationController?.pushViewController(recordingViewController!, animated: true)
    }
        
    
}
