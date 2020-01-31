### NOTE
README and framework are still in development and incomplete. This framework should not currently be used in production applications.

# CodableData
The simplest way to persist data in iOS


## What?
CodableData is an iOS persistence framework like Realm, Firebase, SharkORM or CoreData. It is meant to be simplistic, taking advantage of Swift's Encodable and Decodable protocols and requiring minimal boilerplate code.

Some frameworks take over control of an app, over-complicating simple tasks for very little value. CodableData has minimalist requirements to provide simplicity, reduced boilerplate code, thread-safe operations and type-safe queries and filtering.

CodableData is an arrow in your quiver, not a thorn in your side.


## Why?

### Simplicity
Each Database object connects to the .sqlite3 file twice, and each connection operates on its own queue (more on that later). A custom Configuration can be used to set a custom directory, file name, or queue priority--or just use the default (it saves to "/Application Support/CodableData/SQL.sqlite3")
```swift
let db = Database()

// or

// All values in initializer are optional
let config = Database.Configuration(filename: "MyAppData", syncPriority: .userInteractive, asyncPriority: .default)
let custom = Database(config)
```

### Reduced Boilerplate
Swift's relatively new Encodable and Decodable protocols provide a flexible and powerful means of converting objects to something else. A Decodable object provides a function to instantiate itself from a Decoder _one_ time and reuse that function to instantiate itself from a JSON object, a PropertyList, or some other arbitrary source; an Encodable object provides a function to do the inverse. 

CodableData uses the same function that converts an object to JSON for networking to convert an object to a row in a data table.

```swift
enum EyeColor: String, Codable {
  case blue
  case brown
}

// CodableData
struct Person: Codable, UUIDModel {
  let id: UUID
  var name: String
  var age: Int
  var eyeColor: EyeColor
}


// CoreData
class ManagedPerson: NSManagedObject {
  @NSManaged var id: UUID
  @NSManaged var name: String
  @NSManaged var age: Int // default values not allowed, may unexpectedly be nil, not enforced by the compiler
  
  @NSManaged private var eye_color: String // CoreData won't store enum value, need an intermediate for a clean-ish interface
  
  var eyeColor: EyeColor {
    get { return EyeColor(rawValue: _eyeColor) }
    set { _eyeColor = newValue.rawValue }
  }
}
```

### Thread-Safety
Every interaction with the Database is overloaded to be performed synchronously and asynchronously. Use one or the other, or switch between the two.
```swift
let billy = Person(id: UUID(), name: "Billy Bob", age: 20, eyeColor: .brown)

// synchronous
db.save(billy)

// asynchronous
db.save(billy) { (safeBilly) in
  print(safeBilly)
}

// mix and match
db.get(Person.self) { (people) in
  let bob = people.first!
  bob.age += 1  // happy birthday
  
  db.save(bob)
  
  db.count(Person.self) { (num) in
    print("\(num) people in database")
    
    let people2 = db.get(Person.self)
    print(people2)
  }
}
```
For the curious, sync and async operations are performed on different queues preventing the possibility of deadlock.

### Swiftier Filtering
Swift's relatively new KeyPaths identify a path to a property.
```swift
let filter = Filter(\Person.age, is: .greater(than: 17))
let adults = db.get(with: filter)
```

```swift
// compiles just fine, but crashes at run time
let predicate = NSPredicate(format: "age > %d", "foobar")

// type mismatch, won't compile
let badFilter = Filter(\Person.age, is: .greater(than: "foobar"))
```



CodableData can use KeyPaths to filter the results of a query for data models, enforcing type-safety at compile time, not run time.




Existing frameworks rely on old tools, for dynamic refreshing of objects, instantiating objects from dictionaries, and others. These features can be useful, but can also be cumbersome to work with.

Realm is powerful, especially when an app demands syncing a local database with a remote one (such as a server). However, properties must inherit from the framework's 'Object' model, and properties to be saved must be annotated as "@objc" and "dynamic."

CoreData requires that data models inherit from NSManagedObject, allowing the framework to 

Perhaps most importantly, none of the afore-mentioned frameworks take advantage of the Encodable and Decodable protocols. These protocols require a model to provide a means of converting itself to and from an arbitrary Data object, as is used in networking with URLSessions, 

## How?

Models must conform to the Encodable protocol (if saved to the database), the Decodable protocol (if retrieved from the database) and the SQLModel protocol (described below). Conforming to the Filterable protocol provides a clean interface to filter and sort query results.

## Limitations
