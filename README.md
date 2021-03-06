# ReflectJSON

ReflectJSON is an extension to the JSON serialization from as3corelib library to allow decode JSON strings into domain objects and vice versa.

### Download

[ReflectJSON.swc](https://github.com/papazoff/ReflectJSON/blob/master/bin/ReflectJSON.swc?raw=true)

### Developed with pleasure using IntelliJ IDEA

<a href="http://www.jetbrains.com/idea/features/flex_ide.html"><img src="http://www.jetbrains.com/idea/opensource/img/all/banners/idea468x60_white.gif"></a>

# Quickstart

## How to start with ReflectJSON

To use ReflectJSON in your project, you have to include ReflectJSON.swc to your project libraries. And then import it in your source code.

Plain ActionScript:

```as3

import com.adobe.serialization.reflectjson.ReflectJSON;

```

## Encoding domain objects to JSON string with ReflectJSON

Let's see how to encode domain objects into JSON string.

User.as:

```as3

public class User {

    public var id:String;
    public var firstName:String;
    public var secondName:String;
    public var address:String;

}

```

Main.mxml:

```xml
...

    <fx:Script>
        <![CDATA[
        import com.adobe.serialization.reflectjson.ReflectJSON;
        import com.adobe.serialization.reflectjson.example.domain.User;

        private function encode():void {
            var user:User = new User();
            user.id = "00000000-0000-0000-0000-000000000001";
            user.firstName = "Steve";
            user.secondName = "Jobs";
            user.address = "1 Infinite Loop, Cupertino, CA 95014";

            resultTextArea.text += ReflectJSON.toJSONString(arr);
        }

        ]]>
    </fx:Script>

    <s:Button click="encode();" label="Encode"/>
    <s:TextArea id="resultTextArea" width="400" height="700" />

...

```

When you run this code and click Encode button, you have to see the next output:

```js

{"secondName":"Jobs","id":"00000000-0000-0000-0000-000000000000","firstName":"Steve","address":"1 Infinite Loop, Cupertino, CA 95014"}

```

This is pretty elementary and can be performed with simple JSON serializer, but we are going to experiment further.
Let's say that our back-end accepts a bit different fields/properties names, in this situation we can mark our
fields/properties with reserved Metadata tag.

```as3

public class User {

    [SerializedName("UUID")]
    public var id:String;

    [SerializedName("Name")]
    public var firstName:String;

    [SerializedName("Surname")]
    public var secondName:String;

    [SerializedName("Address")]
    public var address:String;

}

```

And resulting JSON string will be the next one:

```js

{"Surname":"Jobs","UUID":"00000000-0000-0000-0000-000000000000","Name":"Steve","Address":"1 Infinite Loop, Cupertino, CA 95014"}

```

If you don't want to include some fields/properties to your resulting JSON string, just mark it with  ``` [Transient] ``` Metadata tag.


## Encoding collections to JSON string with ReflectJSON

Suppose we extended our  ``` User ``` object with ``` children ``` field of type Array where we want to store records of type ``` User ```.
And once again we are going to use reserved Metadata tag ``` [ElementsType] ```.

```as3

public class User {

    ...

    [ElementsType("User")]
    public var children:Array;

}

```

This will help us encode our collection of objects with necessary name changes during serialization,
and then this will help us to decode JSON string to domain object with all necessary types and names.

Also you can combine metadata tags as follows:

```as3

public class User {

    ...

    [SerializedName("Children")]
    [ElementsType("User")]
    public var children:Array;

}

```

Encoding result will be:

```js

{"Surname":"Jobs","UUID":"00000000-0000-0000-0000-000000000000","Name":"Steve","Address":"1 Infinite Loop, Cupertino, CA 95014",
"Children":[{"Surname":"Jobs","UUID":"00000000-0000-0000-0000-000000000001","Name":"Reed",
"Address":"1 Infinite Loop, Cupertino, CA 95014","Children":null}]}

```

## Decoding JSON string to domain object with ReflectJSON

To decode JSON string to domain object we'll use the next code:

Main.mxml:

```xml
...

    <fx:Script>
        <![CDATA[
        import com.adobe.serialization.reflectjson.ReflectJSON;
        import com.adobe.serialization.reflectjson.example.domain.User;

        private static const JSON_OBJECT:String = '' +
                        '{"UUID":"00000000-0000-0000-0000-000000000000",' +
                        '"Name":"Steve",' +
                        '"Surname":"Jobs",' +
                        '"Address":"1 Infinite Loop, Cupertino, CA 95014",' +
                        '"Children":' +
                        '[' +
                        '{"UUID":"00000000-0000-0000-0000-000000000001","Name":"Lisa","Surname":"Brennan Jobs","Address":"1 Infinite Loop, Cupertino, CA 95014"},' +
                        '{"UUID":"00000000-0000-0000-0000-000000000002","Name":"Reed","Surname":"Jobs","Address":"1 Infinite Loop, Cupertino, CA 95014"},' +
                        '{"UUID":"00000000-0000-0000-0000-000000000003","Name":"Erin","Surname":"Jobs","Address":"1 Infinite Loop, Cupertino, CA 95014"},' +
                        '{"UUID":"00000000-0000-0000-0000-000000000004","Name":"Eve","Surname":"Jobs","Address":"1 Infinite Loop, Cupertino, CA 95014"}' +
                        ']' +
                        '}';

        private function decode():void {
            var user:User = ReflectJSON.fromJSONString(JSON_OBJECT, User);
        }

        ]]>
    </fx:Script>

    <s:Button click="decode();" label="Decode"/>
    <s:TextArea id="resultTextArea" width="400" height="700" />

...

```

If you have array of objects in JSON string, for example:

```js

[
    {"id":"00000000-0000-0000-0000-000000000001","name":"Steve","surname":"Jobs","address":"1 Infinite Loop, Cupertino, CA 95014"},
    {"id":"00000000-0000-0000-0000-000000000002","name":"Steve","surname":"Wozniak","address":"1 Infinite Loop, Cupertino, CA 95014"},
    {"id":"00000000-0000-0000-0000-000000000003","name":"Ronald","surname":"Wayne","address":"1 Infinite Loop, Cupertino, CA 95014"}
]

```

you can decode it to array of domain objects as follows:

```as3

var arr:Array = ReflectJSON.fromJSONString(JSON_OBJECT, Array, User);

```


If you know that JSON string contains unused fields by your client-side application, you have to skip them from parsing as follows:


```as3

//object decoding
var arr:Array = ReflectJSON.fromJSONStringSkipUnexpected(JSON_OBJECT, User);

//collection decoding
var arr:Array = ReflectJSON.fromJSONStringSkipUnexpected(JSON_OBJECT, Array, User);

```

## Vector, encoding and decoding typed data structure

To encode domain object that contains fields/properties of type Vector as simple as encoding Array.
Even if you have assigned domain type to it, for example Vector.<User>, which says that it's a Vector of Users.
But troubles come up when you want to decode JSON string to domain object with fields/properties of type Vector,
because we cant assign dynamically created types as Vector types, that is why we have to use Object as type for
Vector object that has been created during JSON string decoding.

But if you really need your domain object to provide a Vector of domain objects to the rest of the application, you can do the next.
Let's make couple changes in our User object:

```as3

public class User {

    [SerializedName("UUID")]
    public var id:String;

    [SerializedName("Name")]
    public var firstName:String;

    [SerializedName("Surname")]
    public var secondName:String;

    [SerializedName("Address")]
    public var address:String;

    [SerializedName("Children")]
    [ElementsType("User")]
    public var children_untyped:Vector.<Object>;

    [Transient]
    public function get children():Vector.<User>{
        return children_untyped ? Vector.<User>(children_untyped) : null;
    }

}

```

This way we can access typed ``` children ``` Vector property from the application, but this property will not be serialized to JSON string.

Enjoy and feel free to contact me if you find bugs.

Example application can be found in example folder in the root of repository.
