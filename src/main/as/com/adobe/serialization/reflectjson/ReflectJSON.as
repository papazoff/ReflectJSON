/*
 Copyright (c) 2008, Adobe Systems Incorporated
 All rights reserved.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are
 met:

 * Redistributions of source code must retain the above copyright notice,
 this list of conditions and the following disclaimer.

 * Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in the
 documentation and/or other materials provided with the distribution.

 * Neither the name of Adobe Systems Incorporated nor the names of its
 contributors may be used to endorse or promote products derived from
 this software without specific prior written permission.

 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
 IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
 THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
 CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

package com.adobe.serialization.reflectjson {

/**
 * This class provides encoding to JSON and decoding to domain objects functionality.
 *
 * Example usage:
 * <code>
 *        // Encode domain object to a JSON string
 *        ReflectJSON.toJSONString( domainObject );
 *
 *        // Decode JSON string into domain object
 *        var myObject:DomainClass = ReflectJSON.fromJSONString( jsonString, domainClass );
 *        // OR
 *        var myObject:DomainClass = ReflectJSON.fromJSONString( jsonString, collectionType, domainClass );
 *
 *        //If you know that JSON string contains unexpected fields which are not required in your domain object, you can do as follows
 *        var myObject:DomainClass = ReflectJSON.fromJSONStringSkipUnexpected( jsonString, domainClass );
 *        //OR
 *        var myObject:DomainClass = ReflectJSON.fromJSONStringSkipUnexpected( jsonString, collectionType, domainClass );
 *
 * </code>
 */

public class ReflectJSON {

    /**
     * Encodes a domain object into a JSON string.
     *
     * @param o is a domain object which will be serialized to JSON string
     * @return JSON string representing o
     * @langversion ActionScript 3.0
     * @playerversion Flash 9.0 and above
     */
    public static function toJSONString(o:Object):String {
        return new ReflectJSONEncoder(o).getString();
    }

    /**
     * Decodes a JSON string into a domain object.
     *
     * @param json - JSON string
     * @param type - expected domain class to be created
     * @param elementsType - elements type in case we need to get collection of elements as a result
     * @return domain object or collection of domain objects specified by <code>type</code> and <code>elementsType</code> attributes
     * @throws com.adobe.serialization.json.JSONParseError
     * @langversion ActionScript 3.0
     * @playerversion Flash 9.0 and above
     */
    public static function fromJSONString(json:String, type:Class, elementsType:Class = null):* {
        return new ReflectJSONDecoder(json, type, elementsType).getValue();
    }

    /**
     * Decodes a JSON string into a domain object and skips unexpected fields if found.
     *
     * @param json - JSON string
     * @param type - expected domain class to be created
     * @param elementsType - elements type in case we need to get collection of elements as a result
     * @return domain object or collection of domain objects specified by <code>type</code> and <code>elementsType</code> attributes
     * @throws com.adobe.serialization.json.JSONParseError
     * @langversion ActionScript 3.0
     * @playerversion Flash 9.0 and above
     */
    public static function fromJSONStringSkipUnexpected(json:String, type:Class, elementsType:Class = null):* {
        return new ReflectJSONDecoder(json, type, elementsType, true).getValue();
    }

}
}