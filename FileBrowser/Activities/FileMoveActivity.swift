//
//  FileMoveActivity.swift
//  FileBrowser
//
//

import Foundation


class FileMoveActivity : UIActivity
{
	var files:[FBFile] = []
	var state:FileBrowserState? = nil
	
	convenience init( state: FileBrowserState ) {
		self.init()
		
		self.state = state
	}
	
	override var activityTitle : String
	{
		return "Move"
	}
	
	override var activityImage: UIImage?
	{
		return nil
	}
	
	override var activityType: UIActivity.ActivityType
	{
		return UIActivity.ActivityType("com.FileBrowser.activity.FileMoveActivity")
	}
	
	override var activityViewController: UIViewController?
	{
		if let state = state
		{
			return SelectFolderViewController.newInstanceForMovingFiles(files: files, state: state, action:{self.activityDidFinish(true) }, cancelAction:{self.activityDidFinish(false)})
		}
		return nil
	}
	
	override func canPerform(withActivityItems items: [Any] ) -> Bool
	{
		for item in items
		{
			if item is FBFile
			{
				return true
			}
		}
		
		return false
	}
	
	override func prepare(withActivityItems items: [Any] )
	{
		for item in items
		{
			if let item = item as? FBFile
			{
				files.append(item)
			}
		}
		
		
	}
	
//	override func perform() {
//		/*
//		
//		This method is called on your app’s main thread. If your app can complete the activity quickly on the main thread, do so and call the activityDidFinish(_:) method when it is done. If performing the activity might take some time, use this method to start the work in the background and then exit without calling activityDidFinish(_:) from this method. When your background work has completed, call activityDidFinish(_:). You must call activityDidFinish(_:) on the main thread.
//		*/
//		activityDidFinish(true)
//	}
	
	override class var activityCategory: UIActivity.Category
	{
		return .action
	}
}
