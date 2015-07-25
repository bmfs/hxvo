package ;

import haxe.Constraints.IMap;
import haxe.ds.StringMap;
import haxe.Json;

import haxe.rtti.CType;

/**
 * ...
 * @author Bruno Santos
 */

@:rtti

class VO
{
	private static var classCache:Map<String, Map<String,VOTypes>> = new Map<String, Map<String,VOTypes>>();
	
	public function new(obj:Dynamic)
	{
		setValues(obj);
	}
	
	function handleSpecialTypes(key:String, obj:Dynamic):Bool
	{
		return false;
	}

	function hasField(fieldToFind:String):Bool
	{
		var fields:Array<String> = Type.getInstanceFields(Type.getClass(this));
		for (field in fields)
			if (field == fieldToFind) return true;

		return false;
	}
	 
	function setValues(obj:Dynamic):Void
	{
		var classObj = Type.getClass(this);
		var className:String = Type.getClassName(classObj);
		loadFieldInfo(true, className, classObj);
		
		for (field in Reflect.fields(obj)) {
			
				
			if (handleSpecialTypes(field, obj)) {
				
			} else  if (classHasField(className,field)) {
				
				var voType:VOTypes = getDeclaredTypeOfField(className, field);
				var fieldObject:Dynamic = _parse(voType, Reflect.getProperty(obj, field));
				Reflect.setProperty(this, field, fieldObject);
				
			} else {
				//trace(className + " doesn't have field " + field);
			}
			//Reflect.setField(button, n, Reflect.field(properties, n));
		}
	}
	
	function _parse ( type:VOTypes, v:Dynamic):Dynamic {
		switch(type) {
			case VOTypes.VT_Native: return v;
			case VOTypes.VT_Array(valueType): {
				var vClass:Class<Dynamic> = resolveVOType(valueType);
				return _parseArray(vClass, valueType, v);
			}
			
			case VOTypes.VT_Class(name): {
				return _parseClass(name, v);
			}
			default: {
				return null;
			}
		}
	}
	
	function _parseClass(name:String, v:Dynamic):Dynamic
	{
		return Type.createInstance(Type.resolveClass(name), [ v ]);
	}
	
	function resolveVOType(type:VOTypes):Class<Dynamic> {
		switch(type) {
			case VOTypes.VT_Native(name), VOTypes.VT_Class(name): {
				var resuClass:Class<Dynamic> = Type.resolveClass(name);
				return resuClass;
			}
			default: return null;
		}
		return null;
	}
	
	function _parseArray<T>(valueClass:T, valueType:VOTypes,  v:Dynamic):Array<T>
	{
		var result:Array<T> = new Array<T>();
		var arr:Array<Dynamic> = v;
		untyped {
			for( ii in 0...arr.length ) {
				result.push(_parse(valueType, arr[ii]));
			}
		}
		return result;
	}
	
	function parseRTTIFields(type:CType):VOTypes
	{
		switch(type) {
			case CAbstract(name, params), CClass(name, params):
				return parseFieldType(name, params);
			default: {}
		}
		return VT_Unknown;
	}
	
	
	function parseFieldType(name:String, params:List<CType>):VOTypes
	{
		switch(name) {
			case "String", "Int", "Float", "Bool", "Date": return VOTypes.VT_Native(name);

			case "Array": {
				var firstField:VOTypes = parseRTTIFields(params.pop());
				if (firstField != null)
					return VOTypes.VT_Array(firstField);
			}
			default: {
				//trace(name);
			}
		}
		return VOTypes.VT_Class(name);
	}
	
	function loadFieldInfo(rootCall:Bool = false, className:String, classObj:Class<Dynamic>):Void
	{
		if (rootCall && classCache.exists(className)) {
			return;
		}
		
		var rtti = haxe.rtti.Rtti.getRtti(classObj);
		for (field in rtti.fields)
		{
			if (field.isPublic) {
				switch (field.type) {
					case CAbstract(name, params), CClass(name, params):
						addFieldDeclaration(className, field.name , parseFieldType(name, params));
					default: {}
				}
			}
		}
		
		if (rtti.superClass != null) {
			loadFieldInfo(false, className, Type.resolveClass(rtti.superClass.path));
		}
	}
	
	public static function addFieldDeclaration(className:String, fieldName:String, fieldType:VOTypes)
	{
		if (!classCache.exists(className)) {
			classCache.set(className, new Map<String,VOTypes>());
		}
		classCache.get(className).set(fieldName, fieldType);
	}
	
	public static function classHasField(className:String, fieldName:String):Bool
	{
		if (classCache.exists(className)) {
			var tmpList:Map<String,VOTypes> = classCache.get(className);
			if (tmpList.exists(fieldName)) {
				return true;
			}
		}
		return false;
	}
	
	public function getDeclaredTypeOfField(className:String, field:String):VOTypes
	{
		if (classCache.exists(className)) {
			var tmpList:Map<String,VOTypes> = classCache.get(className);
			if (tmpList.exists(field)) {
				return tmpList.get(field);
			}
		}
		
		return VOTypes.VT_Unknown;
	}
	
	public var DEBUG(get, never) : Bool;
	function get_DEBUG() : Bool {
		return true;
    }
	
	
}

enum VOTypes {
		VT_Native(name:String);
		VT_Class(name:String);
		VT_Map(key:VOTypes, value:VOTypes);
		VT_Array(value:VOTypes);
		VT_Unknown;
	}