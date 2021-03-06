//
//  FileBrowserState.swift
//  FileBrowser
//
//

import Foundation

public class FileBrowserState : NSObject, NSCopying
{
	// Overrides
	public var dataSource: FileBrowserDataSource!
	public var delegate: FileBrowserDelegate?
	public var didSelectFile: ((FBFile) -> ())?
	
	// Utility
	let previewManager = PreviewManager()
	let collation = UILocalizedIndexedCollation.current()

	// Configuration
	public var options: FileBrowserOptions?
	fileprivate var includeIndex: Bool = true
	var showOnlyFolders: Bool = false
	var cellAcc: UITableViewCell.AccessoryType = .detailButton
	var allowSearch: Bool = true
	var cellShowDetail: Bool = false
	
	public func shouldIncludeIndex() -> Bool
	{
		return includeIndex && (options?.List_ShowIndex ?? true)
	}
	
	public func setIncludeIndex(_ showIndex: Bool )
	{
		includeIndex = showIndex
	}

	public convenience init(dataSource: FileBrowserDataSource)
	{
		self.init()
		
		self.dataSource = dataSource;
	}
	
	public func copy(with zone: NSZone? = nil) -> Any
	{
		let state = FileBrowserState(dataSource: dataSource)
		
		state.delegate = self.delegate
		state.didSelectFile = self.didSelectFile
		state.includeIndex = self.includeIndex
		state.showOnlyFolders = self.showOnlyFolders
		state.cellAcc = self.cellAcc
		state.allowSearch = self.allowSearch
		state.cellShowDetail = self.cellShowDetail
		state.options = self.options
		
		return state
	}
	
	func viewControllerFor( file: FBFile, fileList: [FBFileProto]? ) -> UIViewController
	{
		if file.isDirectory
		{
			let fileListViewController = FolderEditorTableView(state: self, withDirectory: file)
			return fileListViewController
		}
		else
		{
			let filePreview = PreviewManager.previewViewControllerForFile(file, data: nil, state: self, fileList: fileList)
			return filePreview
		}

	}
	
	func viewFile( file: FBFile, controller: UIViewController, fileList: [FBFileProto]? )
	{
		if file.isDirectory
		{
			controller.navigationController?.pushViewController(viewControllerFor(file: file, fileList: fileList), animated: true)
		}
		else {
			if let didSelectFile = didSelectFile {
				controller.dismiss(animated: true, completion: nil)
				didSelectFile(file)
			}
			else
			{
				controller.navigationController?.pushViewController(viewControllerFor(file: file, fileList: fileList), animated: true)
			}
		}
		
	}
	
	func renameFile( file: FBFile, controller: UIViewController, completion: ((FBFile)->())? )
	{
		// this is just a test
		// bring up the alert thing with two text fields
		let alertController = UIAlertController(title: "Rename", message: nil, preferredStyle: .alert)

		alertController.addTextField(configurationHandler: {(textField : UITextField!) -> Void in
			textField.placeholder = "File Name"
			textField.tag = 1
			textField.text = file.fileNameWithoutExtension()
		})

		if file.isDirectory == false
		{
			alertController.addTextField(configurationHandler: {(textField : UITextField!) -> Void in
				textField.placeholder = "Extension"
				textField.tag = 2
				textField.text = file.fileExtension
			})
		}

		
		
		let renameAction = UIAlertAction(title: "Rename", style: .destructive, handler: {(alert: UIAlertAction!) in
			// Perform rename
			if file.isDirectory
			{
				guard alertController.textFields?.count == 1 else
				{
					print("Failed to rename. Text Fields not equal to 1")
					return
				}
				
				guard let firstTextField = alertController.textFields?[0] else
				{
					return
				}
				
				if let name = firstTextField.text
				{
					let newName = name
					
					let newFile = file.rename(name: newName)
					
					if let completion = completion
					{
						completion( newFile )
					}
				}
			}
			else
			{
				guard alertController.textFields?.count == 2 else
				{
					print("Failed to rename. Text Fields not equal to two")
					return
				}
				
				guard let firstTextField = alertController.textFields?[0] else
				{
					return
				}
				
				guard let secondTextField = alertController.textFields?[1] else
				{
					return
				}
				
				var nameTextField : UITextField
				var extTextField : UITextField
				
				if firstTextField.tag == 1
				{
					nameTextField = firstTextField
					extTextField = secondTextField
				}
				else
				{
					nameTextField = secondTextField
					extTextField = firstTextField
				}
				
				if let name = nameTextField.text, let ext = extTextField.text
				{
					var newName : String = name
					
					if ext.count > 0
					{
						newName += "." + ext
					}
					
					let newFile = file.rename(name: newName)
					
					if let completion = completion
					{
						completion( newFile )
					}
				}
			}
			

		})

		let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil )

		alertController.addAction(cancelAction)
		alertController.addAction(renameAction)
		
		controller.present(alertController, animated: true, completion: nil)
	}
	
	func deleteFilesWithConfirmation( prompt : String, files: [FBFile], fromButton: UIBarButtonItem?, controller: UIViewController, refresh: @escaping ()->() )
	{
		let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
		let deleteAction = UIAlertAction(title: prompt, style: .destructive, handler: {(alert: UIAlertAction!) in
			// Perform delete
			
			for file in files
			{
				file.delete()
			}
			
			refresh()
		})
		let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil )
		
		alertController.addAction(cancelAction)
		alertController.addAction(deleteAction)
		
		// Configure the alert controller's popover presentation controller if it has one.
		if let button = fromButton, let popoverPresentationController = alertController.popoverPresentationController
		{
			popoverPresentationController.barButtonItem = button
		}
		controller.present(alertController, animated: true, completion: nil)
	}
	
	func moveFiles( files: [FBFile], controller: UIViewController, sender: Any? )
	{
		let vc = SelectFolderViewController.newInstanceForMovingFiles(files: files, state: self, action:{
			//TODO: move to the new directory, may not really want to
		} )
		if let vc = vc
		{
			controller.showDetailViewController(vc, sender: sender)
		}
	}
	
	func newFolder( directory: FBFile, controller: UIViewController, action: @escaping ()->() )
	{
		// ask for name
		AlertUtilities.Alert_AskForText(title: "New Folder", question: "Name for new folder", presenter: controller, okHandler:{
			(alert: UIAlertController) in
			// Create folder
			
			if let text = alert.textFields?[0].text
			{
				if directory.createDirectory(name: text)
				{
					 action()
				}
			}
		})
	}
	
	func displayOptionsFrom( _ viewController: UIViewController )
	{
		if let delegate = delegate
		{
			delegate.displayOptionsFrom(viewController)
		}
	}
	
	func sortingSelector() -> Selector
	{
		var selector: Selector
		
		let sortBy : FBFileAttributes = options?.List_SortBy ?? .FileName
		
		switch( sortBy )
		{
		case .None:
			selector = #selector(getter: FBFile.displayName)
		case .FileName:
			selector = #selector(getter: FBFile.displayName)
		case .FileSize:
			selector = #selector(FBFile.getFileSizeDisplayString)
		case .FileType:
			selector = #selector(FBFile.getFileTypeDisplayString)
		case .DateModified:
			selector = #selector(FBFile.getModificationDateStringForSorting)
		case .DateAdded:
			selector = #selector(FBFile.getFileAddedDateStringForSorting)
		case .DateCreated:
			selector = #selector(FBFile.getCreationDateStringForSorting)
		}

		return selector
	}
	
	func sort( fileList files: [FBFile] ) -> [FBFile]
	{
		let selector = sortingSelector()
		
		if let sortedFiles = collation.sortedArray(from: files, collationStringSelector: selector) as? [FBFile]
		{
			if options?.List_SortReversed ?? false
			{
				return sortedFiles.reversed()
			}
			return sortedFiles
		}
		return files
	}
	
	//MARK: UI
	
	public func getDoneButton( target: Any?, action: Selector? ) -> UIBarButtonItem
	{
		return UIBarButtonItem(image: UIImage(named:"switch_tasks_icon"), style: .plain, target: target, action: action)
		//return UIBarButtonItem(barButtonSystemItem: .bookmarks, target: target, action: action)
	}

}
