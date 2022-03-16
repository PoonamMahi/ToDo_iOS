//
//  ViewController.swift
//  ToDo_iOS
//
//  Created by Poonam Mahi on 2022-03-16.
//


import UIKit
import CoreData

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    

    @IBOutlet weak var tableView: UITableView!
    
    var tasks = [String]()
    var idArray = [UUID]()
    var isCompletedArr = [Bool]()
    var selectedRows = [IndexPath]()
    
    var selectedTask = ""
    var selectedTaskId : UUID?
    
    var todoStruct = Todo(isMarked: false)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = "TODO APP"
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        
        navigationController?.navigationBar.topItem?.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.add, target: self, action: #selector(clickedAddBtn))
        
        getData()
    }
    
    @objc func getData(){
        
        tasks.removeAll(keepingCapacity: false)
        idArray.removeAll(keepingCapacity: false)
        isCompletedArr.removeAll(keepingCapacity: false)
        
        let appdelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appdelegate.persistentContainer.viewContext
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Tasks")
        fetchRequest.returnsObjectsAsFaults = false
        
        do{
            let results = try context.fetch(fetchRequest)
            
            for result in results as! [NSManagedObject]{
                if let title = result.value(forKey: "title") as? String{
                    self.tasks.append(title)
                }
                if let id = result.value(forKey: "id") as? UUID{
                    self.idArray.append(id)
                }
                if let isCompleted = result.value(forKey: "isCompleted") as? Bool{
                    self.isCompletedArr.append(isCompleted)
                    if isCompleted && !self.selectedRows.contains(IndexPath(row: (results as! [NSManagedObject]).firstIndex(of: result)!, section: 0)){
                        self.selectedRows.append(IndexPath(row: (results as! [NSManagedObject]).firstIndex(of: result)!, section: 0))
                    }
                }
                self.tableView.reloadData()
            }
        }catch{
            print("view contr error")
        }
        
    }
    
    @objc func clickedAddBtn(){

        let alert = UIAlertController(title: "Add Task", message: "Enter a task", preferredStyle: .alert)

        alert.addTextField { (textField) in
            textField.placeholder = ""
        }

        //ADD
        alert.addAction(UIAlertAction(title: "Add", style: .default, handler: { [weak alert] (_) in
            guard let textfield = alert?.textFields?.first else {
                return
            }
            print("Text field: \(textfield.text ?? "")")
            guard let text = textfield.text else{return}
            
            if text != "" {
                
                let appdelegate = UIApplication.shared.delegate as! AppDelegate
                let context = appdelegate.persistentContainer.viewContext
                
                let newTask = NSEntityDescription.insertNewObject(forEntityName: "Tasks", into: context)
                
                newTask.setValue(UUID(), forKey: "id")
                newTask.setValue(text, forKey: "title")
                newTask.setValue(false, forKey: "isCompleted")
                
                do{
                    try context.save()
                    print("success")
                }catch{
                    print("error")
                }
                
                
                self.getData()
            }
            
        }))
        
        //Cancel
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))


        self.present(alert, animated: true, completion: nil)
        
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tasks.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
       
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! TaskTableViewCell
        
        
        
        if selectedRows.contains(indexPath){
            cell.checkMark.setImage(UIImage(named: "marked"), for: .normal)
            self.todoStruct.isMarked = true
            let attributeString: NSMutableAttributedString = NSMutableAttributedString(string: tasks[indexPath.row])
                attributeString.addAttribute(NSAttributedString.Key.strikethroughStyle, value: 2, range: NSRange(location: 0, length: attributeString.length))
            cell.taskLabel.attributedText = attributeString
        }
        else{
            cell.checkMark.setImage(UIImage(named: "unmarked"), for: .normal)
            cell.taskLabel.attributedText = nil
            cell.taskLabel?.text = tasks[indexPath.row]
            self.todoStruct.isMarked = false
        }
        cell.checkMark.tag = indexPath.row
        cell.checkMark.addTarget(self, action: #selector(checkBoxSelection(_:)), for: .touchUpInside)
        return cell
    }
    
   
    @objc func checkBoxSelection(_ sender:UIButton)
      {
        let selectedIndexPath = IndexPath(row: sender.tag, section: 0)
          
          let appdelegate = UIApplication.shared.delegate as! AppDelegate
          let context = appdelegate.persistentContainer.viewContext
          
          let title = tasks[sender.tag]
          
          let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Tasks")
          fetchRequest.returnsObjectsAsFaults = false
          fetchRequest.predicate = NSPredicate(format: "title = %@", title)
          do{
              let results = try context.fetch(fetchRequest) as! [NSManagedObject]
              
              
            if self.selectedRows.contains(selectedIndexPath)
            {
              self.selectedRows.remove(at: self.selectedRows.firstIndex(of: selectedIndexPath)!)
            results.first?.setValue(false, forKey: "isCompleted")
            }
            else
            {
              self.selectedRows.append(selectedIndexPath)
                results.first?.setValue(true, forKey: "isCompleted")
                
            }
            self.tableView.reloadData()
              
              do{
                  try context.save()
                  print("success")
              }catch{
                  print("error")
              }
          }catch{
              print("view contr error")
          }
          
         
      }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete{
            let appdelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appdelegate.persistentContainer.viewContext
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Tasks")
            
            let idString = idArray[indexPath.row].uuidString
            fetchRequest.predicate = NSPredicate(format: "id = %@", idString)
            
            do{
                let results = try context.fetch(fetchRequest) // results array dönüyo
                if results.count > 0{
                    for result in results as! [NSManagedObject]{
                        if let id = result.value(forKey: "id") as? UUID{
                            if id == idArray[indexPath.row]{
                                //core datadan silme
                                context.delete(result)
                                
                                // arrayden silme
                                tasks.remove(at: indexPath.row)
                                idArray.remove(at: indexPath.row)
                                if isCompletedArr.count > indexPath.row {
                                    self.isCompletedArr.remove(at: indexPath.row)
                                }
                                if self.selectedRows.count > indexPath.row{
                                    self.selectedRows.remove(at: indexPath.row)
                                }
                                self.tableView.reloadData()
                                
                                do{
                                    try context.save()
                                }catch{
                                    print("error")
                                }
                            }
                        }
                    }
                }
            }
            catch{
                print("error")
            }
        }
    }
    
    


}

