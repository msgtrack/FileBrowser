
import Foundation

@objc public protocol FileFilterSettings
{
	var minimumFileSize : Int { get }
	var maximumFileSize : Int { get }

	var filterEnabled: Bool { get }
}
