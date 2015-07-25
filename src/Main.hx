package;

import MyTypedVO;

class Main
{
	
	static function main() {
		var myVo:MyTypedVO = new MyTypedVO({ counter: 1, frameName: "hello_world"});

		trace( myVo );
		trace( myVo.frameName);
		trace( myVo.counter );
		myVo.counter += 10;
		trace( myVo.counter );
	}
}