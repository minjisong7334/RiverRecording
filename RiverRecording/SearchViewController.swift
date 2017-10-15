//
//  SearchViewController.swift
//  RiverRecording
//
//  Created by Marquez on 15/10/2017.
//  Copyright © 2017 Marquez Kim. All rights reserved.
//

import UIKit

class SearchViewController: UIViewController {
    
    var dataprovider: SearchDataProvider!
    @IBOutlet var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        dataprovider = SearchDataProvider()
    }
}

extension SearchViewController: UITableViewDelegate {
    
}

extension SearchViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataprovider.count!
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RecordCell")
        cell?.textLabel?.text = dataprovider.contents?[indexPath.row]
        cell?.detailTextLabel?.text = dataprovider.contents?[indexPath.row]
        
        return cell!
    }
}
