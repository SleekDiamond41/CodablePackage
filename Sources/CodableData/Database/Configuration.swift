//
//  Configuration.swift
//  SQL
//
//  Created by Michael Arrington on 4/3/19.
//  Copyright © 2019 Duct Ape Productions. All rights reserved.
//

import Foundation


extension Database {
	
	public struct Configuration {
		
		public let directory: URL
		public let filename: String
		public let syncPriority: DispatchQoS
		public let asyncPriority: DispatchQoS
		
		
		public static var `default`: Configuration {
			return Configuration()
		}
		
		public init(
			dir: URL = FileManager.default.urls(
			for: .applicationSupportDirectory,
			in: .userDomainMask).first!.appendingPathComponent("CodableData"),
			filename: String = "SQL",
			syncPriority: DispatchQoS = .userInteractive,
			asyncPriority: DispatchQoS = .default)
		{
			self.directory = dir
			self.filename = filename
			self.syncPriority = syncPriority
			self.asyncPriority = asyncPriority
		}
		
		public init(
			dir: URL = FileManager.default.urls(
			for: .applicationSupportDirectory,
			in: .userDomainMask).first!.appendingPathComponent("CodableData"),
			filename: String = "SQL",
			priority: DispatchQoS = .userInteractive)
		{
			self.directory = dir
			self.filename = filename
			self.syncPriority = priority
			self.asyncPriority = priority
		}
		
	}
	
}
