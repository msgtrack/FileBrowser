//
//  TextFileViewController.swift
//  FileBrowser
//
//

import Foundation

class TextFileViewController : UIViewController
{
	var file: FBFile!
	var state: FileBrowserState!
	
	var scrollView : UIScrollView!
	var textView : UITextView!
	
	convenience init (file: FBFile, state: FileBrowserState) {
		self.init(nibName: "WebviewPreviewViewContoller", bundle: Bundle(for: ImageViewController.self))
		self.file = file
		self.state = state
		self.title = file.displayName
		
		//let configuration = URLSessionConfiguration.default
		//session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
	}
	
	func applyOptions()
	{
		if let options = state.options
		{
			textView.backgroundColor = options.TextFile_backgroundColorDay
			textView.textColor = options.TextFile_textColorDay
			textView.font = options.TextFile_font
		}
	}

	
	func toolbarItemsForEdit() -> [UIBarButtonItem]
	{
		let toolbarItems = [UIBarButtonItem]()
		
		return toolbarItems
	}
	
	func toolbarItemsForView() -> [UIBarButtonItem]
	{
		var toolbarItems = [UIBarButtonItem]()
		
		toolbarItems.append(UIBarButtonItem(title: "QL", style: .plain, target: self, action: #selector(TextFileViewController.qlAction(button:))))
		
		toolbarItems.append(UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil))
		
		toolbarItems.append(UIBarButtonItem(title: "Details", style: .plain, target: self, action: #selector(TextFileViewController.detailsAction(button:))))
		
		toolbarItems.append(UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil))
		
		//toolbarItems.append(UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(TextFileViewController.editAction(button:))))
		toolbarItems.append(UIBarButtonItem( image: UIImage(named: "gear_icon"), style: .plain,  target: self, action: #selector(TextFileViewController.actionOptions(button:))))
		
		toolbarItems.append(UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil))
		
		toolbarItems.append(state.getDoneButton(target: self, action: #selector(TextFileViewController.dismiss(button:))))
		
		return toolbarItems
	}
	
	func setupForMode()
	{
		if textView.isEditable
		{
			configureKeyboardNotifications()
			
			self.setToolbarItems(toolbarItemsForEdit(), animated: false)
			self.navigationController?.hidesBarsOnTap = false
			
			self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(TextFileViewController.saveAction(button:)))
			self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Close", style: .plain, target: self, action: #selector(TextFileViewController.doneEditingAction(button:)))
			
			self.navigationController?.setToolbarHidden(true, animated: true)
			
			textView.becomeFirstResponder()
		}
		else
		{
			self.setToolbarItems(toolbarItemsForView(), animated: false)
			self.navigationController?.hidesBarsOnTap = true
			
			self.navigationItem.leftBarButtonItem = nil
			let editButton = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(TextFileViewController.editAction(button:)))
			self.navigationItem.rightBarButtonItem = editButton

			self.navigationController?.setToolbarHidden(false, animated: false)
			
			removeKeyboardNotifications()
		}
		
		// Make sure navigation bar is visible
		self.navigationController?.isNavigationBarHidden = false
	}
	
	//MARK: Lifecycle
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		// Prevent loading of too large of files
		textView = UITextView(frame: view.bounds)
		textView.autoresizingMask = [ .flexibleWidth, .flexibleHeight ]
		
		do
		{
			textView.text = try NSString(contentsOfFile: file.path.path, usedEncoding: nil) as String?
			textView.selectedTextRange = textView.textRange(from: textView.beginningOfDocument, to: textView.beginningOfDocument);
			//textView.scrollRangeToVisible(NSRange(location: 0, length: 0))
			textView.isEditable = false
			textView.isUserInteractionEnabled = true
			
			applyOptions()
		}
		catch
		{
			// unable to load text file
			print("Unable to read file. \(error)")
		}
		
		self.view.addSubview(textView)
		
		
		// Add share button
		//let shareButton = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(WebviewPreviewViewContoller.shareFile(sender:)))
		//self.navigationItem.rightBarButtonItem = shareButton
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		setupForMode()
		applyOptions()
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		removeKeyboardNotifications()
	}
	
	//MARK: Button Actions
	
	@objc func dismiss(button: UIBarButtonItem)
	{
		self.dismiss(animated: true, completion: nil)
	}

	@objc func doneEditingAction(button: UIBarButtonItem)
	{
		// ask to save, just saving right now
		saveAction(button: button)
		textView.isEditable = false
		setupForMode()
		
	}
	
	@objc func editAction(button: UIBarButtonItem)
	{
		textView.isEditable = true
		setupForMode()
	}

	@objc func saveAction(button: UIBarButtonItem)
	{
		if let text = textView.text
		{
			do
			{
				try text.write(to: file.path, atomically: true, encoding: String.Encoding.utf8)
			}
			catch
			{
				print ("Failed to write file. Error:\(error)")
			}
		}
	}

	@objc func qlAction(button: UIBarButtonItem)
	{
		let qlController = state.previewManager.quickLookControllerForFile(file, data: nil, fromNavigation: true)
		self.navigationController?.pushViewController(qlController, animated: true)
	}
	
	@objc func detailsAction(button: UIBarButtonItem) {
		let detailViewController = FileDetailViewController(file: file, state: state, fromImageViewer: true)
		self.navigationController?.pushViewController(detailViewController, animated: true)
	}
	
	@objc func actionOptions( button : UIBarButtonItem )
	{
		state.displayOptionsFrom(self)
	}
	
	//MARK: Keyboard handling
	
	func configureKeyboardNotifications() {
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardWasShown(aNotification:)), name: UIResponder.keyboardDidShowNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillBeHidden(aNotification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
	}
	
	func removeKeyboardNotifications(){
		NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardDidShowNotification, object: nil)
		NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
	}
	
	@objc func keyboardWasShown(aNotification:NSNotification) {
		let info = aNotification.userInfo
		let infoNSValue = info![UIResponder.keyboardFrameBeginUserInfoKey] as! NSValue
		let kbSize = infoNSValue.cgRectValue.size
		var contentInsets = textView.contentInset
		contentInsets.bottom = kbSize.height
		textView.contentInset = contentInsets
		
		var scrollInsets = textView.scrollIndicatorInsets
		scrollInsets.bottom = kbSize.height
		textView.scrollIndicatorInsets = scrollInsets
	}
	
	@objc func keyboardWillBeHidden(aNotification:NSNotification) {
		var contentInsets = textView.contentInset
		contentInsets.bottom = 0
		textView.contentInset = contentInsets
		
		var scrollInsets = textView.scrollIndicatorInsets
		scrollInsets.bottom = 0
		textView.scrollIndicatorInsets = scrollInsets
	}
	
	func scrollToCaretInTextView(textView: UITextView, animated: Bool) {
		if let textRange = textView.selectedTextRange
		{
			var rect = textView.caretRect(for: textRange.end)
			rect.size.height += textView.textContainerInset.bottom
			textView.scrollRectToVisible(rect, animated: animated)
		}
	}
	
	override func didRotate(from: UIInterfaceOrientation) {
		scrollToCaretInTextView(textView: textView, animated: true)
	}
}
