//
//  FBFile.swift
//  FileBrowser
//
//  Created by Roy Marmelstein on 14/02/2016.
//  Copyright © 2016 Roy Marmelstein. All rights reserved.
//

import Foundation
import UIKit


public protocol FBFileProto
{
	// TODO: fix this to have the actual members such as displayName, path, etc
	var file : FBFile? { get }
	
	var image: UIImage? { get }
}

/// FBFile is a class representing a file in FileBrowser
@objc open class FBFile: NSObject, FBFileProto {
	// Temp implementation for FBFileProto
	public var file : FBFile? { get { return self } }
	public var image: UIImage? { get { return nil } }
	//
	
    /// Display name. String.
    @objc open var displayName: String
    // is Directory. Bool.
    public let isDirectory: Bool
    /// File extension.
    public let fileExtension: String?
    /// File attributes (including size, creation date etc).
    //open let fileAttributes: NSDictionary? = nil
    
    /// Describes where the resource can be found. May be a file:// or http[s]:// URL
	var fileLocation: URL?
    // FBFileType
    public var type: FBFileType
    
    /// Describes the path in the current file system, e.g. /dir/file.txt
    @objc public let path: URL
    
    /**
     Initialize an FBFile object with a filePath
     
     - parameter filePath: NSURL filePath
     
     - returns: FBFile object.
     */
    @objc public init(path: URL) {
		// TODO: check permissions
		self.path = path.resolvingSymlinksInPath()
		self.fileLocation = self.path
		self.isDirectory = checkDirectory(self.path)
		
		if self.isDirectory
		{
			self.fileExtension = nil
			self.type = .Directory
		}
		else
		{
			if path.pathExtension != ""
			{
				self.fileExtension = path.pathExtension
				self.type = FBFileType(rawValue: fileExtension!.lowercased()) ?? .Default
			}
			else
			{
				self.fileExtension = nil
				self.type = .Default
			}
		}
		self.displayName = path.lastPathComponent

    }
	
	static func ==(lhs: FBFile, rhs: FBFile) -> Bool
	{
		return lhs.path == rhs.path
	}

	static func ==(lhs: FBFile, rhs: FBFile?) -> Bool
	{
		return lhs.path == rhs?.path
	}

	static func !=(lhs: FBFile, rhs: FBFile) -> Bool
	{
		return lhs.path != rhs.path
	}

	public var isRemoteFile: Bool {
        return fileLocation?.scheme == "http" || fileLocation?.scheme == "https"
    }
	
	open func enclosingDirectory() -> FBFile
	{
		let baseURL = path.deletingLastPathComponent()
		
		return FBFile( path: baseURL )
	}
	
	open func folderListFrom(directory: FBFile) -> [FBFile]
	{
		// Create the folder list
		var folderList = [FBFile]()
		
		if directory == self
		{
			return folderList
		}
		
		let absURLForSelf = self.path.resolvingSymlinksInPath()
		let absURLForDir = directory.path.resolvingSymlinksInPath()
		
		if !absURLForSelf.absoluteString.contains(absURLForDir.absoluteString)
		{
			return folderList
		}

		var curDir = enclosingDirectory()
		while curDir != directory
		{
			folderList.append(curDir)
			curDir = curDir.enclosingDirectory()
		}
		folderList.append(curDir)
		
		return folderList.reversed()
	}
	
	open func delete()
	{
		// override for local file browser
	}
	
	open func createFile(name: String) -> Bool
	{
		return createFile(name: name, data: Data())
	}
	
	open func createFileWithUniqueName(name: String, fileExt: String, data: Data) -> Bool
	{
		// override for local file browser
		return false
	}
	
	open func createFile(name: String, data: Data) -> Bool
	{
		// override for local file browser
		return false
	}
	
	open func createDirectory(name: String) -> Bool
	{
		// override for local file browser
		return false
	}
	
	static let dateFormatter = DateFormatter()
	
	@objc open func getFileAddedDateDisplayString() -> String
	{
		FBFile.dateFormatter.dateStyle = .short
		FBFile.dateFormatter.timeStyle = .short
		return FBFile.dateFormatter.string(from: getFileAddedDate())
	}
	
	@objc open func getFileAddedDateStringForSorting() -> String
	{
		return String_GetDateStringForSorting(date: getFileAddedDate())
	}
	
	@objc open func getCreationDateDisplayString() -> String
	{
		FBFile.dateFormatter.dateStyle = .short
		FBFile.dateFormatter.timeStyle = .short
		return FBFile.dateFormatter.string(from: getCreationDate())
	}
	
	@objc open func getCreationDateStringForSorting() -> String
	{
		return String_GetDateStringForSorting(date: getCreationDate())
	}
	
	@objc open func getModificationDateDisplayString() -> String
	{
		FBFile.dateFormatter.dateStyle = .short
		FBFile.dateFormatter.timeStyle = .short
		return FBFile.dateFormatter.string(from: getModificationDate())
	}
	
	@objc open func getModificationDateStringForSorting() -> String
	{
		return String_GetDateStringForSorting(date: getModificationDate())
	}
	
	@objc open func getFileSizeDisplayString() -> String
	{
		return String_GetDisplayTextForFileSize(file: self, displayType: false)
	}
	
	@objc open func getFileTypeDisplayString() -> String
	{
		return type.rawValue
	}
	
	open func textForAttribute( _ attrib : FBFileAttributes ) -> String
	{
		switch attrib {
		case .DateAdded:
			return getFileAddedDateDisplayString()
		case .DateCreated:
			return getCreationDateDisplayString()
		case .DateModified:
			return getModificationDateDisplayString()
		case .FileSize:
			return getFileSizeDisplayString()
		case .FileName:
			return displayName
		case .FileType:
			return getFileTypeDisplayString()
		case .None:
			return ""
		}
	}
	
	open func getFileSize() -> Int
	{
		return 0
	}
	
	open func getFileAddedDate() -> Date
	{
		return Date()
	}

	open func getCreationDate() -> Date
	{
		return Date()
	}
	
	open func getModificationDate() -> Date
	{
		return Date()
	}
	
	open func isInICloud() -> Bool
	{
		return false
	}
	
	open func moveTo(directory:FBFile) -> FBFile
	{
		return self
	}
	
	open func rename(name:String) -> FBFile
	{
		return self
	}
	
	open func fileNameWithoutExtension() -> String
	{
		let filename : NSString = path.lastPathComponent as NSString
		
		return filename.deletingPathExtension
	}
	
	open func hasViewPermission() -> Bool
	{
		return false
	}
}

/**
 FBFile type
 */
public enum FBFileType: String {
    /// Directory
    case Directory = "directory"
	/// BMP file
	case BMP = "bmp"
    /// GIF file
    case GIF = "gif"
    /// JPG file
    case JPG = "jpg"
	case JPEG = "jpeg"
	// High Efficiency Image File Format (Heif/heic)
	case HEIF = "heif"
	case HEIC = "heic"
    /// PLIST file
    case JSON = "json"
    /// PDF file
    case PDF = "pdf"
    /// PLIST file
    case PLIST = "plist"
    /// PNG file
    case PNG = "png"
    /// ZIP file
    case ZIP = "zip"
	/// Text file
	case TXT = "txt"
	case TEXT = "text"
    /// Any file
    case Default = "file"
	
	public func isImage() -> Bool
	{
		switch self {
		case .JPG, .JPEG, .PNG, .GIF, .BMP, .HEIF, .HEIC:
			return true
		default:
			return false
		}
	}
	
    /**
     Get representative image for file type
     
     - returns: UIImage for file type
     */
    public func image() -> UIImage? {
        let bundle = Bundle(for: FBFile.self)
        var fileName = String()
        switch self {
        case .Directory: fileName = "folder@2x.png"
        case .JPG, .JPEG, .BMP, .PNG, .GIF, .HEIF, .HEIC: fileName = "image@2x.png"
        case .PDF: fileName = "pdf@2x.png"
        case .ZIP: fileName = "zip@2x.png"
        default: fileName = "file@2x.png"
        }
        let file = UIImage(named: fileName, in: bundle, compatibleWith: nil)
        return file
    }
}

/**
 Check if file path NSURL is directory or file.
 
 - parameter filePath: NSURL file path.
 
 - returns: isDirectory Bool.
 */
func checkDirectory(_ filePath: URL) -> Bool {
    if #available(iOS 9.0, *) {
        return filePath.hasDirectoryPath
    }
    var isDirectory = false
    do {
        var resourceValue: AnyObject?
        try (filePath as NSURL).getResourceValue(&resourceValue, forKey: URLResourceKey.isDirectoryKey)
        if let number = resourceValue as? NSNumber , number == true {
            isDirectory = true
        }
    }
    catch { }
    return isDirectory
}
