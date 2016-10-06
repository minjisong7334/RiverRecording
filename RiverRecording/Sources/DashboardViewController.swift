//
//  DashboardViewController.swift
//  RiverRecording
//
//  Created by Marquez on 02/10/2016.
//  Copyright © 2016 Marquez Kim. All rights reserved.
//

import Foundation
import UIKit
import KCFloatingActionButton

class DashboardViewController : UIViewController {
    
    let fab = KCFloatingActionButton()
    
    override func viewDidLoad() {
        
        initButton()
        
        }
    
    func initButton() {
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
		fab.addItem("Search", icon: UIImage(named: "btn_dash_menu_search")!, handler: {action in
			self.moveToSearchView()
		})
		
        
        self.view.addSubview(fab)
    }
    
    func moveToRecordingView() {
        let recordingViewController = storyboard?.instantiateViewController(withIdentifier: "RecordingViewController")
        self.navigationController?.pushViewController(recordingViewController!, animated: true)
    }
	
	func moveToSearchView() {
		let recordingViewController = storyboard?.instantiateViewController(withIdentifier: "SearchViewController")
		self.navigationController?.pushViewController(recordingViewController!, animated: true)
	}
        
    
}
