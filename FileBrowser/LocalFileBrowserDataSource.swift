//
//  FileParser.swift
//  FileBrowser
//
//  Created by Roy Marmelstein on 13/02/2016.
//  Copyright © 2016 Roy Marmelstein. All rights reserved.
//

import Foundation

public class LocalFileBrowserDataSource: FileBrowserDataSource {
    
    public var excludesFileExtensions: [String]? = nil
    public var excludesFilepaths: [URL]? = nil
    var excludesWithEmptyFilenames = false
    
    
    let fileManager = FileManager.default
    
    var rootUrl: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0] as URL
	
	public convenience init( customRootUrl: URL ) {
		self.init()
		rootUrl = customRootUrl
	}
	
    public var rootDirectory: FBFile {
        return LocalFBFile(path: rootUrl)
    }
	
	public func getContents(ofDirectory directory: FBFile) throws -> [FBFile]  {
		
		// Get contents
		let filePaths = try self.fileManager.contentsOfDirectory(at: directory.path, includingPropertiesForKeys: [], options: [.skipsHiddenFiles])
		
		// Filter
		var files = filePaths.map(LocalFBFile.init)
		if let excludesFileExtensions = excludesFileExtensions {
			let lowercased = excludesFileExtensions.map { $0.lowercased() }
			files = files.filter { !lowercased.contains($0.fileExtension?.lowercased() ?? "") }
		}
		if let excludesFilepaths = excludesFilepaths {
			files = files.filter { !excludesFilepaths.contains($0.path) }
		}
		
		// Sort
		files = files.sorted(){$0.displayName < $1.displayName}
		
		return files;
		
	}
    
    public func provideContents(ofDirectory directory: FBFile, callback: @escaping (Result<[FBFile]>) -> ()) {
        
        // Get contents
        do {
            let files = try self.getContents(ofDirectory: directory)
			
            callback(.success(files))
        } catch let error {
            callback(.error(error))
            return
        }
    }
    
    public func attributes(ofItemWithUrl fileUrl: URL) -> NSDictionary? {
        let path = fileUrl.path
        do {
            let attributes = try fileManager.attributesOfItem(atPath: path) as NSDictionary
            return attributes
        } catch {
            return nil
        }
    }
    
    public func dataURL(forFile file: FBFile) throws -> URL {
        return file.path
    }


}
