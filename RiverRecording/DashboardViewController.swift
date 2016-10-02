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
    
    @IBOutlet weak var fab = KCFloatingActionButton()
    
    
    override func viewDidLoad() {
        //Record, Category, Edit, Search
        fab?.addItem("Record", icon: UIImage(named: "btn_dash_menu_record")!)
        fab?.addItem("Category", icon: UIImage(named: "btn_dash_menu_category")!)
        fab?.addItem("Edit", icon: UIImage(named: "btn_dash_menu_edit")!)
        fab?.addItem("Search", icon: UIImage(named: "btn_dash_menu_search")!)
    }
    
    
}
