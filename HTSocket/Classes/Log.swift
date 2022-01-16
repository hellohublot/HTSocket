//
//  Log.swift
//  CocoaLumberjack
//
//  Created by hublot on 2018/2/1.
//

import asl

public extension LogManager {
	
	static var shareLogManager = LogManager(
		[
			AppleLog.self,
		]
	)
	
}

public func Log(_ info: Any ..., file: String = #file, function: String = #function, line: Int = #line) {
	guard let share = LogManager.shareLogManager, share.logAblelist.count > 0 else {
		return
	}
	let name = file.components(separatedBy: "/").last?.replacingOccurrences(of: ".swift", with: "") ?? ""
	var array = info
	var level: Int = 1
	for (index, item) in info.enumerated() {
		var value: Int?
		if let temp = item as? Int {
			value = temp
		}
		if let temp = item as? Bool {
			value = temp ? 1 : 0
		}
		if let temp = value {
			level = temp
			array.remove(at: index)
			break
		}
	}
	let prefix = "[\(name) - \(function)]: "
	var suffix = "\(array)"
	let state: String = {
		var state: String
		switch level {
		case 1: state = "✅"
		case 0: state = "⚠️"
		case -1: state = "❌"
		default: state = "✅"
		}
		return state
	}()
	suffix.append(" " + state)
	if suffix.count > 30 {
		suffix = "↓\n\t" + suffix
	}
	
	let message = prefix + suffix
	share.receiveMessage(message)
}

open class LogManager {
	
	public var logAblelist: [LogAble.Type]
	
	init?(_ logAbleList: [LogAble.Type]) {
		guard logAbleList.count > 0 else {
			return nil
		}
		self.logAblelist = logAbleList
	}
	
	func receiveMessage(_ message: String) {
		for log in logAblelist {
			log.write(message)
		}
	}
	
}

public protocol LogAble {
	
	static var queue: DispatchQueue { get }
	
	static func write(_ message: String)
	
}

open class AppleLog: LogAble {
	
	public static var queue: DispatchQueue = DispatchQueue.init(label: "com.hublot.Log.appleQueue")
	
	static var client: asl_object_t?
	
	static let levelStringList = ["0", "1", "2", "3", "4", "5", "6", "7"]
	
	static var readUIDString: Int8 = {
		let uid = geteuid()
		var readUIDString:Int8 = 0
		let format = "%d"
		let _ = snprintf(ptr: &readUIDString, 16, format, uid)
		return readUIDString
	}()
	
    public static func write(_ message: String) {
		queue.async {
			if client == nil {
				DispatchQueue.main.sync {
					let client = asl_open(nil, "com.apple.console", 0)
					self.client = client
				}
			}
			let levelValue = Int(ASL_LEVEL_NOTICE)
			let levelString = levelStringList[levelValue]
			let m = asl_new(UInt32(ASL_TYPE_MSG))
			if (asl_set(m, ASL_KEY_LEVEL, levelString) == 0 &&
				asl_set(m, ASL_KEY_MSG, message) == 0 &&
				asl_set(m, ASL_KEY_READ_UID, &readUIDString) == 0 &&
				asl_set(m, "Log", "1") == 0) {
				asl_send(client, m);
			}
			asl_free(m)
		}
	}
	
}

