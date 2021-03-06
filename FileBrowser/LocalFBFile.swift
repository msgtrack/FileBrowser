//
//  LocalFBFile.swift
//  FileBrowser
//
//

import Foundation

open class LocalFBFile : FBFile
{
	
	open override func enclosingDirectory() -> FBFile
	{
		let baseURL = path.deletingLastPathComponent()
		
		return LocalFBFile( path: baseURL )
	}

	static func ==(lhs: LocalFBFile, rhs: FBFile) -> Bool
	{
		return lhs.path == rhs.path
	}
	
	override open func delete()
	{
		guard fileLocation != nil else
		{
			print("Could not delete nil file location.")
			return
		}
		
		do
		{
			try FileManager.default.removeItem(at:fileLocation!)
			fileLocation = nil
		}
		catch
		{
			AlertUtilities.Alert_Show(title: "Error", message: "An error occured when trying to delete file:\(String(describing: self.fileLocation)) Error:\(error)")
		}
	}

	open override func createDirectory(name: String) -> Bool
	{
		guard fileLocation != nil else
		{
			print("Could not create directory at nil file location.")
			return false
		}
		
		guard isDirectory else
		{
			print("Could not create a directory inside a file.")
			return false
		}

		do
		{
			if let dirPath = fileLocation?.appendingPathComponent(name, isDirectory: true)
			{
				try FileManager.default.createDirectory(at: dirPath, withIntermediateDirectories: false, attributes: nil)
				return true
			}
		}
		catch
		{
			AlertUtilities.Alert_Show(title: "Error", message: "An error occured when trying to create a directory:\(String(describing: self.fileLocation)) Error:\(error)")
		}
		return false
	}
	
	/*
	Create file at this directory location
	*/
	open override func createFile(name: String, data: Data) -> Bool
	{
		guard fileLocation != nil else
		{
			print("Could not create file at nil file location.")
			return false
		}
		
		guard isDirectory else
		{
			print("Could not create a file inside a file.")
			return false
		}
		
		if let dirPath = fileLocation?.appendingPathComponent(name, isDirectory: false)
		{
			if FileManager.default.fileExists(atPath: dirPath.path) == false
			{
				//FileManager.default.createFile(atPath: dirPath.absoluteString, contents: nil, attributes: nil)
				do
				{
					try data.write(to: dirPath, options: Data.WritingOptions.atomicWrite)
					return true
				}
				catch
				{
					AlertUtilities.Alert_Show(title: "Error", message: "Could not create file.")
				}
			}
			else
			{
				AlertUtilities.Alert_Show(title: "File Exists", message: "Could not create file as file with that name already exists.")
			}
		}
		return false
	}
	
	open override func createFileWithUniqueName(name: String, fileExt: String, data: Data) -> Bool
	{
		guard fileLocation != nil else
		{
			print("Could not create file at nil file location.")
			return false
		}
		
		guard isDirectory else
		{
			print("Could not create a file inside a file.")
			return false
		}
		
		var hasNewName = false
		var testName = "\(name).\(fileExt)"
		var indexTest = 1
		repeat
		{
			if let dirPath = fileLocation?.appendingPathComponent(testName, isDirectory: false)
			{
				if FileManager.default.fileExists(atPath: dirPath.path)
				{
					// be careful with file extension
					testName = name.appendingFormat(" %d.%@", indexTest, fileExt)
					indexTest += 1
				}
				else
				{
					hasNewName = true
					return createFile(name: testName, data: data)
				}
			}
		} while( hasNewName == false )
	}

	
	open override func getFileSize() -> Int
	{
		do
		{
			if let resourceValues = try fileLocation?.resourceValues(forKeys: [URLResourceKey.fileSizeKey])
			{
				return resourceValues.fileSize ?? 0
			}
		}
		catch
		{
		}
		return 0;
	}
	
	open override func getCreationDate() -> Date
	{
		do
		{
			if let resourceValues = try fileLocation?.resourceValues(forKeys: [URLResourceKey.creationDateKey])
			{
				return resourceValues.creationDate ?? Date()
			}
		}
		catch
		{
		}
		return Date()
	}
	
	open override func getFileAddedDate() -> Date
	{
		do
		{
			if let resourceValues = try fileLocation?.resourceValues(forKeys: [URLResourceKey.addedToDirectoryDateKey])
			{
				return resourceValues.addedToDirectoryDate ?? Date()
			}
		}
		catch
		{
		}
		return Date()
	}

	open override func getModificationDate() -> Date
	{
		do
		{
			if let resourceValues = try fileLocation?.resourceValues(forKeys: [URLResourceKey.contentModificationDateKey])
			{
				return resourceValues.contentModificationDate ?? Date()
			}
		}
		catch
		{
		}
		return Date()
	}

	open override func isInICloud() -> Bool {
		do
		{
			if let resourceValues = try fileLocation?.resourceValues(forKeys: [URLResourceKey.isUbiquitousItemKey])
			{
				return resourceValues.isUbiquitousItem ?? false
			}
		}
		catch
		{
		}
		return false
	}
	
	open override func moveTo(directory: FBFile) -> FBFile {
		guard let currentLocation = fileLocation else
		{
			print("Could not move nil file location.")
			return self
		}
		
		guard let moveToLocation = directory.fileLocation else
		{
			print("Could not move to nil file location.")
			return self
		}
		
		guard directory.isDirectory else
		{
			print("Could not move to a file")
			return self
		}
		
		let newLocation = moveToLocation.appendingPathComponent(currentLocation.lastPathComponent, isDirectory: self.isDirectory)
		
		do
		{
			try FileManager.default.moveItem(at: currentLocation, to: newLocation)
			
			return LocalFBFile(path: newLocation)
		}
		catch
		{
			AlertUtilities.Alert_Show(title: "Error moving file", message: error.localizedDescription)
		}
		
		return self
	}
	
	open override func rename(name:String) -> FBFile
	{
		guard let currentLocation = fileLocation else
		{
			print("Could not rename nil file location.")
			return self
		}
		
		let newLocation = currentLocation.deletingLastPathComponent().appendingPathComponent(name, isDirectory: isDirectory)
		
		do
		{
			try FileManager.default.moveItem(at: currentLocation, to: newLocation)
			return LocalFBFile(path: newLocation)
		}
		catch
		{
			AlertUtilities.Alert_Show(title: "Error renaming file", message: error.localizedDescription)
		}
		
		return self
	}
	
	open override func hasViewPermission() -> Bool
	{
		guard path.isFileURL else
		{
			return false
		}
		
		do
		{
			let resourceValues = try path.resourceValues(forKeys: [URLResourceKey.isReadableKey])
			
			return resourceValues.isReadable ?? false
			
		}
		catch
		{
		}

		
		return false
	}
	
}
