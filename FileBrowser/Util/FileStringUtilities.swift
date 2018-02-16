//
//  FileStringUtilities.swift
//  FileBrowser
//
//  Created by Eric Patno on 5/3/17.
//  Copyright © 2017 Eric Patno. All rights reserved.
//

import Foundation


func String_GetDisplayTextForFileSize( file : FBFile, displayType: Bool ) -> String
{
	if file.isDirectory
	{
		if( displayType )
		{
			return "Folder" // TODO: later calculate folder size?
		}
	}
	else
	{
		return "\(file.getFileSize()) bytes"
	}
	return ""
}

let gRFC3339DateFormatter = InitDateFormatter()

func InitDateFormatter() -> DateFormatter
{
	let RFC3339DateFormatter = DateFormatter()
	
	RFC3339DateFormatter.locale = Locale(identifier: "en_US_POSIX")
	RFC3339DateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
	RFC3339DateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
	
	return RFC3339DateFormatter
}

func String_GetDateStringForSorting( date : Date ) -> String
{

	return gRFC3339DateFormatter.string(from: date)
}
