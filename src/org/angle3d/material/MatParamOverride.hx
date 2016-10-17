package org.angle3d.material;
import org.angle3d.material.MatParam;

/**
 * `MatParamOverride` is a mechanism by which
 * {@link MatParam material parameters} can be overridden on the scene graph.
 * <p>
 * A scene branch which has a `MatParamOverride` applied to it will
 * cause all material parameters with the same name and type to have their value
 * replaced with the value set on the `MatParamOverride`. If those
 * parameters are mapped to a define, then the define will be overridden as well
 * using the same rules as the ones used for regular material parameters.
 * <p>
 * `MatParamOverrides` are applied to a {@link Spatial} via the
 * {@link Spatial#addMatParamOverride(com.jme3.material.MatParamOverride)}
 * method. They are propagated to child `Spatials` via
 * {@link Spatial#updateGeometricState()} similar to how lights are propagated.
 * <p>
 * Example:<br>
 * <pre>
 * {@code
 *
 * Geometry box = new Geometry("Box", new Box(1,1,1));
 * Material mat = new Material(assetManager, "Common/MatDefs/Misc/Unshaded.j3md");
 * mat.setColor("Color", ColorRGBA.Blue);
 * box.setMaterial(mat);
 * rootNode.attachChild(box);
 *
 * // ... later ...
 * MatParamOverride override = new MatParamOverride(Type.Vector4, "Color", ColorRGBA.Red);
 * rootNode.addMatParamOverride(override);
 *
 * // After adding the override to the root node, the box becomes red.
 * }
 * </pre>
 *
 * @author Kirill Vainer
 * @see Spatial#addMatParamOverride(com.jme3.material.MatParamOverride)
 * @see Spatial#getWorldMatParamOverrides()
 */
class MatParamOverride extends MatParam
{
	private var _enabled:Bool = true;
	
	public var enabled(get, set):Bool;

	public function new(type:VarType, name:String, value:Dynamic) 
	{
		super(type, name, value);
		
	}
	
	override public function equals(other:MatParam):Bool 
	{
		return super.equals(other) && (_enabled == cast(other,MatParamOverride)._enabled);
	}
	
	private inline function get_enabled():Bool
	{
		return _enabled;
	}
	
	private inline function set_enabled(value:Bool):Bool
	{
		return _enabled = value;
	}
	
}