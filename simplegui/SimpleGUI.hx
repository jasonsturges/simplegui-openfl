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

import minimalcomps.components.CheckBox;
import minimalcomps.components.ColorChooser;
import minimalcomps.components.ComboBox;
import minimalcomps.components.Component;
import minimalcomps.components.HUISlider;
import minimalcomps.components.Label;
import minimalcomps.components.NumericStepper;
import minimalcomps.components.PushButton;
import minimalcomps.components.RangeSlider;
import minimalcomps.components.Style;

import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.DisplayObjectContainer;
import openfl.display.Sprite;
import openfl.display.Stage;
import openfl.errors.Error;
import openfl.events.ContextMenuEvent;
import openfl.events.Event;
import openfl.events.EventDispatcher;
import openfl.events.KeyboardEvent;
import openfl.events.MouseEvent;
import openfl.geom.Rectangle;
import openfl.net.FileReference;
import openfl.system.System;
//import openfl.ui.ContextMenu;
//import openfl.ui.ContextMenuItem;


/**
 * SimpleGUI
 */
class SimpleGUI extends EventDispatcher {

    //	----------------------------------------------------------------
    //	CONSTANTS
    //	----------------------------------------------------------------

    public static inline var VERSION:Float = 1.02;

    private static inline var TOOLBAR_HEIGHT:Int = 13;
    private static inline var COMPONENT_MARGIN:Int = 8;
    private static inline var COLUMN_MARGIN:Int = 1;
    private static inline var GROUP_MARGIN:Int = 1;
    private static inline var PADDING:Int = 4;
    private static inline var MARGIN:Int = 1;

    //	----------------------------------------------------------------
    //	PRIVATE MEMBERS
    //	----------------------------------------------------------------

    private var _components:Array<Component> = new Array<Component>();
    private var _parameters:Map<Component, Dynamic> = new Map<Component, Dynamic>();
    private var _container:Sprite = new Sprite();
    private var _target:DisplayObjectContainer;
    private var _active:Component;
    private var _stage:Stage;

    private var _toolbar:Sprite = new Sprite();
    private var _message:Label = new Label();
    private var _version:Label = new Label();
    private var _toggle:Sprite = new Sprite();
    private var _lineH:Bitmap = new Bitmap();
    private var _lineV:Bitmap = new Bitmap();
    private var _tween:Float = 0.0;
    private var _width:Float = 0.0;

    private var _hotKey:String;
    private var _column:Sprite;
    private var _group:Sprite;
    private var _dirty:Bool;
    private var _hidden:Bool;

    private var _showToggle:Bool = true;

    //	----------------------------------------------------------------
    //	CONSTRUCTOR
    //	----------------------------------------------------------------

    public function new(target:DisplayObjectContainer, title:String = null, hotKey:Dynamic = null) {
        super();

        _target = target;

        _toggle.x = MARGIN;
        _toggle.y = MARGIN;

        _toolbar.x = MARGIN;
        _toolbar.y = MARGIN;

        _container.x = MARGIN;
        _container.y = TOOLBAR_HEIGHT + (MARGIN * 2);

        initStyles();
        initToolbar();
        // TODO: Implement context menu functionality
        //initContextMenu();

        if (_target.stage != null)
            onAddedToStage(null);
        else
            _target.addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);

        _target.addEventListener(Event.ADDED, onTargetAdded);

        if (hotKey) this.hotKey = hotKey;

        addColumn(title);
        addGroup();
        hide();
    }

    //	----------------------------------------------------------------
    //	PUBLIC METHODS
    //	----------------------------------------------------------------

    /**
     * Shows the GUI
     */
    public function show():Void {
        _lineV.visible = false;

        _target.addChild(_container);
        _target.addChild(_toolbar);
        _target.addChild(_toggle);

        _hidden = false;
    }

    /**
     * Hides the GUI
     */
    public function hide():Void {
        _lineV.visible = true;

        if (!_showToggle && _target.contains(_toggle)) _target.removeChild(_toggle);
        if (_target.contains(_container)) _target.removeChild(_container);
        if (_target.contains(_toolbar)) _target.removeChild(_toolbar);

        _hidden = true;
    }

    /**
     * Populates the system clipboard with Actionscript code, setting all
     * controlled properties to their current values
     */

    public function save():Void {
        var path:String;
        var prop:Dynamic;
        var target:Dynamic;
        var targets:Array<Dynamic>;
        var options:Dynamic;
        var component:Component;
        var output:String = '';

        for (i in 0 ... _components.length) {
            component = _components[i];
            options = _parameters[component];

            if (options.hasOwnProperty("target")) {
                targets = [].concat(options.target);

                for (j in 1 ... targets.length) {
                    path = targets[j];
                    prop = getProp(path);
                    target = getTarget(path);

                    output += path + " = " + target[prop] + ';\n';
                }
            }
        }

        message = "Settings copied to clipboard";

        System.setClipboard(output);
    }

    /**
     * Generic method for adding controls. This is called internally by
     * specific control methods. It is best to use explicit methods for
     * adding controls (such as addSlider and addToggle), however this
     * method has been exposed for flexibility
     *
     * @param type The class definition of the component to add
     * @param options The options to configure the component with
     */

    public function addControl<T>(type:Class<T>, options:Dynamic):Component {
        var component:Component = cast Type.createInstance(type, []);

        // apply settings

        for (option in Reflect.fields(options)) {
            Reflect.setProperty(component, option, Reflect.getProperty(options, option));
        }

        // subscribe to component events

        if (Std.is(component, PushButton) || Std.is(component, CheckBox)) {
            component.addEventListener(MouseEvent.CLICK, onComponentClicked);
        }
        else if (Std.is(component, ComboBox)) {
            component.addEventListener(Event.SELECT, onComponentChanged);
        }
        else {
            component.addEventListener(Event.CHANGE, onComponentChanged);
        }

        // listen for first draw

        component.addEventListener(Component.DRAW, onComponentDraw);

        // add a label if necessary

        if (!Reflect.hasField(component, "label") && Reflect.hasField(options, "label") && !Std.is(type, Label)) {
            var container:Sprite = new Sprite();
            var label:Label = new Label();

            label.text = options.label;
            label.draw();

            component.x = label.width + 5;

            container.addChild(label);
            container.addChild(component);

            _group.addChild(container);
        }
        else {
            _group.addChild(component);
        }

        _parameters[component] = options;
        _components.push(component);

        update();
        //component.width = 200;

        return component;
    }

    /**
     * Adds a column to the GUI
     *
     * @param title An optional title to display at the top of the column
     */

    public function addColumn(title:String = null):Void {
        _column = new Sprite();
        _container.addChild(_column);
        addGroup(title);
    }

    /**
     * Creates a separator with an optional title to help segment groups
     * of controls
     *
     * @param title An optional title to display at the top of the group
     */

    public function addGroup(title:String = null):Void {
        if (_group != null && _group.numChildren == 0) {
            _group.parent.removeChild(_group);
        }

        _group = new Sprite();
        _column.addChild(_group);

        if (title != null) {
            addLabel(title.toUpperCase());
        }
    }

    /**
     * Adds a label
     *
     * @param text The text content of the label
     */

    public function addLabel(text:String):Label {
        return cast addControl(Label, {text : text.toUpperCase()}); // as Label
    }

    /**
     * Adds a toggle control for a boolean value
     *
     * @param target The name of the property to be controlled
     * @param options An optional object containing initialisation parameters
     * for the control, the keys of which should correspond to properties on
     * the control. Additional values can also be placed within this object,
     * such as a callback function. If a String is passed as this parameter,
     * it will be used as the control's label, though it is recommended that
     * you instead pass the label as a property within the options object
     */

    public function addToggle(target:String, options:Dynamic = null):CheckBox {
        options = parseOptions(target, options);

        var params:Dynamic = {};

        params.target = target;

        return cast addControl(CheckBox, merge(params, options)); // as CheckBox;
    }

    public function addButton(label:String, options:Dynamic = null):PushButton {
        options = parseOptions(label, options);

        var params:Dynamic = {};

        params.label = label;

        return cast addControl(PushButton, merge(params, options)); // as PushButton;
    }

    /**
     * Adds a slider control for a numerical value
     *
     * @param target The name of the property to be controlled
     * @param minimum The minimum slider value
     * @param maximum The maximum slider value
     * @param options An optional object containing initialisation parameters
     * for the control, the keys of which should correspond to properties on
     * the control. Additional values can also be placed within this object,
     * such as a callback function. If a String is passed as this parameter,
     * it will be used as the control's label, though it is recommended that
     * you instead pass the label as a property within the options object
     */

    public function addSlider(target:String, minimum:Float, maximum:Float, options:Dynamic = null):HUISlider {
        options = parseOptions(target, options);

        var params:Dynamic = {};

        // TODO: HUISlider has no `target` property
        //params.target = target;
        params.minimum = minimum;
        params.maximum = maximum;

        return cast addControl(HUISlider, merge(params, options)); // as HUISlider;
    }

    /**
     * Adds a range slider control for a numerical value
     *
     * @param target The name of the property to be controlled
     * @param minimum The minimum slider value
     * @param maximum The maximum slider value
     * @param options An optional object containing initialisation parameters
     * for the control, the keys of which should correspond to properties on
     * the control. Additional values can also be placed within this object,
     * such as a callback function. If a String is passed as this parameter,
     * it will be used as the control's label, though it is recommended that
     * you instead pass the label as a property within the options object
     */

    public function addRange(target1:String, target2:String, minimum:Float, maximum:Float, options:Dynamic = null):HUIRangeSlider {
        var target:Array<String> = [target1, target2];

        options = parseOptions(target.join(" / "), options);

        var params:Dynamic = {};

        params.target = target;
        params.minimum = minimum;
        params.maximum = maximum;

        return cast addControl(HUIRangeSlider, merge(params, options)); // as HUIRangeSlider;
    }

    /**
     * Adds a numeric stepper control for a numerical value
     *
     * @param target The name of the property to be controlled
     * @param minimum The minimum stepper value
     * @param maximum The maximum stepper value
     * @param options An optional object containing initialisation parameters
     * for the control, the keys of which should correspond to properties on
     * the control. Additional values can also be placed within this object,
     * such as a callback function. If a String is passed as this parameter,
     * it will be used as the control's label, though it is recommended that
     * you instead pass the label as a property within the options object
     */

    public function addStepper(target:String, minimum:Float, maximum:Float, options:Dynamic = null):NumericStepper {
        options = parseOptions(target, options);

        var params:Dynamic = {};

        params.target = target;
        params.minimum = minimum;
        params.maximum = maximum;

        return cast addControl(NumericStepper, merge(params, options)); // as NumericStepper;
    }

    /**
     * Adds a colour picker
     *
     * @param target The name of the property to be controlled
     * @param options An optional object containing initialisation parameters
     * for the control, the keys of which should correspond to properties on
     * the control. Additional values can also be placed within this object,
     * such as a callback function. If a String is passed as this parameter,
     * it will be used as the control's label, though it is recommended that
     * you instead pass the label as a property within the options object
     */

    public function addColour(target:String, options:Dynamic = null):ColorChooser {
        options = parseOptions(target, options);

        var params:Dynamic = {};

        params.target = target;
        params.usePopup = true;

        return cast addControl(ColorChooser, merge(params, options)); // as ColorChooser;
    }

    /**
     * Adds a combo box of values for a property
     *
     * @param target The name of the property to be controlled
     * @param items A list of selectable items for the combo box in the form
     * or [{label:"The Label", data:anObject},...]
     * @param options An optional object containing initialisation parameters
     * for the control, the keys of which should correspond to properties on
     * the control. Additional values can also be placed within this object,
     * such as a callback function. If a String is passed as this parameter,
     * it will be used as the control's label, though it is recommended that
     * you instead pass the label as a property within the options object
     */
    // TODO: There is no StyledCombo defined in SimpleGUI or MinimalComps.

    public function addComboBox(target:String, items:Array<Dynamic>, options:Dynamic = null):ComboBox {
        options = parseOptions(target, options);

        var params:Dynamic = {};

        var prop:String = getProp(target);
        var targ:Dynamic = getTarget(target);

        params.target = target;
        params.items = items;
        params.defaultLabel = Reflect.getProperty(targ, prop);
        params.numVisibleItems = Math.min(items.length, 5);

        return cast addControl(ComboBox, merge(params, options));
    }

    /**
     * Adds a file chooser for a File object
     *
     * @param label The label for the file
     * @param file The File object to control
     * @param onComplete A callback function to trigger when the file's data is loaded
     * @param filter An optional list of FileFilters to apply when selecting the file
     * @param options An optional object containing initialisation parameters
     * for the control, the keys of which should correspond to properties on
     * the control. Additional values can also be placed within this object,
     * such as a callback function. If a String is passed as this parameter,
     * it will be used as the control's label, though it is recommended that
     * you instead pass the label as a property within the options object
     */

    public function addFileChooser(label:String, file:FileReference, onComplete:Dynamic, filter:Array<String> = null, options:Dynamic = null):FileChooser {
        options = parseOptions(label, options);

        var params:Dynamic = {};

        params.file = file;
        params.label = label;
        params.width = 220;
        params.filter = filter;
        params.onComplete = onComplete;

        return cast addControl(FileChooser, merge(params, options)); // as FileChooser;
    }

    /**
     * Adds a save button to the controls. The save method can also be called
     * manually or by pressing the 's' key. Saving populates the system clipboard
     * with Actionscript code, setting all controlled properties to their current values
     *
     * @param label The label for the save button
     * @param options An optional object containing initialisation parameters
     * for the control, the keys of which should correspond to properties on
     * the control. Additional values can also be placed within this object,
     * such as a callback function. If a String is passed as this parameter,
     * it will be used as the control's label, though it is recommended that
     * you instead pass the label as a property within the options object
     */

    public function addSaveButton(label:String = "Save", options:Dynamic = null):PushButton {
        addGroup("Save Current Settings (S)");

        options = parseOptions(label, options);

        var params:Dynamic = {};

        params.label = label;

        var button:PushButton = cast addControl(PushButton, merge(params, options)); // as PushButton;
        button.addEventListener(MouseEvent.CLICK, onSaveButtonClicked);
        return button;
    }

    //	----------------------------------------------------------------
    //	PRIVATE METHODS
    //	----------------------------------------------------------------

    private function initStyles():Void {
        Style.PANEL = 0x333333;
        Style.BACKGROUND = 0x333333;
        Style.INPUT_TEXT = 0xEEEEEE;
        Style.LABEL_TEXT = 0xEEEEEE;
        Style.BUTTON_FACE = 0x555555;
        Style.DROPSHADOW = 0x000000;

        Style.LIST_DEFAULT = 0x333333;
        Style.LIST_ALTERNATE = 0x444444;
        Style.LIST_SELECTED = 0x111111;
        Style.LIST_ROLLOVER = 0x555555;
    }

    private function initToolbar():Void {
        _toolbar.x += TOOLBAR_HEIGHT + 1;

        _version = new Label();
        _version.text = "SimpelGUI v" + VERSION;
        _version.alpha = 0.5;

        _message = new Label();
        _message.alpha = 0.6;
        _message.x = 2;

        _version.y = _message.y = -3;

        _toggle.graphics.beginFill(0x333333, 0.9);
        _toggle.graphics.drawRect(0, 0, TOOLBAR_HEIGHT, TOOLBAR_HEIGHT);
        _toggle.graphics.endFill();

        _toolbar.addChild(_version);
        _toolbar.addChild(_message);

        _toggle.addEventListener(MouseEvent.CLICK, onToggleClicked);
        _toggle.buttonMode = true;

        //

        _lineH.bitmapData = new BitmapData(5, 1, false, 0xFFFFFF);
        _lineV.bitmapData = new BitmapData(1, 5, false, 0xFFFFFF);

        _lineH.x = (TOOLBAR_HEIGHT * 0.5) - 3;
        _lineH.y = (TOOLBAR_HEIGHT * 0.5) - 1;

        _lineV.x = (TOOLBAR_HEIGHT * 0.5) - 1;
        _lineV.y = (TOOLBAR_HEIGHT * 0.5) - 3;

        _toggle.addChild(_lineH);
        _toggle.addChild(_lineV);
    }

    // TODO: Determine appropriate implementation
//    private function initContextMenu():Void {
//        var menu : * = _target.contextMenu || new ContextMenu();
//        var item:ContextMenuItem = new ContextMenuItem("Toggle Controls", true);
//
//        item.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, onContextMenuItemSelected);
//        menu.customItems.push(item);
//
//        _target.contextMenu = menu;
//    }

    private function commit(component:Component = null):Void {
        if (component != null) {
            _active = component;
            apply(component, true);
        }
        else {
            for (i in 0 ... _components.length) {
                component = _components[i];
                apply(component, false);
            }
        }

        update();
    }

    private function apply(component:Component, extended:Bool = false):Void {
        var i:Int;
        var path:String;
        var prop:Dynamic;
        var target:Dynamic;
        var targets:Array<String>; // TODO: Confirm datatype
        var options:Dynamic = _parameters[component];

        if (options.hasOwnProperty("target")) {
            targets = [].concat(options.target);

            for (i in 0 ... targets.length) {
                path = targets[i];
                prop = getProp(path);
                target = getTarget(path);

                if (Std.is(component, CheckBox)) {
                    var checkBox:CheckBox = cast component;
                    target[prop] = checkBox.selected;
                }
                else if (Std.is(component, RangeSlider)) {
                    var rangeSlider:RangeSlider = cast component;
                    target[prop] = (i == 0) ? rangeSlider.lowValue : rangeSlider.highValue;
                }
                else if (Std.is(component, ComboBox)) {
                    var comboBox:ComboBox = cast component;
                    if (comboBox.selectedItem != null)
                        target[prop] = comboBox.selectedItem.data;
                }
                else if (Reflect.hasField(component, "value")) {
                    target[prop] = Reflect.getProperty(component, "value");
                }
            }
        }

        if (extended && options.hasOwnProperty("callback")) {
            Reflect.callMethod(_target, options.callback, options.callbackParams);
        }
    }

    private function update():Void {
        var i:Int;
        var j:Int;
        var path:String;
        var prop:Dynamic;
        var target:Dynamic;
        var targets:Array<String>; // TODO: Confirm datatype
        var options:Dynamic;
        var component:Component;

        for (i in 0 ... _components.length) {
            component = _components[i];

            if (component == _active) continue;

            options = _parameters[component];

            if (options.hasOwnProperty("target")) {
                targets = [].concat(options.target);

                for (j in 0 ... targets.length) {
                    path = targets[j];
                    prop = getProp(path);
                    target = getTarget(path);

                    if (Std.is(component, CheckBox)) {
                        var checkBox:CheckBox = cast component;
                        checkBox.selected = target[prop];
                    }
                    else if (Std.is(component, RangeSlider)) {
                        var rangeSlider:RangeSlider = cast component;
                        if (j == 0)
                            rangeSlider.lowValue = target[prop];
                        else
                            rangeSlider.highValue = target[prop];
                    }
                    else if (Std.is(component, ComboBox)) {
                        var comboBox:ComboBox = cast component;
                        var items:Array<Dynamic> = comboBox.items;

                        for (k in 0 ... items.length) {
                            if (items[k].data == target[prop]) {
                                if (comboBox.selectedIndex != k) {
                                    comboBox.selectedIndex = k;
                                    break;
                                }
                            }
                        }
                    }
                    else if (Reflect.hasField(component, "value")) {
                        Reflect.setProperty(component, "value", Reflect.getProperty(target, prop));
                    }
                }
            }
        }
    }

    private function invalidate():Void {
        _container.addEventListener(Event.ENTER_FRAME, onEnterFrame);
        _dirty = true;
    }

    private function draw():Void {
        var i:Int;
        var j:Int;
        var k:Int;

        var ghs:Array<Int>;

        var gw:Int = 0;
        var gh:Int = 0;
        var gy:Int = 0;
        var cx:Int = 0;
        var cw:Int = 0;

        var group:Sprite;
        var column:Sprite;
        var component:Sprite;
        var bounds:Rectangle;

        for (i in 0 ... _container.numChildren) {
            column = cast(_container.getChildAt(i), Sprite);
            column.x = cx;

            gy = cw = 0;
            ghs = [];

            for (j in 0 ... column.numChildren) {
                group = cast(column.getChildAt(j), Sprite);
                group.y = gy;

                gw = 0;
                gh = PADDING;

                for (k in 0 ... group.numChildren) {
                    component = cast(group.getChildAt(k), Sprite);

                    bounds = component.getBounds(component);

                    component.x = PADDING - bounds.x;
                    component.y = gh - bounds.y;

                    gw = Math.floor(Math.max(gw, bounds.width));
                    gh += Math.floor(bounds.height + (k < group.numChildren - 1 ? COMPONENT_MARGIN : 0));
                }

                gh += PADDING;
                ghs[j] = gh;

                gy += gh + GROUP_MARGIN;
                cw = Math.floor(Math.max(cw, gw));
            }

            cw += (PADDING * 2);

            for (j in 0 ... column.numChildren) {
                group = cast(column.getChildAt(j), Sprite);

                for (k in 0 ... group.numChildren) {
                    component = cast(group.getChildAt(k), Sprite);

                    bounds = component.getBounds(component);
                    bounds.bottom += COMPONENT_MARGIN / 2;

                    component.graphics.clear();
                    component.graphics.lineStyle(0, 0x000000, 0.1);
                    component.graphics.moveTo(bounds.left, bounds.bottom);
                    component.graphics.lineTo(bounds.x + cw - (PADDING * 2), bounds.bottom);
                }

                group.graphics.clear();
                group.graphics.beginFill(0x333333, 0.9);
                group.graphics.drawRect(0, 0, cw, ghs[j]);
                group.graphics.endFill();
            }

            cx += cw + COLUMN_MARGIN;
        }

        _width = cx - COLUMN_MARGIN;
        _version.x = _width - _toolbar.x - _version.width - 2;

        _toolbar.graphics.clear();
        _toolbar.graphics.beginFill(0x333333, 0.9);
        _toolbar.graphics.drawRect(0, 0, _width - _toolbar.x, TOOLBAR_HEIGHT);
        _toolbar.graphics.endFill();
    }

    private function parseOptions(target:String, options:Dynamic):Dynamic {
        options = clone(options);

        if (Std.is(options, String)) {
            return {label: options};
        } else if (Reflect.hasField(options, "label")) {
            return options;
        } else {
            return {label: propToLabel(target)};
        }
    }

    private function getTarget(path:String):Dynamic {
        var target:Dynamic = _target;
        var hierarchy:Array<String> = path.split('.');

        if (hierarchy.length == 1)
            return _target;

        for (i in 0 ... hierarchy.length - 1) {
            target = Reflect.getProperty(target, hierarchy[i]);
        }

        return target;
    }

    // TODO: Rework
    private function getProp(path:String):String {
        return null;
        //return /[_a - z0 - 9] + $ /i.exec(path)[0];
    }

    private function merge(source:Dynamic, destination:Dynamic):Dynamic {
        var combined:Dynamic = clone(destination);

        for (prop in Reflect.fields(source)) {
            if (!Reflect.hasField(destination, prop)) {
                Reflect.setProperty(combined, prop, Reflect.getProperty(source, prop));
            }
        }

        return combined;
    }

    private function clone(source:Dynamic):Dynamic {
        var copy:Dynamic = {};

        for (prop in Reflect.fields(source)) {
            Reflect.setProperty(copy, prop, Reflect.getProperty(source, prop));
        }

        return copy;
    }

    // TODO: Rework
    private function propToLabel(prop:String):String {
        return prop;
        //return prop .replace(/[_]+ ([a - zA - Z0 - 9] + ) | ([0 - 9]+ ) / g, " $1$2 ")
        //.replace( / (?<=[a - z0 - 9])([A - Z]) | (?<=[a - z])([0 - 9]) / g, " $1$2")
        //.replace( / ^ (\w) | \s + (\w)| \. + (\w) / g, capitalise)
        //.replace( / ^ \s| \s$ | (?<=\s)\s + / g, '');
    }

    // TODO: Macro extra:Array<Expr> rest argument?
    private function capitalise(args:Array<String>):String {
        return Std.string(' ' + args[1] + args[2] + args[3]).toUpperCase();
    }


    //	----------------------------------------------------------------
    //	EVENT HANDLERS
    //	----------------------------------------------------------------

    private function onAddedToStage(event:Event):Void {
        _stage = _target.stage;
        _target.removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
        _target.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPressed);
    }

    private function onTargetAdded(event:Event):Void {
        if (!_hidden) show();
    }

    private function onSaveButtonClicked(event:MouseEvent):Void {
        save();
    }

    private function onToggleClicked(event:MouseEvent):Void {
        _hidden ? show() : hide();
    }

    private function onContextMenuItemSelected(event:ContextMenuEvent):Void {
        _hidden ? show() : hide();
    }

    private function onComponentClicked(event:MouseEvent):Void {
        commit(cast(event.target, Component));
    }

    private function onComponentChanged(event:Event):Void {
        commit(cast (event.target, Component));
    }

    private function onComponentDraw(event:Event):Void {
        var component:Component = cast(event.target, Component);
        component.removeEventListener(Component.DRAW, onComponentDraw);
        invalidate();
    }

    private function onEnterFrame(event:Event):Void {
        _container.removeEventListener(Event.ENTER_FRAME, onEnterFrame);

        if (_dirty) {
            _dirty = false;
            draw();
        }
    }

    private function onKeyPressed(event:KeyboardEvent):Void {
        if (hotKey && event.keyCode == hotKey.toUpperCase().charCodeAt(0)) {
            _hidden ? show() : hide();
        }

        if (event.keyCode == 83) {
            save();
        }
    }

    private function onMessageEnterFrame(event:Event):Void {
        _tween += 0.01;
        _message.alpha = 1.0 - (-0.5 * (Math.cos(Math.PI * _tween) - 1));

        if (_message.alpha < 0.0001) {
            _message.removeEventListener(Event.ENTER_FRAME, onMessageEnterFrame);
            _message.text = '';
        }
    }

    //	----------------------------------------------------------------
    //	PUBLIC ACCESSORS
    //	----------------------------------------------------------------

    public var showToggle(get, set):Bool;

    public function get_showToggle():Bool {
        return _showToggle;
    }

    public function set_showToggle(value:Bool):Bool {
        _showToggle = value;
        if (_hidden) hide();

        return _showToggle;
    }

    public var message(never, set):String;

    public function set_message(value:String):String {
        _tween = 0.0;
        _message.alpha = 1.0;
        _message.text = value.toUpperCase();
        _message.addEventListener(Event.ENTER_FRAME, onMessageEnterFrame);

        return _message.text;
    }

    public var hotKey(get, set):Dynamic;

    public function get_hotKey():Dynamic {
        return _hotKey;
    }

    public function set_hotKey(value:Dynamic):Dynamic {
        if (Std.is(value, String)) {
            _hotKey = value;
        }
        else if (Std.is(value, Int)) {
            _hotKey = String.fromCharCode(value);
        }
        else {
            throw new Error("HotKey must be a String or an integer");
        }

        message = "Hotkey set to '" + _hotKey + "'";

        return _hotKey;
    }
}
