//
//  Configuration.swift
//  SQL
//
//  Created by Michael Arrington on 4/3/19.
//  Copyright © 2019 Duct Ape Productions. All rights reserved.
//

import struct Foundation.URL


struct Configuration {

    let directory: URL
    let filename: String

    var url: URL {
        return directory
            .appendingPathComponent(filename)
            .appendingPathExtension("sqlite3")
    }
}
