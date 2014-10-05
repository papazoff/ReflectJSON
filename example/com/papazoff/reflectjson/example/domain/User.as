package com.papazoff.reflectjson.example.domain {

public class User {

    public var id:String;

    [SerializedName("name")]
    public var firstName:String;

    [SerializedName("surname")]
    public var secondName:String;

    public var address:String;

    [SerializedName("children")]
    [ElementsType("com.papazoff.reflectjson.example.domain.User")]
    public var children_untyped:Vector.<Object>;

    [Transient]
    public function get children():Vector.<User> {
        return children_untyped ? Vector.<User>(children_untyped) : null;
    }

    public function toString():String {
        return "id-" +  id + "; firstName-" + firstName + ";secondName-" + secondName + ";address-" + address + ";children-" + children;
    }

}
}
