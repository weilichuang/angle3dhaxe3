package org.angle3d.bullet.debug;
import org.angle3d.material.Material;
import org.angle3d.material.VarType;
import org.angle3d.math.Color;
import org.angle3d.math.Vector3f;
import org.angle3d.renderer.RenderManager;
import org.angle3d.renderer.ViewPort;
import org.angle3d.scene.debug.Arrow;
import org.angle3d.scene.Geometry;
import org.angle3d.scene.Node;

/**
 * ...
 * @author weilichuang
 */
class DebugTools
{
    public var DEBUG_BLUE:Material;
    public var DEBUG_RED:Material;
    public var DEBUG_GREEN:Material;
    public var DEBUG_YELLOW:Material;
    public var DEBUG_MAGENTA:Material;
    public var DEBUG_PINK:Material;
	
    public var debugNode:Node;
    public var arrowBlue:Arrow;
    public var arrowBlueGeom:Geometry;
    public var arrowGreen:Arrow;
    public var arrowGreenGeom:Geometry;
    public var arrowRed:Arrow;
    public var arrowRedGeom:Geometry;
    public var arrowMagenta:Arrow;
    public var arrowMagentaGeom:Geometry;
    public var arrowYellow:Arrow;
    public var arrowYellowGeom:Geometry;
    public var arrowPink:Arrow;
    public var arrowPinkGeom:Geometry;
	
    private static var UNIT_X_CHECK:Vector3f = new Vector3f(1, 0, 0);
    private static var UNIT_Y_CHECK:Vector3f = new Vector3f(0, 1, 0);
    private static var UNIT_Z_CHECK:Vector3f = new Vector3f(0, 0, 1);
    private static var UNIT_XYZ_CHECK:Vector3f = new Vector3f(1, 1, 1);
    private static var ZERO_CHECK:Vector3f = new Vector3f(0, 0, 0);

    public function new() 
	{
		debugNode = new Node("Debug Node");
		arrowBlue = new Arrow(Vector3f.ZERO);
		arrowBlueGeom = new Geometry("Blue Arrow", arrowBlue);
		arrowGreen = new Arrow(Vector3f.ZERO);
		arrowGreenGeom = new Geometry("Green Arrow", arrowGreen);
		arrowRed = new Arrow(Vector3f.ZERO);
		arrowRedGeom = new Geometry("Red Arrow", arrowRed);
		arrowMagenta = new Arrow(Vector3f.ZERO);
		arrowMagentaGeom = new Geometry("Magenta Arrow", arrowMagenta);
		arrowYellow = new Arrow(Vector3f.ZERO);
		arrowYellowGeom = new Geometry("Yellow Arrow", arrowYellow);
		arrowPink = new Arrow(Vector3f.ZERO);
		arrowPinkGeom = new Geometry("Pink Arrow", arrowPink);
		
        setupMaterials();
        setupDebugNode();
    }

    public function show(rm:RenderManager, vp:ViewPort):Void
	{
        debugNode.updateLogicalState(0);
        debugNode.updateGeometricState();
        rm.renderScene(debugNode, vp);
    }

    public function setBlueArrow(location:Vector3f, extent:Vector3f):Void
	{
        arrowBlueGeom.setLocalTranslation(location);
        arrowBlue.setArrowExtent(extent);
    }

    public function setGreenArrow(location:Vector3f, extent:Vector3f):Void
	{
        arrowGreenGeom.setLocalTranslation(location);
        arrowGreen.setArrowExtent(extent);
    }

    public function setRedArrow(location:Vector3f, extent:Vector3f):Void
	{
        arrowRedGeom.setLocalTranslation(location);
        arrowRed.setArrowExtent(extent);
    }

    public function setMagentaArrow(location:Vector3f, extent:Vector3f):Void
	{
        arrowMagentaGeom.setLocalTranslation(location);
        arrowMagenta.setArrowExtent(extent);
    }

    public function setYellowArrow(location:Vector3f, extent:Vector3f):Void
	{
        arrowYellowGeom.setLocalTranslation(location);
        arrowYellow.setArrowExtent(extent);
    }

    public function setPinkArrow(location:Vector3f, extent:Vector3f):Void
	{
        arrowPinkGeom.setLocalTranslation(location);
        arrowPink.setArrowExtent(extent);
    }

    private function setupDebugNode():Void
	{
        arrowBlueGeom.setMaterial(DEBUG_BLUE);
        arrowGreenGeom.setMaterial(DEBUG_GREEN);
        arrowRedGeom.setMaterial(DEBUG_RED);
        arrowMagentaGeom.setMaterial(DEBUG_MAGENTA);
        arrowYellowGeom.setMaterial(DEBUG_YELLOW);
        arrowPinkGeom.setMaterial(DEBUG_PINK);
        debugNode.attachChild(arrowBlueGeom);
        debugNode.attachChild(arrowGreenGeom);
        debugNode.attachChild(arrowRedGeom);
        debugNode.attachChild(arrowMagentaGeom);
        debugNode.attachChild(arrowYellowGeom);
        debugNode.attachChild(arrowPinkGeom);
    }

    private function setupMaterials():Void 
	{
		DEBUG_BLUE = new Material();
		DEBUG_BLUE.load("assets/material/wireframe.mat");
		DEBUG_BLUE.setParam("u_color", VarType.COLOR, Color.Blue());
		
		DEBUG_GREEN = new Material();
		DEBUG_GREEN.load("assets/material/wireframe.mat");
		DEBUG_GREEN.setParam("u_color", VarType.COLOR, Color.Green());
		
		DEBUG_RED = new Material();
		DEBUG_RED.load("assets/material/wireframe.mat");
		DEBUG_RED.setParam("u_color", VarType.COLOR, Color.Red());
		
		DEBUG_YELLOW = new Material();
		DEBUG_YELLOW.load("assets/material/wireframe.mat");
		DEBUG_YELLOW.setParam("u_color", VarType.COLOR, Color.Yellow());
		
		DEBUG_MAGENTA = new Material();
		DEBUG_MAGENTA.load("assets/material/wireframe.mat");
		DEBUG_MAGENTA.setParam("u_color", VarType.COLOR, Color.Magenta());
		
		DEBUG_PINK = new Material();
		DEBUG_PINK.load("assets/material/wireframe.mat");
		DEBUG_PINK.setParam("u_color", VarType.COLOR, Color.Pink());
    }
	
}