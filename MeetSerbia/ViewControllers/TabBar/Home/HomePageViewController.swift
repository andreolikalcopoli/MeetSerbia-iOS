//
//  HomePage.swift
//  MeetSerbia
//
//  Created by Nemanja Ducic on 9.3.23..
//

import Foundation
import UIKit
class HomePageViewController:UIViewController,UITableViewDelegate,UITableViewDataSource,UISearchBarDelegate,SelectedCategoryDelegate{
    func didSelectCategory(cell: UITableViewCell, category: String,index:Int) {
        temporarySelectedCategories.toggle(element: category)
        boolArray[index].toggle()
        checkButtonGreen.isHidden = temporarySelectedCategories.isEmpty
        
    }
    
    var itemsArray = [DataModel]()
    private var boolArray = [false,false,false,false,false,false,false,false,false,false,false,false,false]
    private var selectedLocationModel: LocationModel?
    private var filteredData = [String]()
    private var temporarySelectedCategories = [String]()
    @IBOutlet weak var homePageTableView: UITableView!
    @IBOutlet weak var searchB: UISearchBar!
    @IBOutlet weak var checkButtonGreen: UIButton!
    @IBOutlet weak var searchTV: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        if logedInCheck() == true{
            initSetup()
        } else {
            let onboardingController =  UIStoryboard.init(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "onbord") as? OnboardingViewControllerMain
            self.dismiss(animated: true)
            onboardingController?.modalPresentationStyle = .fullScreen
            present(onboardingController!, animated: true, completion: nil)
        }
        
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        homePageTableView.reloadData()
        checkButtonGreen.isHidden = temporarySelectedCategories.isEmpty
        
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        homePageTableView.reloadData()
        
    }
    
    
    private func initSetup(){
        getData()
        checkButtonGreen.backgroundColor = nil
        homePageTableView.dataSource = self
        homePageTableView.delegate = self
        searchTV.dataSource = self
        searchTV.delegate = self
        homePageTableView.register(UINib(nibName: "TableViewCell", bundle: nil), forCellReuseIdentifier: "cell")
        if let tabBarController = self.tabBarController {
            var viewControllers = tabBarController.viewControllers
            viewControllers?.remove(at: 1)
            viewControllers?.remove(at: 2)
            tabBarController.viewControllers = viewControllers
        }
        LocalManager.shared.getAllLocations { locations in
            
        }
        searchB.delegate = self
        searchTV.isHidden = true
        checkButtonGreen.isHidden = temporarySelectedCategories.isEmpty

        
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == homePageTableView {
            return  itemsArray.count
            
        }
        else {
            return filteredData.count
        }
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == homePageTableView{
            
            let cell = homePageTableView.dequeueReusableCell(withIdentifier: "cell") as? TableViewCell
            cell!.testLabel.contentMode = .bottom
            if Constants().userDefLangugaeKey == "cir" {
                cell?.testLabel.text = itemsArray[indexPath.row].category.uppercased()
                cell?.data = itemsArray[indexPath.row].subcategory
            } else if Constants().userDefLangugaeKey == "lat" {
                cell?.testLabel.text = itemsArray[indexPath.row].categoryLat.uppercased()
                cell?.data = itemsArray[indexPath.row].subcategoryLat
            } else if Constants().userDefLangugaeKey == "eng" {
                cell?.testLabel.text = itemsArray[indexPath.row].categoryEng.uppercased()
                cell?.data = itemsArray[indexPath.row].subcategoryEng
            }else {
                cell?.testLabel.text = itemsArray[indexPath.row].category.uppercased()
                cell?.data = itemsArray[indexPath.row].subcategory
            }
            cell?.index = indexPath.row
            let imageName = boolArray[indexPath.row] ? "button_checked" : "button_unchecked"
            cell?.categoryCheckButton.setImage(UIImage(named: imageName), for: .normal)
            cell?.imageHolder.image = UIImage(named: itemsArray[indexPath.row].categoryImageData)
            cell?.delegate = self
            cell?.vc = self
            cell?.allData = itemsArray
            cell?.inviData = itemsArray[indexPath.row].subcategoryLat
            cell?.holderTView.isHidden = !itemsArray[indexPath.row].expanded
            cell?.hidencell.text = itemsArray[indexPath.row].categoryLat
            cell?.selectionStyle = .none
            
            cell?.imageData = itemsArray[indexPath.row].imageData
            return cell!} else {
                let cell = UITableViewCell()
                cell.textLabel?.text = filteredData[indexPath.row]
                return cell
            }
    }
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if Constants().userDefLangugaeKey == "eng" {
            let filteredData = LocalManager.shared.allLocations.filter { item in
                return item.nameEng.lowercased().contains(searchText.lowercased())
            }
            self.filteredData = filteredData.map { $0.nameLat.uppercased() }
        } else if Constants().userDefLangugaeKey == "lat" {
            let filteredData = LocalManager.shared.allLocations.filter { item in
                
                return item.nameLat.lowercased().contains(searchText.lowercased())
            }
            self.filteredData = filteredData.map { $0.nameLat.uppercased() }
        } else {
            let filteredData = LocalManager.shared.allLocations.filter { item in
                return item.nameCir.lowercased().contains(searchText.lowercased())
            }
            self.filteredData = filteredData.map { $0.nameLat.uppercased() }
        }
        
        searchTV.isHidden = filteredData.isEmpty
        searchTV.reloadData()
    }
 
    func getData() {
        itemsArray = Data().items
        
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if tableView == homePageTableView {
            return 187 } else {
                return 30
            }
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView == homePageTableView {
            let selectedCell = homePageTableView.cellForRow(at: indexPath) as! TableViewCell

            didSelectCategory(cell: selectedCell, category: selectedCell.hidencell.text!.lowercased(),index: indexPath.row)
            homePageTableView.reloadData()
        } else {
            guard indexPath.row < filteredData.count else {
                       return
                   }
            let selectedLocation = filteredData[indexPath.row]
            selectedLocationModel = LocalManager.shared.allLocations.first{$0.nameLat.lowercased() == selectedLocation.lowercased()}
            let DVC  = UIStoryboard.init(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "locationDescVC") as? LocationDescriptionViewController
            DVC?.id = selectedLocationModel!.id
            DVC?.long = selectedLocationModel!.lon
            DVC?.lat = selectedLocationModel!.lat
            self.navigationController?.pushViewController(DVC!, animated: true)
               }

        
    }
    func getSubcategories(category:String)->[String] {
            guard let item = itemsArray.first(where: { $0.categoryLat.lowercased() == category }) else {
                return [String]()
                }
        var subs = item.subcategoryLat
        subs.insert(category, at: 0)
        return subs
        
    }
    func getPosition(item: DataModel, itemSelected: String) -> String? {
        if let index = item.subcategoryEng.map({$0.lowercased()}).firstIndex(of: itemSelected) {
            return item.subcategoryLat[index]
        }
        
        if let index = item.subcategory.map({$0.lowercased()}).firstIndex(of: itemSelected) {
            return item.subcategoryLat[index]
        }
        
        if let index = item.subcategoryLat.map({$0.lowercased()}).firstIndex(of: itemSelected) {
            return item.subcategoryLat[index]
        }
        
        return nil
    }
    
    private func logedInCheck()->Bool {
        if Constants().userDefLoginKey == true {
            return true
        } else {
            return false
        }
    }

    
    @IBAction func checkmarkClick(_ sender: Any) {
        if temporarySelectedCategories.isEmpty {
            if Constants().userDefLangugaeKey == "eng" {
                showToast(message: "Select Category", font: UIFont(name: "Arial", size: 17.0)!)

            } else if Constants().userDefLangugaeKey == "lat" {
                showToast(message: "Odaberite Kategorije", font: UIFont(name: "Arial", size: 17.0)!)

            } else {
                showToast(message: "Одаберите Категорију", font: UIFont(name: "Arial", size: 17.0)!)
            }
           
        } else {
            let viewController =  UIStoryboard.init(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "FMT") as? FilteredMapViewController
            viewController?.selectedCategories = temporarySelectedCategories
            viewController?.sentFromSearch = false
            boolArray = [false,false,false,false,false,false,false,false,false,false,false,false,false]
            temporarySelectedCategories = []
            navigationController?.pushViewController(viewController!, animated: true)
        }
          
            
        
    }
    func categoryToLat(string:String) -> String {
        if Constants().MAIN_CATEGORIES_CIR.contains(string){
            return Constants().MAIN_CATEGORIES[Constants().MAIN_CATEGORIES_CIR.firstIndex(of: string)!]
        } else if Constants().MAIN_CATEGORIES_ENG.contains(string){
            return Constants().MAIN_CATEGORIES[Constants().MAIN_CATEGORIES_ENG.firstIndex(of: string)!]
        } else {
            return string
        }
    }

}



