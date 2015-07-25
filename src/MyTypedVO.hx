package;

import VO;

class MyTypedVO extends VO
{
	
	public var spriteFilename: String;
    public var frameName: String;
    public var counter:Int = 0;

	public function new(obj : Dynamic = null)
    {
        super(obj);
    }
}