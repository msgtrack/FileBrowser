//
//  ImageViewController.swift
//  FileBrowser
//
//

import Foundation


public class ImageViewController: UIViewController, UIScrollViewDelegate {
	
	var navFileList: [FBFileProto]?
	
	var file: FBFileProto! {didSet {
		NotificationCenter.default.post(name: FileBrowser.FILE_BROWSER_VIEW_NOTIFICATION, object: file)
		loadImage()
		}}
	var state: FileBrowserState!
	
	var imageView : UIImageView!
	var scrollView : UIScrollView!
	var setZoom : Bool = false
	
	static let ZOOM_STEP : CGFloat = 2.0
	
	public convenience init (file: FBFile, state: FileBrowserState, fileList: [FBFileProto]?) {
		self.init(nibName: "WebviewPreviewViewContoller", bundle: Bundle(for: ImageViewController.self))
		self.state = state
		self.file = file
		self.navFileList = fileList
		self.edgesForExtendedLayout = UIRectEdge()
		
		//let configuration = URLSessionConfiguration.default
		//session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
	}
	
	func loadImage()
	{
		guard file != nil else { goToAnotherImage(file); return }
		guard file.file != nil else { goToAnotherImage(file); return }
		
		self.title = file.file!.displayName
		if imageView != nil
		{
			imageView.removeFromSuperview()
		}
		do
		{
			if let theImage = file.image
			{
				imageView = UIImageView(image: theImage)
			}
			else
			{
				imageView = UIImageView(image: UIImage(data: try state.dataSource.data(forFile: file.file!)))
			}
			setZoom = false
			if scrollView != nil
			{
				scrollView.contentSize = imageView.bounds.size
				scrollView.addSubview(imageView)
				
				setZoomScale( setInitialScale: true )
			}
		} catch {
			goToAnotherImage(file)
			print(error)
		}

	}
	
	func setZoomScale( setInitialScale: Bool = false ) {
		guard imageView != nil else {
			return
		}
		
		let imageViewSize = imageView.bounds.size
		let scrollViewSize = scrollView.bounds.size
		let widthScale = scrollViewSize.width / imageViewSize.width
		let heightScale = scrollViewSize.height / imageViewSize.height
		
		var minScale = min(widthScale, heightScale)
		var scale : CGFloat = 1.0
		
		if minScale > 1.0
		{
			minScale = 1.0
			scale = min((scrollViewSize.width - 50) / imageViewSize.width, ((scrollViewSize.height-100) / imageViewSize.height))
		}
		else
		{
			scale = minScale
		}
		
		scrollView.minimumZoomScale = minScale
		if setInitialScale
		{
			scrollView.zoomScale = scale
			scrollViewDidZoom(scrollView)
		}
		scrollView.maximumZoomScale = 3.0
	}
	
	override public func viewDidLoad() {
		super.viewDidLoad()
		
		if imageView == nil
		{
			loadImage()
		}
		
		if imageView != nil
		{
			scrollView = UIScrollView(frame: view.bounds)
			scrollView.backgroundColor = .white
			scrollView.contentSize = imageView.bounds.size
			scrollView.autoresizingMask = [ .flexibleWidth, .flexibleHeight ]
			//scrollView.contentInset =
			
			scrollView.addSubview(imageView)
			view.addSubview(scrollView)
			
			
			scrollView.delegate = self
			
			setZoomScale( setInitialScale: true )
			
			setupGestureRecognizer()
			//self.automaticallyAdjustsScrollViewInsets = false
			
			// Add share button
			//let shareButton = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(WebviewPreviewViewContoller.shareFile(sender:)))
			//self.navigationItem.rightBarButtonItem = shareButton
		}
	}
	
	public func scrollViewDidZoom(_ scrollView: UIScrollView)
	{
		let imageViewSize = imageView.frame.size
		let scrollViewSize = scrollView.bounds.size
		
		let verticalPadding = imageViewSize.height < scrollViewSize.height ? (scrollViewSize.height - imageViewSize.height) / 2 : 0
		let horizontalPadding = imageViewSize.width < scrollViewSize.width ? (scrollViewSize.width - imageViewSize.width) / 2 : 0
		
		//scrollView.contentMode = .center
		scrollView.contentInset = UIEdgeInsets(top: verticalPadding, left: horizontalPadding, bottom: verticalPadding, right: horizontalPadding)
	}
	
	override public var prefersStatusBarHidden: Bool
	{
		let hidden = self.navigationController?.isNavigationBarHidden ?? false
		
		if scrollView != nil
		{
			let backColor : UIColor = hidden ? .black : .white
			
			if scrollView.backgroundColor != backColor
			{
				scrollView.backgroundColor = backColor
			}
		}

		return hidden
	}
	
	override public func viewWillLayoutSubviews() {
	}
	
	override public func viewDidLayoutSubviews() {
		if setZoom == false
		{
			setZoomScale( setInitialScale: true )
			setZoom = true
		}
		else
		{
			setZoomScale()
		}
		scrollViewDidZoom( scrollView )
	}
	
	public func viewForZooming(in scrollView: UIScrollView) -> UIView?
	{
		return self.imageView;
	}
	
	public func updateImageNavButtons()
	{
		// Set nav bar items on right
		// Down and left
		
		if let navFileList = navFileList,
			let curIndex = indexOfFileIn( list: navFileList, file: self.file)
		{
			var navItems = [UIBarButtonItem]()
			
			if curIndex < (navFileList.count - 1)
			{
				navItems.append(UIBarButtonItem(title: ">", style: .plain, target: self, action: #selector(ImageViewController.nextFile(button:))))
			}
			if curIndex > 0
			{
				navItems.append(UIBarButtonItem(title: "<", style: .plain, target: self, action: #selector(ImageViewController.prevFile(button:))))
			}
			self.navigationItem.rightBarButtonItems = navItems
			
			
		}
		else
		{
			self.navigationItem.rightBarButtonItems = nil
		}
	}
	
	override public func viewWillAppear(_ animated: Bool)
	{
		super.viewWillAppear(animated)
		
		updateImageNavButtons()
		
		// Add toolbar items to this view
		var toolbarItems = [UIBarButtonItem]()
		
//		if self.toolbarItems != nil
//		{
//			toolbarItems = self.toolbarItems!
//		}
//		else
//		{
//			toolbarItems = [UIBarButtonItem]()
//		}
		//			= self.toolbarItems;
		//var ti = [UIBarButtonItem]()
		
		//ti += toolbarItems
		toolbarItems.append(UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(ImageViewController.trashAction(button:))))
		
		toolbarItems.append(UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil))
		
		toolbarItems.append(UIBarButtonItem(title: "QL", style: .plain, target: self, action: #selector(ImageViewController.qlAction(button:))))

		toolbarItems.append(UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil))
		
		toolbarItems.append(UIBarButtonItem(title: "Details", style: .plain, target: self, action: #selector(ImageViewController.detailsAction(button:))))

		toolbarItems.append(UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil))
		
		toolbarItems.append(state.getDoneButton(target: self, action: #selector(done(button:))))

		self.setToolbarItems(toolbarItems, animated: false);
		
		
		self.navigationController?.hidesBarsOnTap = true
		
		// Make sure navigation bar is visible
		self.navigationController?.isNavigationBarHidden = false
		self.navigationController?.setToolbarHidden(false, animated: false)
	}
	
	func goToAnotherImage( _ file : FBFileProto )
	{
		if let navFileList = self.navFileList
		{
			if navFileList.count == 1
			{
				// this is the last file
				self.navigationController?.popViewController(animated: true)
			}
			else
			{
				if let index = indexOfFileIn(list: navFileList, file: file)
				{
					if (index + 1) >= navFileList.endIndex
					{
						prevFile()
					}
					else
					{
						nextFile()
					}
				}
				self.removeFileFromList(file)
				updateImageNavButtons()
			}
		}
		else
		{
			// can't go to another file because there is no list
			self.navigationController?.popViewController(animated: true)
		}
	}
	
	func removeFileFromList( _ file : FBFileProto )
	{
		if let fileList = navFileList
		{
			if let index = indexOfFileIn(list: fileList, file: file)
			{
				navFileList?.remove(at: index)
			}
		}
	}
	
	func indexOfFileIn( list : [FBFileProto], file : FBFileProto ) -> Int?
	{
		var index: Int = 0
		for theFile in list
		{
			if theFile.file === file.file
			{
				return index
			}
			index += 1
		}
		return nil
	}
	
	@objc func done(button: UIBarButtonItem)
	{
		self.dismiss(animated: true, completion: nil)
	}
	
	func nextFile()
	{
		if let navFileList = navFileList
		{
			var index = 0
			if let curIndex = indexOfFileIn( list: navFileList, file: self.file)
			{
				index = curIndex + 1
			}
			if index < navFileList.endIndex
			{
				self.file = navFileList[index]
			}
		}
		
		updateImageNavButtons()
	}
	
	@objc func nextFile(button: UIBarButtonItem)
	{
		nextFile()
	}
	
	func prevFile()
	{
		if let navFileList = navFileList
		{
			var index = 0
			if let curIndex = indexOfFileIn( list: navFileList, file: self.file)
			{
				index = curIndex - 1
			}
			if index >= 0
			{
				if navFileList.endIndex > index
				{
					self.file = navFileList[index]
				}
			}
		}
		
		updateImageNavButtons()
	}
	
	@objc func prevFile(button: UIBarButtonItem)
	{
		prevFile()
	}
	
	@objc func qlAction(button: UIBarButtonItem)
	{
		guard file.file != nil else {
			return
		}
		
		let qlController = state.previewManager.quickLookControllerForFile(file.file!, data: nil, fromNavigation: true)
		self.navigationController?.pushViewController(qlController, animated: true)
	}
	
	@objc func detailsAction(button: UIBarButtonItem) {
		guard file.file != nil else {
			return
		}
		
		let detailViewController = FileDetailViewController(file: file.file!, state: state, fromImageViewer: true)
		self.navigationController?.pushViewController(detailViewController, animated: true)
	}
	
	@objc func trashAction(button: UIBarButtonItem) {
		guard file.file != nil else {
			return
		}
		
		state.deleteFileAfterUserConfirmation(files: [file.file!], controller: self, refresh: {
			// show a different image if available
			// file list needs to be refreshed
			self.goToAnotherImage(self.file)
		})
	}
	
	//MARK: TapDetectingImageViewDelegate methods
	
	func setupGestureRecognizer() {
		let doubleTap = UITapGestureRecognizer(target: self, action: #selector(ImageViewController.handleDoubleTap(recognizer:)))
		doubleTap.numberOfTapsRequired = 2
		scrollView.addGestureRecognizer(doubleTap)
		
		let twoFingerTap = UITapGestureRecognizer(target: self, action: #selector(ImageViewController.handleTwoFingerTap(gestureRecognizer:)))
		twoFingerTap.numberOfTouchesRequired = 2
		scrollView.addGestureRecognizer(twoFingerTap)
		
		
		let leftSwipe = UISwipeGestureRecognizer(target: self, action: #selector(ImageViewController.handleLeftSwipe(recognizer:)))
		leftSwipe.numberOfTouchesRequired = 1;
		leftSwipe.direction = .left
		scrollView.addGestureRecognizer(leftSwipe)

		let rightSwipe = UISwipeGestureRecognizer(target: self, action: #selector(ImageViewController.handleRightSwipe(recognizer:)))
		rightSwipe.numberOfTouchesRequired = 1;
		rightSwipe.direction = .right
		scrollView.addGestureRecognizer(rightSwipe)
	}
	
//	@objc func handleDoubleTap(recognizer: UITapGestureRecognizer) {
//		
//		if (scrollView.zoomScale > scrollView.minimumZoomScale) {
//			scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
//		} else {
//			scrollView.setZoomScale(scrollView.maximumZoomScale, animated: true)
//		}
//	}

	@objc func handleLeftSwipe(recognizer: UIGestureRecognizer) {
		nextFile()
	}

	@objc func handleRightSwipe(recognizer: UIGestureRecognizer) {
		prevFile()
	}

	@objc func handleDoubleTap(recognizer: UIGestureRecognizer) {
		// zoom in
		var newScale = scrollView.zoomScale * ImageViewController.ZOOM_STEP
		
		if (newScale > self.scrollView.maximumZoomScale)
		{
			newScale = self.scrollView.minimumZoomScale
			let zoomRect = zoomRectForScale(newScale, withCenter:recognizer.location(in:recognizer.view));
			
			scrollView.zoom(to:zoomRect, animated:true);
		}
		else
		{
			newScale = self.scrollView.maximumZoomScale;
			let zoomRect = zoomRectForScale(newScale, withCenter:recognizer.location(in:recognizer.view));
			
			scrollView.zoom(to: zoomRect, animated: true);
		}
	}
	
	@objc func handleTwoFingerTap( gestureRecognizer: UIGestureRecognizer) {
		// two-finger tap zooms out
		let newScale = scrollView.zoomScale / ImageViewController.ZOOM_STEP
		let zoomRect = zoomRectForScale(newScale, withCenter:gestureRecognizer.location(in: gestureRecognizer.view))
		scrollView.zoom(to: zoomRect, animated:true);
	}
	
	//MARK: Utility methods
	
	func zoomRectForScale(_ scale :CGFloat, withCenter center:CGPoint)->CGRect {
		
		var zoomRect = CGRect()
		
		// the zoom rect is in the content view's coordinates.
		//    At a zoom scale of 1.0, it would be the size of the imageScrollView's bounds.
		//    As the zoom scale decreases, so more content is visible, the size of the rect grows.
		zoomRect.size.height = scrollView.frame.size.height / scale;
		zoomRect.size.width  = scrollView.frame.size.width  / scale;
		
		// choose an origin so as to get the right center.
		zoomRect.origin.x    = center.x - (zoomRect.size.width  / 2.0);
		zoomRect.origin.y    = center.y - (zoomRect.size.height / 2.0);
		
		return zoomRect;
	}
}
