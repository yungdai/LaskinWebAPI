//
//  enums.swift
//  App
//
//  Created by Yung Dai on 2018-09-26.
//

import Foundation

enum TimeZones: Int, Codable {
	case pacific = 0
	case mountain = 1
	case central = 2
	case eastern = 3
	case atlantic = 4
	case newfoundland = 5
	
	static func getTimeZones() -> [String] {
		
		let timeZones = ["Pacific", "Mountain", "Central", "Eastern", "Atlantic", "Newfoundland"]
		return timeZones
	}
	
	static func timeZoneValue(by name: String) -> Int {
		switch(name) {
		case "Pacific":
			return 0
		case "Mountain":
			return 1
		case "Central":
			return 2
		case "Eastern":
			return 3
		case "Atlantic":
			return 4
		case "Newfoundland":
			return 5
		default:
			return 0
		}
	}
}

extension TimeZones: Equatable {
	
	static func ==(lhs: TimeZones, rhs: TimeZones) -> Bool {
		return (lhs == rhs) ? true : false
	}
}

// Public enums to be used for locations
enum Province: String, Codable {
	case britishColumbia = "British Columbia"
	case alberta = "Alberta"
	case saskatchewan = "Saskatchewan"
	case manitoba = "Manitoba"
	case ontario = "Ontario"
	case quebec = "Quebec"
	case novaScotia = "Nova Scotia"
	case newBrunswick = "New Brunswick"
	case princeEdwardIsland = "Prince Edward Island"
	case newfoundlandLabrador = "Newfoundland & Labrador"
	case yukon = "Yukon"
	case northwestTerritories = "Northwest Territories"
	case nunavut = "Nunavut"
	
	static func getProvinces() -> [String] {
		let provinces = ["British Columbia", "Alberta", "Saskatchewan", "Manitoba", "Ontario", "Quebec", "Nova Scotia", "New Brunswick", "Prince Edward Island", "Newfoundland & Labrardor", "Yukon", "Northwest Territories", "Nunavut"]
		return provinces
	}
}

extension Province {
	
	public var timeZone: TimeZones {
		switch self {
		case .britishColumbia, .yukon:
			return .pacific
		case .alberta, .northwestTerritories:
			return .mountain
		case .saskatchewan, .manitoba, .nunavut:
			return .central
		case .ontario, .quebec:
			return .eastern
		case .novaScotia, .princeEdwardIsland, .newBrunswick:
			return .atlantic
		case .newfoundlandLabrador:
			return .newfoundland
		}
	}
}

extension Province: Equatable {
	
	static func ==(lhs: Province, rhs: Province) -> Bool {
		
		return (lhs == rhs) ? true : false
	}
}

public enum SchoolName: String, StringRepresentableEnum, Codable {
	case alberta = "Alberta"
	case dalhousie = "Dalhousie"
	case laval = "Laval"
	case manitoba = "Manitoba"
	case mcgill = "McGill"
	case moncton = "Moncton"
	case montreal = "Montreal"
	case montréal = "Montréal"
	case osgoode = "Osgoode"
	case ottawaCivil = "Ottawa Civil"
	case ottawaCommon = "Ottawa Common"
	case queens = "Queen's"
	case saskatchewan = "Saskatchewan"
	case sherbrooke = "Sherbrooke"
	case toronto = "Toronto"
	case ubc = "UBC"
	case unb = "UNB"
	case uqam = "UQAM"
	case western = "Western"
	case windsor = "Windsor"
	
	static func getSchools() -> [SchoolData] {
		
		let alberta = SchoolData(name: "Alberta", city: "Edmonton", province:  "Alberta", timeZone: "Mountain")
		let dalhousie = SchoolData(name: "Dalhousie", city: "Halifax", province: "Nova Scotia", timeZone: "Atlantic")
		let laval = SchoolData(name: "Laval", city: "Montréal", province: "Quebec", timeZone: "Eastern")
		let manitoba = SchoolData(name: "Manitoba", city: "Winnipeg", province: "Manitoba", timeZone: "Central")
		let mcGill = SchoolData(name: "McGill", city: "Montréal", province: "Quebec", timeZone: "Eastern")
		let moncton = SchoolData(name: "Moncton", city: "Moncton", province: "New Brunswick", timeZone: "Atlantic")
		let montreal = SchoolData(name: "Montréal", city: "Montréal", province: "Quebec", timeZone: "Eastern")
		let osgoode = SchoolData(name: "Osgoode", city: "Toronto", province: "Ontario", timeZone: "Eastern")
		let ottawaCivil = SchoolData(name: "Ottawa Civil", city: "Ottawa", province: "Ontario", timeZone: "Eastern")
		let ottawaCommon = SchoolData(name: "Ottawa Common", city: "Ottawa", province: "Ontario", timeZone: "Eastern")
		let queens = SchoolData(name: "Queen's", city: "Kingston", province: "Ontario", timeZone: "Eastern")
		let saskatchewan = SchoolData(name: "Saskatchewan", city: "Saskatoon", province: "Saskatchewan", timeZone: "Central")
		let sherbrooke = SchoolData(name: "Sherbrooke", city: "Sherbrooke", province: "Quebec", timeZone: "Eastern")
		let toronto = SchoolData(name: "Toronto", city: "Toronto", province: "Ontario", timeZone: "Eastern")
		let ubc = SchoolData(name: "UBC", city: "Vancouver", province: "British Columbia", timeZone: "Pacific")
		let unb = SchoolData(name: "UNB", city: "Fredericton", province: "New Brunshwick", timeZone: "Pacific")
		let uqam = SchoolData(name: "UQAM", city: "Montréal", province: "Quebec", timeZone: "Eastern")
		let western = SchoolData(name: "Western", city: "London", province: "Ontario", timeZone: "Eastern")
		let windsor = SchoolData(name: "Windsor", city: "Windsor", province: "Ontario", timeZone: "Eastern")
		
		let schools = [alberta, dalhousie, laval, manitoba, mcGill, moncton, montreal, osgoode, ottawaCivil, ottawaCommon, queens, saskatchewan, sherbrooke, toronto, ubc, unb, uqam, western, windsor]
		
		return schools
	}
}
