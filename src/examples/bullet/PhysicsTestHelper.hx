package examples.bullet;
import flash.display3D.Context3DTextureFilter;
import flash.display3D.Context3DWrapMode;
import flash.ui.Keyboard;
import org.angle3d.app.Application;
import org.angle3d.bullet.collision.shapes.CollisionShape;
import org.angle3d.bullet.collision.shapes.MeshCollisionShape;
import org.angle3d.bullet.control.RigidBodyControl;
import org.angle3d.bullet.PhysicsSpace;
import org.angle3d.input.controls.ActionListener;
import org.angle3d.input.controls.KeyTrigger;
import org.angle3d.light.AmbientLight;
import org.angle3d.material.Material;
import org.angle3d.material.MaterialTexture;
import org.angle3d.math.Color;
import org.angle3d.scene.Geometry;
import org.angle3d.scene.Node;
import org.angle3d.scene.shape.Box;
import org.angle3d.scene.shape.Sphere;
import org.angle3d.texture.Texture2D;

@:bitmap("../assets/embed/logo/Monkey.jpg") class MONKEY_ASSET extends flash.display.BitmapData { }
@:bitmap("../assets/embed/rock.png") class ROCK_ASSET extends flash.display.BitmapData { }
/**
 * ...
 * @author weilichuang
 */
class PhysicsTestHelper
{

	/**
     * creates a simple physics test world with a floor, an obstacle and some test boxes
     * @param rootNode
     * @param assetManager
     * @param space
     */
    public static function createPhysicsTestWorld(rootNode:Node, space:PhysicsSpace):Void
	{
        //var light:AmbientLight = new AmbientLight();
        //light.color = Color.LightGray();
        //rootNode.addLight(light);

		var texture:Texture2D = new Texture2D(new MONKEY_ASSET(0, 0));
		texture.wrapMode = Context3DWrapMode.REPEAT;
		texture.textureFilter = Context3DTextureFilter.LINEAR;
        var material:Material = new MaterialTexture(texture);

        var floorBox:Box = new Box(140, 0.25, 140);
        var floorGeometry:Geometry = new Geometry("Floor", floorBox);
        floorGeometry.setMaterial(material);
        floorGeometry.setTranslationXYZ(0, -5, 0);
//        Plane plane = new Plane();
//        plane.setOriginNormal(new Vector3f(0, 0.25f, 0), Vector3f.UNIT_Y);
//        floorGeometry.addControl(new RigidBodyControl(new PlaneCollisionShape(plane), 0));
		var rigidBody:RigidBodyControl = new RigidBodyControl(null, 0);
		rigidBody.showDebug = false;
        floorGeometry.addControl(rigidBody);
        rootNode.attachChild(floorGeometry);
        space.add(floorGeometry);
		
		//var node3:Node = createPhysicsTestNode(new PlaneCollisionShape(new Plane(new Vector3f(0, 1, 0), 0)), 0);
        //cast(node3.getControl(RigidBodyControl),RigidBodyControl).setPhysicsLocation(new Vector3f(0, -5, 0));
        //rootNode.attachChild(node3);
        //space.add(node3);

        //movable boxes
        for (i in 0...12)
		{
            var box:Box = new Box(0.25, 0.25, 0.25);
            var boxGeometry:Geometry = new Geometry("Box", box);
            boxGeometry.setMaterial(material);
            boxGeometry.setTranslationXYZ(i, 5, -3);
            //RigidBodyControl automatically uses box collision shapes when attached to single geometry with box mesh
            boxGeometry.addControl(new RigidBodyControl(null, 2));
            rootNode.attachChild(boxGeometry);
            space.add(boxGeometry);
        }

        //immovable sphere with mesh collision shape
        var sphere:Sphere = new Sphere(1, 8, 8);
        var sphereGeometry:Geometry = new Geometry("Sphere", sphere);
        sphereGeometry.setMaterial(material);
        sphereGeometry.setTranslationXYZ(4, -4, 2);
        sphereGeometry.addControl(new RigidBodyControl(new MeshCollisionShape(sphere), 0));
        rootNode.attachChild(sphereGeometry);
        space.add(sphereGeometry);

    }
    
    public static function createPhysicsTestWorldSoccer(rootNode:Node, space:PhysicsSpace):Void
	{
        var light:AmbientLight = new AmbientLight();
        light.color = Color.LightGray();
        rootNode.addLight(light);

        var texture:Texture2D = new Texture2D(new MONKEY_ASSET(0, 0));
        var material:Material = new MaterialTexture(texture);

        var floorBox:Box = new Box(20, 0.25, 20);
        var floorGeometry:Geometry = new Geometry("Floor", floorBox);
        floorGeometry.setMaterial(material);
        floorGeometry.setTranslationXYZ(0, -0.25, 0);
//        Plane plane = new Plane();
//        plane.setOriginNormal(new Vector3f(0, 0.25, 0), Vector3f.UNIT_Y);
//        floorGeometry.addControl(new RigidBodyControl(new PlaneCollisionShape(plane), 0));
        floorGeometry.addControl(new RigidBodyControl(null,0));
        rootNode.attachChild(floorGeometry);
        space.add(floorGeometry);

        //movable spheres
        for (i in 0...5)
		{
            var sphere:Sphere = new Sphere(0.5, 16, 16);
            var ballGeometry:Geometry = new Geometry("Soccer ball", sphere);
            ballGeometry.setMaterial(material);
            ballGeometry.setTranslationXYZ(i, 2, -3);
            //RigidBodyControl automatically uses Sphere collision shapes when attached to single geometry with sphere mesh
            ballGeometry.addControl(new RigidBodyControl(null,.001));
            cast(ballGeometry.getControl(RigidBodyControl),RigidBodyControl).setRestitution(1);
            rootNode.attachChild(ballGeometry);
            space.add(ballGeometry);
        }
		
        {
			//immovable Box with mesh collision shape
			var box:Box = new Box(1, 1, 1);
			var boxGeometry:Geometry = new Geometry("Box", box);
			boxGeometry.setMaterial(material);
			boxGeometry.setTranslationXYZ(4, 1, 2);
			boxGeometry.addControl(new RigidBodyControl(new MeshCollisionShape(box), 0));
			rootNode.attachChild(boxGeometry);
			space.add(boxGeometry);
        }
        {
			//immovable Box with mesh collision shape
			var box:Box = new Box(1, 1, 1);
			var boxGeometry:Geometry = new Geometry("Box", box);
			boxGeometry.setMaterial(material);
			boxGeometry.setTranslationXYZ(4, 3, 4);
			boxGeometry.addControl(new RigidBodyControl(new MeshCollisionShape(box), 0));
			rootNode.attachChild(boxGeometry);
			space.add(boxGeometry);
        }
    }

    /**
     * creates a box geometry with a RigidBodyControl
     * @param assetManager
     * @return
     */
    public static function createPhysicsTestBox():Geometry
	{
        var texture:Texture2D = new Texture2D(new MONKEY_ASSET(0, 0));
        var material:Material = new MaterialTexture(texture);
        var box:Box = new Box(0.25, 0.25, 0.25);
        var boxGeometry:Geometry = new Geometry("Box", box);
        boxGeometry.setMaterial(material);
        //RigidBodyControl automatically uses box collision shapes when attached to single geometry with box mesh
        boxGeometry.addControl(new RigidBodyControl(null,2));
        return boxGeometry;
    }

    /**
     * creates a sphere geometry with a RigidBodyControl
     * @param assetManager
     * @return
     */
    public static function createPhysicsTestSphere():Geometry
	{
        var texture:Texture2D = new Texture2D(new MONKEY_ASSET(0, 0));
        var material:Material = new MaterialTexture(texture);
		
        var sphere:Sphere = new Sphere(0.25, 8, 8);
        var boxGeometry:Geometry = new Geometry("Sphere", sphere);
        boxGeometry.setMaterial(material);
        //RigidBodyControl automatically uses sphere collision shapes when attached to single geometry with sphere mesh
        boxGeometry.addControl(new RigidBodyControl(null,2));
        return boxGeometry;
    }

    /**
     * creates an empty node with a RigidBodyControl
     * @param manager
     * @param shape
     * @param mass
     * @return
     */
    public static function createPhysicsTestNode(shape:CollisionShape, mass:Float):Node
	{
        var node:Node = new Node("PhysicsNode");
        var control:RigidBodyControl = new RigidBodyControl(shape, mass);
        node.addControl(control);
        return node;
    }

    /**
     * creates the necessary inputlistener and action to shoot balls from teh camera
     * @param app
     * @param rootNode
     * @param space
     */
    public static function createBallShooter(app:Application, rootNode:Node, space:PhysicsSpace, showBoom:Bool = true):Void
	{
        var actionListener:ActionListener = new PhysicsTestActionListener(app, rootNode, space, showBoom);
        app.getInputManager().addSingleMapping("shoot", new KeyTrigger(Keyboard.SPACE));
        app.getInputManager().addListener(actionListener, ["shoot"]);
    }
	
}

class PhysicsTestActionListener implements ActionListener
{
	private var app:Application;
	private var rootNode:Node;
	private var space:PhysicsSpace;
	private var showBoom:Bool;
	public function new(app:Application, rootNode:Node, space:PhysicsSpace, showBoom:Bool)
	{
		this.app = app;
		this.rootNode = rootNode;
		this.space = space;
		this.showBoom = showBoom;
	}
	
	public function onAction(name:String, isPressed:Bool, tpf:Float):Void
	{
		var bullet:Sphere = new Sphere(0.4, 16, 16, true);
		
		var texture:Texture2D = new Texture2D(new ROCK_ASSET(0, 0));
        var material:Material = new MaterialTexture(texture);

		if (name == "shoot" && !isPressed)
		{
			var bulletg:Geometry = new Geometry("bullet", bullet);
			bulletg.setMaterial(material);
			//bulletg.setShadowMode(ShadowMode.CastAndReceive);
			bulletg.setLocalTranslation(app.camera.location);
			var bulletControl:RigidBodyControl;
			if (this.showBoom)
				bulletControl = new BombControl(null, 10);
			else
				bulletControl = new RigidBodyControl(null, 10);
			bulletControl.showDebug = false;
			bulletg.addControl(bulletControl);
			bulletControl.setCcdMotionThreshold(0.1);
			bulletControl.setCcdSweptSphereRadius(0.2);
			bulletControl.setLinearVelocity(app.camera.getDirection().scaleLocal(25));
			bulletg.addControl(bulletControl);
			rootNode.attachChild(bulletg);
			space.add(bulletControl);
		}
	}
}