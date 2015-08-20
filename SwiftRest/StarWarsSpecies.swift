//
//  StarWarsSpecies.swift
//  SwiftRest
//
//  Created by Christina Moulton on 2015-08-20.
//  Copyright (c) 2015 Teak Mobile Inc. All rights reserved.
//

/* API response to http://swapi.co/api/species/3 looks like:

{
"average_height": "2.1",
"average_lifespan": "400",
"classification": "Mammal",
"created": "2014-12-10T16:44:31.486000Z",
"designation": "Sentient",
"edited": "2014-12-10T16:44:31.486000Z",
"eye_colors": "blue, green, yellow, brown, golden, red",
"hair_colors": "black, brown",
"homeworld": "http://swapi.co/api/planets/14/",
"language": "Shyriiwook",
"name": "Wookie",
"people": [
"http://swapi.co/api/people/13/"
],
"films": [
"http://swapi.co/api/films/1/",
"http://swapi.co/api/films/2/"
],
"skin_colors": "gray",
"url": "http://swapi.co/api/species/3/"
}
*/

import Foundation
import Alamofire
import SwiftyJSON

enum SpeciesFields: String {
  case Name = "name"
  case Classification = "classification"
  case Designation = "designation"
  case AverageHeight = "average_height"
  case SkinColors = "skin_colors"
  case HairColors = "hair_colors"
  case EyeColors = "eye_colors"
  case AverageLifespan = "average_lifespan"
  case Homeworld = "homeworld"
  case Language = "language"
  case People = "people"
  case Films = "films"
  case Created = "created"
  case Edited = "edited"
  case Url = "url"
}

class SpeciesWrapper {
  var species: Array<StarWarsSpecies>?
  var count: Int?
  private var next: String?
  private var previous: String?
}

class StarWarsSpecies {
  var idNumber: Int?
  var name: String?
  var classification: String?
  var designation: String?
  var averageHeight: Int?
  var skinColors: String?
  var hairColors: String? // TODO: parse into array
  var eyeColors: String? // TODO: array
  var averageLifespan: Int?
  var homeworld: String?
  var language: String?
  var people: Array<String>?
  var films: Array<String>?
  var created: NSDate?
  var edited: NSDate?
  var url: String?
  
  required init(json: JSON, id: Int?) {
    println(json)
    self.idNumber = id
    self.name = json[SpeciesFields.Name.rawValue].stringValue
    self.classification = json[SpeciesFields.Classification.rawValue].stringValue
    self.designation = json[SpeciesFields.Designation.rawValue].stringValue
    self.averageHeight = json[SpeciesFields.AverageHeight.rawValue].int
    // TODO: add all the fields!
  }
  
  // MARK: Endpoints
  class func endpointForSpecies() -> String {
    return "http://swapi.co/api/species/"
  }
  
  private class func getSpeciesAtPath(path: String, completionHandler: (SpeciesWrapper?, NSError?) -> Void) {
    Alamofire.request(.GET, path)
      .responseSpeciesArray { (request, response, speciesWrapper, error) in
        if let anError = error
        {
          completionHandler(nil, error)
          return
        }
        completionHandler(speciesWrapper, nil)
    }
  }
  
  class func getSpecies(completionHandler: (SpeciesWrapper?, NSError?) -> Void) {
    getSpeciesAtPath(StarWarsSpecies.endpointForSpecies(), completionHandler: completionHandler)
  }
  
  
  class func getMoreSpecies(wrapper: SpeciesWrapper?, completionHandler: (SpeciesWrapper?, NSError?) -> Void) {
    if wrapper == nil || wrapper?.next == nil
    {
      completionHandler(nil, nil)
      return
    }
    getSpeciesAtPath(wrapper!.next!, completionHandler: completionHandler)
  }
}

extension Alamofire.Request {
  func responseSpeciesArray(completionHandler: (NSURLRequest, NSHTTPURLResponse?, SpeciesWrapper?, NSError?) -> Void) -> Self {
    let responseSerializer = GenericResponseSerializer<SpeciesWrapper> { request, response, data in
      if let responseData = data
      {
        var jsonError: NSError?
        let jsonData:AnyObject? = NSJSONSerialization.JSONObjectWithData(data!, options: nil, error: &jsonError)
        if jsonData == nil || jsonError != nil
        {
          return (nil, jsonError)
        }
        let json = JSON(jsonData!)
        if json.error != nil || json == nil
        {
          return (nil, json.error)
        }
        
        var wrapper:SpeciesWrapper = SpeciesWrapper()
        wrapper.next = json["next"].stringValue
        wrapper.previous = json["previous"].stringValue
        wrapper.count = json["count"].intValue
        
        var allSpecies:Array = Array<StarWarsSpecies>()
        println(json)
        let results = json["results"]
        println(results)
        for jsonSpecies in results
        {
          println(jsonSpecies.1)
          let species = StarWarsSpecies(json: jsonSpecies.1, id: jsonSpecies.0.toInt())
          allSpecies.append(species)
        }
        wrapper.species = allSpecies
        return (wrapper, nil)
      }
      return (nil, nil)
    }
    
    return response(responseSerializer: responseSerializer,
      completionHandler: completionHandler)
  }
}