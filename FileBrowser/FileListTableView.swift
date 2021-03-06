//
//  FlieListTableView.swift
//  FileBrowser
//
//  Created by Roy Marmelstein on 14/02/2016.
//  Copyright © 2016 Roy Marmelstein. All rights reserved.
//

import Foundation

extension FileListViewController: UITableViewDataSource, UITableViewDelegate {
    
    //MARK: UITableViewDataSource, UITableViewDelegate
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if searchController?.isActive ?? false {
            return 1
        }
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchController?.isActive ?? false {
            return filteredFiles.count
        }
        return sections[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "FileCell"
		let reuseCell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier)
		var cell : UITableViewCell
        if reuseCell == nil
		{
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: cellIdentifier)
        }
		else
		{
			cell = reuseCell!
		}
        cell.selectionStyle = .blue
        let selectedFile = fileForIndexPath(indexPath)
		
		cell.textLabel?.font = cell.textLabel?.font.withSize(CGFloat(fileBrowserState.options?.List_FileNameFontSize ?? 17))
		if selectedFile.isDirectory
		{
			if fileBrowserState.options?.Folder_ShowItemCount ?? false
			{
				//TODO: count items in directory and then put in ()
				cell.textLabel?.text = selectedFile.displayName
			}
			else
			{
				cell.textLabel?.text = selectedFile.displayName
			}
		}
		else
		{
			cell.textLabel?.text = selectedFile.displayName
		}
		
		cell.textLabel?.adjustsFontSizeToFitWidth = true
		cell.textLabel?.minimumScaleFactor = 0.5
		
		if #available(iOS 9, *) {
			cell.textLabel?.allowsDefaultTighteningForTruncation = true
		} else {
		}

		// Image Thumbnail
		if selectedFile.type.isImage() && (fileBrowserState.options?.List_ShowImageThumbnails ?? false)
		{
			if let imageData = fileBrowserState.dataSource.dataNoThrow(forFile: selectedFile)
			{
				if let imageForUI = UIImage(data: imageData)
				{
					// clip the image to aspect ratio
					//if imageForUI.size
					cell.imageView?.image = imageForUI
				}
				else
				{
					cell.imageView?.image = selectedFile.type.image()
				}
			}
			else
			{
				cell.imageView?.image = selectedFile.type.image()
			}
		}
		else
		{
			cell.imageView?.image = selectedFile.type.image()
		}
		
		// Detail information
		if fileBrowserState.cellShowDetail
		{
			let leftDetailAttribute : FBFileAttributes = fileBrowserState.options?.FileDetail_Left ?? FBFileAttributes.FileSize
			let rightDetailAttribute : FBFileAttributes = fileBrowserState.options?.FileDetail_Right ?? FBFileAttributes.DateModified
			
			let leftDetailText = selectedFile.textForAttribute(leftDetailAttribute)
			let rightDetailText = selectedFile.textForAttribute(rightDetailAttribute)
			
			if leftDetailText.count > 0 || rightDetailText.count > 0
			{
				let attString = NSMutableAttributedString.init(string: "\(leftDetailText)\t\(rightDetailText)")
				
				let style : NSMutableParagraphStyle = NSMutableParagraphStyle()
				let adjustment : CGFloat = fileBrowserState.shouldIncludeIndex() ? 15 : 0 //TODO: replace with width of index
				let rightLocation : CGFloat = cell.frame.width - (115 + adjustment)
				style.tabStops = [NSTextTab.init(textAlignment: .right, location: rightLocation, options: [:])]
				
				attString.beginEditing()
				attString.addAttribute(NSAttributedString.Key.paragraphStyle, value: style, range: NSMakeRange(0, leftDetailText.count + rightDetailText.count))
				attString.endEditing()
				
				cell.detailTextLabel?.font = cell.detailTextLabel?.font.withSize(CGFloat(fileBrowserState.options?.List_FileDetailFontSize ?? 10))
				cell.detailTextLabel?.attributedText = attString
			}
			else
			{
				cell.detailTextLabel?.text = nil
			}
		}
		
		// Disclosure (Info) button
		if fileBrowserState.options?.File_ShowDisclosureButton ?? true
		{
			cell.accessoryType = fileBrowserState.cellAcc
		}
		else
		{
			cell.accessoryType = .none
		}
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedFile = fileForIndexPath(indexPath)
        searchController?.isActive = false
		fileBrowserState.viewFile(file: selectedFile, controller: self, fileList: sortedFileList())
        //tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if (fileBrowserState.shouldIncludeIndex() == false) || (searchController?.isActive ?? false) {
            return nil
        }
        if sections[section].count > 0 {
            return fileBrowserState.collation.sectionTitles[section]
        }
        else {
            return nil
        }
    }
    
    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        if (fileBrowserState.shouldIncludeIndex() == false) || (searchController?.isActive ?? false)
		{
            return nil
        }
        return fileBrowserState.collation.sectionIndexTitles
    }
    
    func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        if (fileBrowserState.shouldIncludeIndex() == false) || (searchController?.isActive ?? false) {
            return 0
        }
        return fileBrowserState.collation.section(forSectionIndexTitle: index)
    }
    
    
}
