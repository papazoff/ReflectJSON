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

package com.adobe.serialization.reflectjson{
	
	import com.adobe.serialization.json.JSONToken;
	import com.adobe.serialization.json.JSONTokenType;
	import com.adobe.serialization.json.JSONTokenizer;
	
	import flash.utils.describeType;
	import flash.utils.getDefinitionByName;
	import flash.utils.getQualifiedClassName;
	
	import mx.collections.ArrayCollection;
	
	public class ReflectJSONDecoder{
		
		/**
		 * Flag indicating if the parser should be strict about the format
		 * of the JSON string it is attempting to decode.
		 */
		private var strict:Boolean = true;
		
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
		 * @param s The JSON string to be converted
		 *		into a native value object
		 * 
		 * @param c The Class to be created
		 *		a native value object
		 * 
		 * @langversion ActionScript 3.0
		 * @playerversion Flash 9.0
		 * @tiptext
		 */
		public function ReflectJSONDecoder( s:String, output:Class ){
			super();
			
			tokenizer = new JSONTokenizer( s, strict );
			
			nextToken();
			value = parseValue( output );
		}
		
		public function getValue():*{
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
		private final function nextValidToken():JSONToken{
			token = tokenizer.getNextToken();
			checkValidToken();
			
			return token;
		}
		
		/**
		 * Verifies that the token is valid.
		 */
		private final function checkValidToken():void{
			// Catch errors when the input stream ends abruptly
			if ( token == null ){
				tokenizer.parseError( "Unexpected end of input" );
			}
		}
		
		/**
		 * Attempt to parse an object.
		 */
		private function parseObject(expectedType:String, description:XML):*{
			// create the object internally that we're going to
			// attempt to parse from the tokenizer
			var o:Object;
			
			try{
				var expectedClass:Class = Class(getDefinitionByName(expectedType));
				o = new expectedClass();
			}
			catch(e:ReferenceError){
				tokenizer.parseError("Unregistered class name " + expectedType + ". " +
					"Use registerClassAlias(' + expectedType + ', Class) method to register your class aliases " + e.getStackTrace());
			}
			
			var expectedFieldsListIfBindable:XMLList = description.factory.accessor as XMLList;
			var expectedFieldsList:XMLList = description.factory.variable as XMLList;
			
			if(expectedFieldsList.length() > 0){
				for each(var child:XML in expectedFieldsListIfBindable){
					expectedFieldsList.appendChild(child);
				}
			}
			else{
				expectedFieldsList = expectedFieldsListIfBindable;
			}
			
			if(expectedFieldsList.length() <= 0){
				tokenizer.parseError(" Expected output object should contain fields ");
			}
			
			// store the string part of an object member so
			// that we can assign it a value in the object
			var key:String
			
			// grab the next token from the tokenizer
			nextValidToken();
			
			// check to see if we have an empty object
			if ( token.type == JSONTokenType.RIGHT_BRACE ) {
				// throw an exception if we unexpect empty object
				if(expectedFieldsList.length() > 0){
					tokenizer.parseError(" Unexpected empty object ");
				}
				// we're done reading the object, so return it
				return o;
			}
			
			var expectedFields:Array = extractFieldsFromDescription(expectedFieldsList);
			
			var currentField:Object;
			
			// deal with members of the object, and use an "infinite"
			// loop because we could have any amount of members
			while ( true ) {
				if ( token.type == JSONTokenType.STRING ) {
					// the string value we read is the key for the object
					
					if(!isFieldPresentInExpectedObject(token.value.toString(), expectedFields)){
						tokenizer.parseError( " JSON object contain unexpected field : " + key );
					}
					
					currentField = getFieldByKey(token.value.toString(), expectedFields);
					key = String( currentField.name );
					
					// move past the string to see what's next
					nextValidToken();
					
					// after the string there should be a :
					if ( token.type == JSONTokenType.COLON ) {
						
						// move past the : and read/assign a value for the key
						nextToken();
						
						var fieldType:String = currentField.type;
						
						//if current field is Array type we should pass elements type argument to parseValue method.
						
						var valueClass:Class = Class(getDefinitionByName(fieldType));
						
						if(fieldType == getQualifiedClassName(ArrayCollection)){
							o[key] = new ArrayCollection(parseValue(valueClass, currentField.elementsType) as Array);
						}
						else{
							o[key] = parseValue(valueClass, currentField.elementsType);	
						}	
						
						// move past the value to see what's next
						nextValidToken();
						
						// after the value there's either a } or a ,
						if ( token.type == JSONTokenType.RIGHT_BRACE ) {
							// // we're done reading the object, so return it
							return o;
							
						} else if ( token.type == JSONTokenType.COMMA ) {
							// skip past the comma and read another member
							nextToken();
						} else {
							tokenizer.parseError( "Expecting } or , but found " + token.value );
						}
					} else {
						tokenizer.parseError( "Expecting : but found " + token.value );
					}
				
				} else {
					tokenizer.parseError( "Expecting string but found " + token.value );
				}
			}
			return null;
		}
		
		/**
		 * Attempt to parse an array.
		 */
		private function parseArray(elementsType:String = null):Array{
			// create an array internally that we're going to attempt
			// to parse from the tokenizer
			var a:Array = new Array();
			
			// grab the next valid token from the tokenizer to move
			// past the opening [
			nextValidToken();
			
			// check to see if we have an empty array
			if ( token.type == JSONTokenType.RIGHT_BRACKET ) {
				// we're done reading the array, so return it
				return a;
			}
			
			// deal with elements of the array, and use an "infinite"
			// loop because we could have any amount of elements
			while ( true ) {
				// read in the value and add it to the array
				try{
					a.push ( parseValue( Class( getDefinitionByName(elementsType) )));
				}
				catch(e:ReferenceError){
					tokenizer.parseError(" Unregistered class alias " + elementsType + ". " +
						"Use registerClassAlias('" + elementsType + "', Class) method to register your class aliases " + e.getStackTrace());
				}
				
				// after the value there should be a ] or a ,
				nextValidToken();
				
				if ( token.type == JSONTokenType.RIGHT_BRACKET ) {
					// we're done reading the array, so return it
					return a;
				} else if ( token.type == JSONTokenType.COMMA ) {
					// move past the comma and read another value
					nextToken();
				} else {
					tokenizer.parseError( "Expecting ] or , but found " + token.value );
				}
			}
			return null;
		}
		
		/**
		 * Attempt to parse a value
		 */
		private function parseValue( expectedObject : Class, elementsType:String = null):Object{
			// Catch errors when the input stream ends abruptly
			if ( token == null ){
				tokenizer.parseError( "Unexpected end of input" );
			}
			
			// Gets the xml description of an expected object type
			var description:XML = describeType(expectedObject);
			
			// Gets actual expected object type
			var expectedType:String = description.@name;
			
			// Gets expected object type base types
			var expectedTypeBases:Array = [];
			for(var t:int = 0; t < description.extendsClass.length(); t++){
				expectedTypeBases.push(description.extendsClass[t].@type);
			}
			
			switch ( token.type ) {
				case JSONTokenType.LEFT_BRACE:
					if(!isExpectedType(ActionScriptTypes.OBJECT, expectedType, expectedTypeBases)){
						tokenizer.parseError(" Unexpected type parsed from JSON ");
					}
					return parseObject(expectedType, description);
				case JSONTokenType.LEFT_BRACKET:
					if(!isExpectedType(ActionScriptTypes.ARRAY, expectedType, 
						(expectedType == ActionScriptTypes.ARRAY_COLLECTION || expectedType.search(ActionScriptTypes.VECTOR) > -1) ? 
								expectedTypeBases.concat(ActionScriptTypes.ARRAY) : expectedTypeBases)){
						tokenizer.parseError(" Unexpected type parsed from JSON ");
					}
					return parseArray(elementsType);
				case JSONTokenType.STRING:
					if(!isExpectedType(ActionScriptTypes.STRING, expectedType, expectedTypeBases)){
						tokenizer.parseError(" Unexpected type parsed from JSON ");
					}
					return token.value;
				case JSONTokenType.NUMBER:
					if(!isExpectedType(ActionScriptTypes.NUMBER, expectedType, 
						(expectedType == ActionScriptTypes.INT || expectedType == ActionScriptTypes.UINT) ? 
								expectedTypeBases.concat(ActionScriptTypes.NUMBER) : expectedTypeBases)){
						tokenizer.parseError(" Unexpected type parsed from JSON ");
					}
					return token.value;
				case JSONTokenType.TRUE:
				case JSONTokenType.FALSE:
					if(!isExpectedType(ActionScriptTypes.BOOLEAN, expectedType, expectedTypeBases)){
						tokenizer.parseError(" Unexpected type parsed from JSON ");
					}
					return token.value;
				case JSONTokenType.NULL:
					if(!isExpectedType(ActionScriptTypes.NULL, expectedType, expectedTypeBases)){
						tokenizer.parseError(" Unexpected type parsed from JSON ");
					}
					return token.value;
				case JSONTokenType.NAN:
				default:
					tokenizer.parseError( "Unexpected " + token.value );
			}
			return null;
		}
		
		/**
		 * Check if current token is an expected type for appropriate field
		 */
		
		private function isExpectedType(parsedJSONType:String, expectedType:String, expectedTypeBases:Array):Boolean{
			var result:Boolean = false;
			if(parsedJSONType != expectedType){
				for(var i:int = 0; i<expectedTypeBases.length; i++){
					if(expectedTypeBases[i] == parsedJSONType){
						result = true;
						break;
					}
				}
			}
			else {
				result = true;
			}
			return result;
		}
		
		/**
		 * Retrieves all fields from created entity description
		 */
		
		private function extractFieldsFromDescription(list:XMLList):Array{
			var result:Array = new Array();
			
			for(var i:int = 0; i<list.length(); i++){
				var fieldDescription:XML = list[i] as XML;
				var fieldName:String = fieldDescription.@name;
				var fieldType:String = fieldDescription.@type;
				var collectionElementsType:String; // if field is an Array or ArrayCollection
				var metadataJSONFieldName:String; 
				
				var fieldMetadata:XMLList = fieldDescription.metadata;
				
				for(var j:int = 0; j<fieldMetadata.length(); j++){
					var metadataItem:XML = fieldMetadata[j] as XML;
					if(metadataItem.@name == MetadataNames.JSON_FIELD_METADATA){
						metadataJSONFieldName = metadataItem.arg.(@key="name").@value;
					}
					if(metadataItem.@name == MetadataNames.ELEMENTS_METADATA){
						collectionElementsType = metadataItem.arg.(@key="type").@value;
					}
				}
				
				result.push({name:fieldName, jsonFieldName:metadataJSONFieldName, type:fieldType, elementsType:collectionElementsType});
			}
			
			return result;
		}
		
		/**
		 * Checks field presence in created entity by name
		 */
		
		private function isFieldPresentInExpectedObject(key:String, fields:Array):Boolean{
			return getFieldByKey(key, fields) != null;
		}
		
		/**
		 * Retrieves field type in created entity by key
		 */
		
		private function getExpectedTypeByKey(key:String, fields:Array):String{
			return getFieldByKey(key, fields)["type"];
		}
		
		/**
		 *  Retrieves field in created entity by key
		 *	@key String
		 * 	@fields Array
		 * 	@return Object
		 */
		private function getFieldByKey(key:String, fields:Array):Object{
			for(var i:int = 0; i< fields.length; i++){
				var field:Object = fields[i];
				if(field.name == key || field.jsonFieldName == key){
					return field;
				}
			}
			return null;
		}
	}
}