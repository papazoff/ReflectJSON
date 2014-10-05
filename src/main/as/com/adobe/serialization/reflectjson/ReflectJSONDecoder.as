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

public class ReflectJSONDecoder {

    /** The value that will get parsed from the JSON string */
    private var _value:*;

    /** The tokenizer designated to read the JSON string */
    private var _tokenizer:JSONTokenizer;

    /** The current token from the tokenizer */
    private var _token:JSONToken;

    /**
     * Designates whether to skip or throw an exception when
     * unexpected field has been found during parsing json string
     */
    private var _skipUnexpectedFields:Boolean = false;

    /**
     * Constructs a new ReflectJSONDecoder to parse provided JSON string into a domain object.
     *
     * @param s JSON string to be converted into a domain object
     * @param output expected domain object
     * @param elementsType - class that represents elements type in case if we need a collection as a result.
     * @param skipUnexpectedFields - skipUnexpectedFields - flag that designates whether to skip or not all
     * unexpected fields which have been found during json string parsing
     * @langversion ActionScript 3.0
     * @playerversion Flash 9.0
     * @tiptext
     */
    public function ReflectJSONDecoder(s:String, output:Class, elementsType:Class = null, skipUnexpectedFields:Boolean = false) {
        super();

        _skipUnexpectedFields = skipUnexpectedFields;
        _tokenizer = new JSONTokenizer(s, true);
        nextToken();
        _value = parseValue(output, elementsType);
    }

    public function getValue():* {
        return _value;
    }

    /**
     * Returns the next token from the tokenizer reading
     * the JSON string
     */
    private function nextToken():JSONToken {
        return _token = _tokenizer.getNextToken();
    }

    /**
     * Returns the next token from the tokenizer reading
     * the JSON string and verifies that the token is valid.
     */
    private final function nextValidToken():JSONToken {
        _token = _tokenizer.getNextToken();
        checkValidToken();

        return _token;
    }

    /**
     * Verifies that the token is valid.
     */
    private final function checkValidToken():void {
        // Catch errors when the input stream ends abruptly
        if (_token == null) {
            _tokenizer.parseError("Unexpected end of input");
        }
    }

    /**
     * Attempt to parse an object.
     */
    private function parseObject(expectedObject:Class, description:XML):* {
        var o:Object = new expectedObject();

        var expectedFieldsList:XMLList = description..*.(name() == "variable" || (name() == "accessor" &&
                (String(attribute("access")).search("write") > -1)));

        if (expectedFieldsList.length() <= 0) {
            _tokenizer.parseError(" Expected output object should contain fields ");
        }

        var key:String;

        nextValidToken();

        if (_token.type == JSONTokenType.RIGHT_BRACE) {
            if (expectedFieldsList.length() > 0) {
                _tokenizer.parseError(" Unexpected empty object ");
            }
            // we're done reading the object, so return it
            return o;
        }

        var expectedFields:Array = extractFieldsFromDescription(expectedFieldsList);
        var currentField:Object;

        // deal with members of the object, and use an "infinite"
        // loop because we could have any amount of members
        while (true) {
            if (_token.type == JSONTokenType.STRING) {
                // the string value we read is the key for the object

                var tokenValue:String = _token.value.toString();

                if (!isFieldPresentInExpectedObject(tokenValue, expectedFields)) {
                    if (!_skipUnexpectedFields) {
                        _tokenizer.parseError(" JSON object contain unexpected field : " + tokenValue);
                    }

                    nextValidToken();
                    nextToken();
                    nextValidToken();

                    if (_token.type == JSONTokenType.RIGHT_BRACE) {
                        // we're done reading the object, so return it
                        return o;
                    }
                    else if (_token.type == JSONTokenType.COMMA) {
                        // skip past the comma and read another member
                        nextToken();
                    }
                    else {
                        _tokenizer.parseError("Expecting } or , but found " + _token.value);
                    }

                    continue;
                }

                currentField = getFieldByKey(tokenValue, expectedFields);
                key = String(currentField.name);

                nextValidToken();

                if (_token.type == JSONTokenType.COLON) {

                    nextToken();

                    var fieldType:String = currentField.type;
                    var valueClass:Class = Class(getDefinitionByName(fieldType));

                    //if current field is any collection type, we should pass elements type argument to parseValue method.
                    if (fieldType == ActionScriptTypes.ARRAY || fieldType.search(ActionScriptTypes.VECTOR) > -1) {
                        o[key] = parseValue(valueClass, Class(getDefinitionByName(currentField.elementsType)));
                    }
                    else {
                        o[key] = parseValue(valueClass);
                    }

                    nextValidToken();

                    if (_token.type == JSONTokenType.RIGHT_BRACE) {
                        // we're done reading the object, so return it
                        return o;
                    }
                    else if (_token.type == JSONTokenType.COMMA) {
                        // skip past the comma and read another member
                        nextToken();
                    }
                    else {
                        _tokenizer.parseError("Expecting } or , but found " + _token.value);
                    }
                }
                else {
                    _tokenizer.parseError("Expecting : but found " + _token.value);
                }
            }
            else {
                _tokenizer.parseError("Expecting string but found " + _token.value);
            }
        }
        return null;
    }

    /**
     * Attempt to parse an array.
     */
    private function parseArray(elementsType:Class = null):Array {
        var a:Array = [];

        // grab the next valid token from the tokenizer to move
        // past the opening [
        nextValidToken();

        if (_token.type == JSONTokenType.RIGHT_BRACKET) {
            // we're done reading the array, so return it
            return a;
        }

        while (true) {
            try {
                a.push(parseValue(elementsType));
            }
            catch (e:ReferenceError) {
                _tokenizer.parseError(" Unregistered class alias " + elementsType + ". " +
                        "Use registerClassAlias('" + elementsType + "', Class) method to register your class aliases " + e.getStackTrace());
            }

            nextValidToken();

            if (_token.type == JSONTokenType.RIGHT_BRACKET) {
                // we're done reading the array, so return it
                return a;
            }
            else if (_token.type == JSONTokenType.COMMA) {
                // move past the comma and read another value
                nextToken();
            }
            else {
                _tokenizer.parseError("Expecting ] or , but found " + _token.value);
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

        switch (_token.type) {
            case JSONTokenType.LEFT_BRACE:
                if (!isExpectedType(ActionScriptTypes.OBJECT, expectedType, expectedTypeBases)) {
                    _tokenizer.parseError(" Unexpected type parsed from JSON ");
                }
                return parseObject(expectedObject, description);
            case JSONTokenType.LEFT_BRACKET:
                if (!isExpectedType(ActionScriptTypes.ARRAY, expectedType,
                        (expectedType.search(ActionScriptTypes.VECTOR) > -1 ?
                                expectedTypeBases.concat([ActionScriptTypes.ARRAY]) : expectedTypeBases))) {
                    _tokenizer.parseError(" Unexpected type parsed from JSON ");
                }

                var result:Array = parseArray(elementsType);
                return expectedType.search(ActionScriptTypes.VECTOR) > -1 ? Vector.<Object>(result) : result;
            case JSONTokenType.STRING:
                if (!isExpectedType(ActionScriptTypes.STRING, expectedType, expectedTypeBases)) {
                    _tokenizer.parseError(" Unexpected type parsed from JSON ");
                }
                return _token.value;
            case JSONTokenType.NUMBER:
                if (!isExpectedType(ActionScriptTypes.NUMBER, expectedType,
                        (expectedType == ActionScriptTypes.INT || expectedType == ActionScriptTypes.UINT) ?
                                expectedTypeBases.concat([ActionScriptTypes.NUMBER]) : expectedTypeBases)) {
                    _tokenizer.parseError(" Unexpected type parsed from JSON ");
                }
                return _token.value;
            case JSONTokenType.TRUE:
            case JSONTokenType.FALSE:
                if (!isExpectedType(ActionScriptTypes.BOOLEAN, expectedType, expectedTypeBases)) {
                    _tokenizer.parseError(" Unexpected type parsed from JSON ");
                }
                return _token.value;
            case JSONTokenType.NULL:
                if (!isExpectedType(ActionScriptTypes.NULL, expectedType, expectedTypeBases)) {
                    _tokenizer.parseError(" Unexpected type parsed from JSON ");
                }
                return _token.value;
            case JSONTokenType.NAN:
            default:
                _tokenizer.parseError("Unexpected " + _token.value);
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