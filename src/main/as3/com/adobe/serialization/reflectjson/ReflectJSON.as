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
 * This class provides encoding and decoding of the JSON format.
 *
 * Example usage:
 * <code>
 *        // create a JSON string from an internal object
 *        ReflectJSON.toJSONString( myObject );
 *
 *        // read a JSON string into an internal object
 *        var myObject:DomainClass = ReflectJSON.fromJSONString( jsonString, DomainClass );
 *    </code>
 */

public class ReflectJSON {

    /**
     * Encodes a object into a JSON string.
     *
     * @param o is a domain object from which JSON string will be created
     * @return JSON string representing o
     * @langversion ActionScript 3.0
     * @playerversion Flash 9.0 and above
     */
    public static function toJSONString(o:Object):String {
        return new ReflectJSONEncoder(o).getString();
    }

    /**
     * Decodes a JSON string into a domain typed object.
     *
     * @param s The JSON string representing the object
     * @param c Domain class to be created
     * @param eType elements type in case we need to get array
     * @return Domain object specified by type of c attribute
     * @throws com.adobe.serialization.json.JSONParseError
     * @langversion ActionScript 3.0
     * @playerversion Flash 9.0 and above
     */
    public static function fromJSONString(s:String, c:Class, eType:Class = null):* {
        return new ReflectJSONDecoder(s, c, eType).getValue();

    }

}
}