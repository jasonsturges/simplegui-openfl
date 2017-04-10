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

import minimalcomps.components.Component;
import minimalcomps.components.InputText;
import minimalcomps.components.Label;
import minimalcomps.components.PushButton;
import openfl.events.Event;
import openfl.events.MouseEvent;
import openfl.net.FileFilter;
import openfl.net.FileReference;


class FileChooser extends Component {
    public var filter:Array<FileFilter> = [];
    public var onComplete:Dynamic;

    private var _label:Label = new Label();
    private var _file:FileReference;
    private var _filePath:InputText = new InputText();
    private var _button:PushButton = new PushButton();

    override private function addChildren():Void {
        super.addChildren();

        _button.x = 125;
        _button.width = 75;
        _button.label = "Browse";
        _button.addEventListener(MouseEvent.CLICK, onButtonClicked);

        _filePath.enabled = false;
        _filePath.width = 120;
        _filePath.height = _button.height;

        _button.y = _filePath.y = 20;

        addChild(_filePath);
        addChild(_button);
        addChild(_label);
    }

    private function onButtonClicked(event:MouseEvent):Void {
        if (_file != null)
            _file.browse(filter);
    }

    private function onFileSelected(event:Event):Void {
        _filePath.text = _file.name;
        _file.addEventListener(Event.COMPLETE, onFileComplete);
        _file.load();
    }

    private function onFileComplete(event:Event):Void {
        if (onComplete != null)
            onComplete();
    }

    /**
     *  width
     */
    #if flash @:setter(width) #end
    override public function set_width(w:Float): #if flash Void #else Float #end {
        super.width = w;
        _button.x = w - _button.width;
        _filePath.width = w - _button.width - 5;

        return super.width;
    }

    /**
     *  label
     */
    public var label(get, set):String;

    public function get_label():String {
        return _label.text;
    }

    public function set_label(value:String):String {
        _label.text = value;

        return _label.text;
    }

    /**
     *  file
     */
    public var file(get, set):FileReference;

    public function get_file():FileReference {
        return _file;
    }

    public function set_file(value:FileReference):FileReference {
        if (_file != null) {
            _file.removeEventListener(Event.SELECT, onFileSelected);
        }

        _file = value;
        _file.addEventListener(Event.SELECT, onFileSelected);

        if (_file.data != null) {
            _filePath.text = _file.name;
        }

        return _file;
    }
}