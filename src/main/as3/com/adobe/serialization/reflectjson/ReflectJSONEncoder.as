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

import flash.utils.describeType;
import flash.utils.getQualifiedClassName;

public class ReflectJSONEncoder {

    /** The string that is going to represent the object we're encoding */
    private var jsonString:String;

    /**
     * Creates a new ReflectJSONEncoder.
     *
     * @param value The object to encode as a JSON string
     * @langversion ActionScript 3.0
     * @playerversion Flash 9.0
     * @tiptext
     */
    public function ReflectJSONEncoder(value:*) {
        jsonString = convertToString(value);
    }

    /**
     * Gets the JSON string from the encoder.
     *
     * @return The JSON string representation of the object
     *        that was passed to the constructor
     * @langversion ActionScript 3.0
     * @playerversion Flash 9.0
     * @tiptext
     */
    public function getString():String {
        return jsonString;
    }

    /**
     * Converts a value to it's JSON string equivalent.
     *
     * @param value The value to convert.  Could be any
     *        type (object, number, array, etc)
     */
    private function convertToString(value:*):String {
        if (value is String) {
            return escapeString(value as String);
        }
        else if (value is Number) {
            return isFinite(value as Number) ? value.toString() : "null";
        }
        else if (value is Boolean) {
            return value ? "true" : "false";
        }
        else if (value is Array || getQualifiedClassName(value).search(ActionScriptTypes.VECTOR) > -1) {
            return iterableToString(value);
        }
        else if (value is Object && value != null) {
            return objectToString(value);
        }
        return "null";
    }

    /**
     * Escapes a string accoding to the JSON specification.
     *
     * @param str The string to be escaped
     * @return The string with escaped special characters
     *        according to the JSON specification
     */
    private static function escapeString(str:String):String {
        var s:String = "";
        var ch:String;
        var len:Number = str.length;

        for (var i:int = 0; i < len; i++) {

            // examine the character to determine if we have to escape it
            ch = str.charAt(i);
            switch (ch) {

                case '"':	// quotation mark
                    s += "\\\"";
                    break;

                case '\\':	// reverse solidus
                    s += "\\\\";
                    break;

                case '\b':	// bell
                    s += "\\b";
                    break;

                case '\f':	// form feed
                    s += "\\f";
                    break;

                case '\n':	// newline
                    s += "\\n";
                    break;

                case '\r':	// carriage return
                    s += "\\r";
                    break;

                case '\t':	// horizontal tab
                    s += "\\t";
                    break;

                default:	// everything else

                    // check for a control character and escape as unicode
                    if (ch < ' ') {
                        // get the hex digit(s) of the character (either 1 or 2 digits)
                        var hexCode:String = ch.charCodeAt(0).toString(16);

                        // ensure that there are 4 digits by adjusting
                        // the # of zeros accordingly.
                        var zeroPad:String = hexCode.length == 2 ? "00" : "000";

                        // create the unicode escape sequence with 4 hex digits
                        s += "\\u" + zeroPad + hexCode;
                    }
                    else {

                        // no need to do any special encoding, just pass-through
                        s += ch;

                    }
            }	// end switch

        }	// end for loop

        return "\"" + s + "\"";
    }

    /**
     * Converts iterables to it's JSON string equivalent
     *
     * @param value The iterable object to convert
     * @return The JSON string representation of <code>value</code>
     */
    private function iterableToString(value:*):String {
        var s:String = "";

        for (var i:int = 0; i < value.length; i++) {
            if (s.length > 0) {
                s += ","
            }
            s += convertToString(value[i]);
        }

        return "[" + s + "]";
    }

    /**
     * Converts an object to it's JSON string equivalent
     *
     * @param o The object to convert
     * @return The JSON string representation of <code>o</code>
     */
    private function objectToString(o:Object):String {
        var s:String = "";
        var classInfo:XML = describeType(o);

        if (classInfo.@name.toString() == ActionScriptTypes.OBJECT) {
            var value:Object;

            for (var key:String in o) {
                if (o.hasOwnProperty(key)) {
                    value = o[key];

                    if (value is Function) {
                        continue;
                    }

                    if (s.length > 0) {
                        s += ","
                    }

                    s += escapeString(key) + ":" + convertToString(value);
                }
            }
        }
        else {
            for each (var v:XML in classInfo..*.( name() == "variable" || ( name() == "accessor"
                    && attribute("access").charAt(0) == "r" ) )) {

                if (v.metadata && v.metadata.( @name == "Transient" ).length() > 0) {
                    continue;
                }

                var fieldName:String = v.@name.toString();

                if (v.metadata && v.metadata.( @name == MetadataNames.SERIALIZED_NAME ).length() > 0) {
                    fieldName = v.metadata.( @name == MetadataNames.SERIALIZED_NAME ).arg.@value;
                }

                if (s.length > 0) {
                    s += ","
                }

                s += escapeString(fieldName.toString()) + ":" + convertToString(o[ v.@name ]);
            }
        }

        return "{" + s + "}";
    }
}
}