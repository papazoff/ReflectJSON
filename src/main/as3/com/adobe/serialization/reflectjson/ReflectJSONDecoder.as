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

import com.adobe.serialization.json.JSONToken;
import com.adobe.serialization.json.JSONTokenType;
import com.adobe.serialization.json.JSONTokenizer;

import flash.utils.describeType;
import flash.utils.getDefinitionByName;

internal class ReflectJSONDecoder {

    /** The value that will get parsed from the JSON string */
    private var value:*;

    /** The tokenizer designated to read the JSON string */
    private var tokenizer:JSONTokenizer;

    /** The current token from the tokenizer */
    private var token:JSONToken;

    /**
     * Constructs a new ActionJSONDecoder to parse a JSON string
     * into a native value object.
     *
     * @param s The JSON string to be converted into a native value object
     * @param output The Class to be created as a parsing result
     * @param elementsType - class that represents elements type in case if we need an Array in the result.
     * @langversion ActionScript 3.0
     * @playerversion Flash 9.0
     * @tiptext
     */
    public function ReflectJSONDecoder(s:String, output:Class, elementsType:Class = null) {
        super();

        tokenizer = new JSONTokenizer(s, true);
        nextToken();
        value = parseValue(output, elementsType);
    }

    public function getValue():* {
        return value;
    }

    /**
     * Returns the next token from the tokenzier reading
     * the JSON string
     */
    private function nextToken():JSONToken {
        return token = tokenizer.getNextToken();
    }

    /**
     * Returns the next token from the tokenizer reading
     * the JSON string and verifies that the token is valid.
     */
    private final function nextValidToken():JSONToken {
        token = tokenizer.getNextToken();
        checkValidToken();

        return token;
    }

    /**
     * Verifies that the token is valid.
     */
    private final function checkValidToken():void {
        // Catch errors when the input stream ends abruptly
        if (token == null) {
            tokenizer.parseError("Unexpected end of input");
        }
    }

    /**
     * Attempt to parse an object.
     */
    private function parseObject(expectedObject:Class, description:XML):* {
        // create the object internally that we're going to
        // attempt to parse from the tokenizer
        var o:Object = new expectedObject();

//        try {
////            var expectedClass:Class = Class(getDefinitionByName(expectedType));
//            o = new expectedObject();
//        }
//        catch (e:ReferenceError) {
//            tokenizer.parseError("Unregistered class name " + expectedObject + ". " +
//                    "Use registerClassAlias(' + expectedType + ', Class) method to register your class aliases " + e.getStackTrace());
//        }

        var expectedFieldsList:XMLList = description..*.(name() == "variable" || (name() == "accessor" &&
                (String(attribute("access")).search("write") > -1)));

        if (expectedFieldsList.length() <= 0) {
            tokenizer.parseError(" Expected output object should contain fields ");
        }

        // store the string part of an object member so
        // that we can assign it a value in the object
        var key:String;

        // grab the next token from the tokenizer
        nextValidToken();

        // check to see if we have an empty object
        if (token.type == JSONTokenType.RIGHT_BRACE) {
            // throw an exception if we unexpect empty object
            if (expectedFieldsList.length() > 0) {
                tokenizer.parseError(" Unexpected empty object ");
            }
            // we're done reading the object, so return it
            return o;
        }

        var expectedFields:Array = extractFieldsFromDescription(expectedFieldsList);

        var currentField:Object;

        // deal with members of the object, and use an "infinite"
        // loop because we could have any amount of members
        while (true) {
            if (token.type == JSONTokenType.STRING) {
                // the string value we read is the key for the object

                if (!isFieldPresentInExpectedObject(token.value.toString(), expectedFields)) {
                    tokenizer.parseError(" JSON object contain unexpected field : " + key);
                }

                currentField = getFieldByKey(token.value.toString(), expectedFields);

                key = String(currentField.name);

                // move past the string to see what's next
                nextValidToken();

                // after the string there should be a :
                if (token.type == JSONTokenType.COLON) {

                    // move past the : and read/assign a value for the key
                    nextToken();

                    var fieldType:String = currentField.type;
                    var valueClass:Class = Class(getDefinitionByName(fieldType));

                    //if current field is Array type we should pass elements type argument to parseValue method.
                    if (fieldType == "Array") {
                        o[key] = parseValue(valueClass, Class(getDefinitionByName(currentField.elementsType))) as Array;
                    }
                    else {
                        o[key] = parseValue(valueClass);
                    }

                    // move past the value to see what's next
                    nextValidToken();

                    // after the value there's either a } or a ,
                    if (token.type == JSONTokenType.RIGHT_BRACE) {
                        // // we're done reading the object, so return it
                        return o;

                    }
                    else if (token.type == JSONTokenType.COMMA) {
                        // skip past the comma and read another member
                        nextToken();
                    }
                    else {
                        tokenizer.parseError("Expecting } or , but found " + token.value);
                    }
                }
                else {
                    tokenizer.parseError("Expecting : but found " + token.value);
                }

            }
            else {
                tokenizer.parseError("Expecting string but found " + token.value);
            }
        }
        return null;
    }

    /**
     * Attempt to parse an array.
     */
    private function parseArray(elementsType:Class = null):Array {
        // create an array internally that we're going to attempt
        // to parse from the tokenizer
        var a:Array = [];

        // grab the next valid token from the tokenizer to move
        // past the opening [
        nextValidToken();

        // check to see if we have an empty array
        if (token.type == JSONTokenType.RIGHT_BRACKET) {
            // we're done reading the array, so return it
            return a;
        }

        // deal with elements of the array, and use an "infinite"
        // loop because we could have any amount of elements
        while (true) {
            // read in the value and add it to the array
            try {
                a.push(parseValue(elementsType));
            }
            catch (e:ReferenceError) {
                tokenizer.parseError(" Unregistered class alias " + elementsType + ". " +
                        "Use registerClassAlias('" + elementsType + "', Class) method to register your class aliases " + e.getStackTrace());
            }

            // after the value there should be a ] or a ,
            nextValidToken();

            if (token.type == JSONTokenType.RIGHT_BRACKET) {
                // we're done reading the array, so return it
                return a;
            }
            else if (token.type == JSONTokenType.COMMA) {
                // move past the comma and read another value
                nextToken();
            }
            else {
                tokenizer.parseError("Expecting ] or , but found " + token.value);
            }
        }
        return null;
    }

    /**
     * Attempt to parse a value
     */
    private function parseValue(expectedObject:Class, elementsType:Class = null):Object {
        checkValidToken();

        // Gets the xml description of an expected object type
        var description:XML = describeType(expectedObject);

        // Gets actual expected object type
        var expectedType:String = description.@name;

        // Gets expected object type base types
        var expectedTypeBases:Array = [];
        for (var i:int = 0; i < description.extendsClass.length(); i++) {
            expectedTypeBases.push(description.extendsClass[i].@type);
        }

        switch (token.type) {
            case JSONTokenType.LEFT_BRACE:
                if (!isExpectedType(ActionScriptTypes.OBJECT, expectedType, expectedTypeBases)) {
                    tokenizer.parseError(" Unexpected type parsed from JSON ");
                }
                return parseObject(expectedObject, description);
            case JSONTokenType.LEFT_BRACKET:
                if (!isExpectedType(ActionScriptTypes.ARRAY, expectedType,
                        (expectedType == ActionScriptTypes.VECTOR ?
                                expectedTypeBases.concat([ActionScriptTypes.ARRAY]) : expectedTypeBases))) {
                    tokenizer.parseError(" Unexpected type parsed from JSON ");
                }
                return parseArray(elementsType);
            case JSONTokenType.STRING:
                if (!isExpectedType(ActionScriptTypes.STRING, expectedType, expectedTypeBases)) {
                    tokenizer.parseError(" Unexpected type parsed from JSON ");
                }
                return token.value;
            case JSONTokenType.NUMBER:
                if (!isExpectedType(ActionScriptTypes.NUMBER, expectedType,
                        (expectedType == ActionScriptTypes.INT || expectedType == ActionScriptTypes.UINT) ?
                                expectedTypeBases.concat(ActionScriptTypes.NUMBER) : expectedTypeBases)) {
                    tokenizer.parseError(" Unexpected type parsed from JSON ");
                }
                return token.value;
            case JSONTokenType.TRUE:
            case JSONTokenType.FALSE:
                if (!isExpectedType(ActionScriptTypes.BOOLEAN, expectedType, expectedTypeBases)) {
                    tokenizer.parseError(" Unexpected type parsed from JSON ");
                }
                return token.value;
            case JSONTokenType.NULL:
                if (!isExpectedType(ActionScriptTypes.NULL, expectedType, expectedTypeBases)) {
                    tokenizer.parseError(" Unexpected type parsed from JSON ");
                }
                return token.value;
            case JSONTokenType.NAN:
            default:
                tokenizer.parseError("Unexpected " + token.value);
        }
        return null;
    }

    /**
     * Checks if current token is an expected type for appropriate field
     */
    private static function isExpectedType(parsedJSONType:String, expectedType:String, expectedTypeBases:Array):Boolean {
        if (parsedJSONType == expectedType) {
            return true;
        }

        for (var i:int = 0; i < expectedTypeBases.length; i++) {
            if (expectedTypeBases[i] == parsedJSONType) {
                return true;
            }
        }

        return false;
    }

    /**
     * Retrieves all fields from created entity description
     */
    private static function extractFieldsFromDescription(list:XMLList):Array {
        var result:Array = [];

        for (var i:int = 0; i < list.length(); i++) {
            var fieldDescription:XML = list[i] as XML;
            var fieldName:String = fieldDescription.@name;
            var fieldType:String = fieldDescription.@type;
            var serializedName:String;
            var collectionElementType:String;

            var fieldMetadata:XMLList = fieldDescription.metadata;

            for (var j:int = 0; j < fieldMetadata.length(); j++) {
                var metadataItem:XML = fieldMetadata[j] as XML;
                if (metadataItem.@name == MetadataNames.SERIALIZED_NAME) {
                    serializedName = metadataItem.arg.@value;
                }
                if (metadataItem.@name == MetadataNames.ELEMENTS_TYPE) {
                    collectionElementType = metadataItem.arg.@value;
                }
            }

            result.push({name: fieldName, jsonFieldName: serializedName, type: fieldType, elementsType: collectionElementType});
        }

        return result;
    }

    /**
     * Checks field presence in created entity by name
     */
    private static function isFieldPresentInExpectedObject(key:String, fields:Array):Boolean {
        return getFieldByKey(key, fields) != null;
    }

    /**
     *  Retrieves field in created entity by key
     *  @key String
     *  @fields Array
     *  @return Object
     */
    private static function getFieldByKey(key:String, fields:Array):Object {
        for (var i:int = 0; i < fields.length; i++) {
            var field:Object = fields[i];
            if (field.name == key || field.jsonFieldName == key) {
                return field;
            }
        }
        return null;
    }
}
}