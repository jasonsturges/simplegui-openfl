/**
 *
 *	uk.co.soulwire.gui.SimpleGUI
 *
 *	@version 1.00 | Jan 13, 2011
 *	@author Justin Windle
 *
 *	SimpleGUI is a single Class utility designed for AS3 projects where a developer needs to
 *	quickly add UI controls for variables or functions to a sketch. Properties can be controlled
 *	with just one line of code using a variety of components from the fantastic Minimal Comps set
 *	by Keith Peters, as well as custom components written for SimpleGUI such as the FileChooser
 *
 *	Credit to Keith Peters for creating Minimal Comps which this class uses
 *	http://www.minimalcomps.com/
 *	http://www.bit-101.com/
 *
 **/

package simplegui;

import minimalcomps.components.HRangeSlider;
import minimalcomps.components.Label;


class HUIRangeSlider extends HRangeSlider {

    private var _label:Label = new Label();
    private var _offset:Float = 0.0;

    override private function addChildren():Void {
        super.addChildren();
        _label.y = -5;
        addChild(_label);
    }

    override public function draw():Void {
        _offset = x = _label.width + 5;
        _width = Math.min(200 - _offset, 200);
        _label.x = -_offset;

        super.draw();
    }

    public var label(get, set):String;

    public function get_label():String {
        return _label.text;
    }

    public function set_label(value:String):String {
        _label.text = value;
        _label.draw();

        return _label.text;
    }
}

