package org.angle3d.scene;

import flash.Vector;
import org.angle3d.bounding.BoundingVolume;
import org.angle3d.collision.Collidable;
import org.angle3d.collision.CollisionResults;
import org.angle3d.material.Material;
import org.angle3d.utils.Assert;
import org.angle3d.utils.Logger;

using org.angle3d.utils.ArrayUtil;
/**
 * <code>Node</code> defines an internal node of a scene graph. The internal
 * node maintains a collection of children and handles merging said children
 * into a single bound to allow for very fast culling of multiple nodes. Node
 * allows for any number of children to be attached.
 *
 */

class Node extends Spatial
{
	public var children(default, null):Array<Spatial>;
	public var numChildren(get, null):Int;

	public function new(name:String)
	{
		super(name);
		children = new Array<Spatial>();
	}

	override public function setMaterial(material:Material):Void
	{
		var numChildren:Int = children.length;
		for (i in 0...numChildren)
		{
			children[i].setMaterial(material);
		}
	}

	override public function setTransformRefresh():Void
	{
		super.setTransformRefresh();

		var cLength:Int = children.length;
		for (i in 0...cLength)
		{
			var child:Spatial = children[i];
			if (!child.needTransformUpdate())
			{
				child.setTransformRefresh();
			}
		}
	}

	override public function setLightListRefresh():Void
	{
		super.setLightListRefresh();

		var cLength:Int = children.length;
		for (i in 0...cLength)
		{
			var child:Spatial = children[i];
			if (!child.needLightListUpdate())
			{
				child.setLightListRefresh();
			}
		}
	}

	override public function updateWorldBound():Void
	{
		super.updateWorldBound();

		// for a node, the world bound is a combination of all it's children bounds
		var resultBound:BoundingVolume = null;
		for (child in children)
		{
			//child bound is assumed to be updated
			Assert.assert(!child.needBoundUpdate(), "child bound is not updated");

			if (resultBound != null)
			{
				// merge current world bound with child world bound
				resultBound.mergeLocal(child.worldBound);
			}
			else
			{
				// set_world bound to first non-null child world bound
				if (child.worldBound != null)
				{
					resultBound = child.worldBound.clone(mWorldBound);
				}
			}
		}

		mWorldBound = resultBound;
	}

	override public function runControlUpdate(tpf:Float):Void
	{
		super.runControlUpdate(tpf);

		for (child in children)
		{
			child.runControlUpdate(tpf);
		}
	}
	
	override public function updateLogicalState(tpf:Float):Void
	{
		super.updateLogicalState(tpf);
		
		if (numChildren == 0)
			return;
			
		var cLength:Int = children.length;
		for (i in 0...cLength)
		{
			var child:Spatial = children[i];
			child.updateLogicalState(tpf);
		}	
	}

	override public function updateGeometricState():Void
	{
		if (needLightListUpdate())
		{
			updateWorldLightList();
		}

		if (needTransformUpdate())
		{
			// combine with parent transforms- same for all spatial subclasses.
			updateWorldTransforms();
		}

		if (numChildren > 0)
		{
			for (child in children)
			{
				// the important part- make sure child geometric state is refreshed
				// first before updating own world bound. This saves
				// a round-trip later on.
				// NOTE 9/19/09
				// Although it does save a round trip,
				child.updateGeometricState();
			}
		}

		if (needBoundUpdate())
		{
			updateWorldBound();
		}

		Assert.assert(mRefreshFlags == 0, "refreshFlags == 0");
	}
	
	override public function getTriangleCount():Int 
	{
		var count:Int = 0;
		for (i in 0...children.length)
		{
			var child:Spatial = children[i];
			count += child.getTriangleCount();
		}
		return count;
	}
	
	override public function getVertexCount():Int 
	{
		var count:Int = 0;
		for (i in 0...children.length)
		{
			var child:Spatial = children[i];
			count += child.getVertexCount();
		}
		return count;
	}

	/**
	 *
	 * <code>attachChild</code> attaches a child to this node. This node
	 * becomes the child's parent. The current number of children maintained is
	 * returned.
	 * <br>
	 * If the child already had a parent it is detached from that former parent.
	 *
	 * @param child
	 *            the child to attach to this node.
	 * @return the number of children maintained by this node.
	 */
	public function attachChild(child:Spatial):Void
	{
		var cParent:Node = child.parent;
		if (cParent != this && child != this)
		{
			if (cParent != null)
			{
				cParent.detachChild(child);
			}

			child.parent = this;
			children.push(child);

			// XXX: Not entirely correct? Forces bound update up the
			// tree stemming from the attached child. Also forces
			// transform update down the tree-
			child.setTransformRefresh();
			child.setLightListRefresh();

			#if debug
			Logger.log(child.toString() + " attached to " + this.toString());
			#end
		}
	}

	/**
	 *
	 * <code>attachChildAt</code> attaches a child to this node at an index. This node
	 * becomes the child's parent. The current number of children maintained is
	 * returned.
	 * <br>
	 * If the child already had a parent it is detached from that former parent.
	 *
	 * @param child
	 *            the child to attach to this node.
	 * @return the number of children maintained by this node.
	 */
	public function attachChildAt(child:Spatial, index:Int):Void
	{
		var cParent:Node = child.parent;
		if (cParent != this && child != this)
		{
			if (cParent != null)
			{
				cParent.detachChild(child);
			}
			
			children.insert(index, child);

			child.parent = this;
			child.setTransformRefresh();
			child.setLightListRefresh();

			#if debug
			Logger.log(child.toString() + " attached to " + this.toString());
			#end
		}
	}

	/**
	 * <code>detachChild</code> removes a given child from the node's list.
	 * This child will no longe be maintained.
	 *
	 * @param child
	 *            the child to remove.
	 * @return the index the child was at. -1 if the child was not in the list.
	 */
	public function detachChild(child:Spatial):Int
	{
		if (child.parent == this)
		{
			var index:Int = children.indexOf(child);
			if (index != -1)
			{
				detachChildAt(index);
			}
			return index;
		}

		return -1;
	}


	/**
	 * <code>detachChild</code> removes a given child from the node's list.
	 * This child will no longe be maintained. Only the first child with a
	 * matching name is removed.
	 *
	 * @param childName
	 *            the child to remove.
	 * @return the index the child was at. -1 if the child was not in the list.
	 */
	public function detachChildByName(childName:String):Int
	{
		for (i in 0...numChildren)
		{
			var child:Spatial = children[i];
			if (childName == child.name)
			{
				detachChildAt(i);
				return i;
			}
		}

		return -1;
	}

	/**
	 *
	 * <code>detachChildAt</code> removes a child at a given index. That child
	 * is returned for saving purposes.
	 *
	 * @param index
	 *            the index of the child to be removed.
	 * @return the child at the supplied index.
	 */
	public function detachChildAt(index:Int):Spatial
	{
		var child:Spatial = children[index];
		children.splice(index, 1);

		if (child != null)
		{
			child.parent = null;

			#if debug
			Logger.log(child.toString() + " removed from " + this.toString());
			#end

			// since a child with a bound was detached;
			// our own bound will probably change.
			setBoundRefresh();

			// our world transform no longer influences the child.
			// XXX: Not neccessary? Since child will have transform updated
			// when attached anyway.
			child.setTransformRefresh();
			// lights are also inherited from parent
			child.setLightListRefresh();
		}
		return child;
	}

	/**
	 *
	 * <code>detachAllChildren</code> removes all children attached to this
	 * node.
	 */
	public function detachAllChildren():Void
	{
		var i:Int = children.length;
		while (--i >= 0)
		{
			var child:Spatial = children[i];
			if (child != null)
			{
				child.parent = null;

				#if debug
				Logger.log(child.toString() + " removed from " + this.toString());
				#end

				child.setTransformRefresh();
				child.setLightListRefresh();
			}
		}

		children = [];

		setBoundRefresh();

		#if debug
		Logger.log("All children removed from " + this.toString());
		#end
	}

	/**
	 * <code>getChildIndex</code> returns the index of the given spatial
	 * in this node's list of children.
	 * @param sp
	 *          The spatial to look up
	 * @return
	 *          The index of the spatial in the node's children, or -1
	 *          if the spatial is not attached to this node
	 */
	public function getChildIndex(sp:Spatial):Int
	{
		return children.indexOf(sp);
	}

	/**
	 * More efficient than e.g detaching and attaching as no updates are needed.
	 * @param index1
	 * @param index2
	 */
	public function swapChildren(index1:Int, index2:Int):Void
	{
		var child1:Spatial = children[index1];
		children[index1] = children[index2];
		children[index2] = child1;
	}

	/**
	 *
	 * <code>getChild</code> returns a child at a given index.
	 *
	 * @param i
	 *            the index to retrieve the child from.
	 * @return the child at a specified index.
	 */
	public function getChildAt(index:Int):Spatial
	{
		return children[index];
	}

	/**
	 * <code>getChild</code> returns the first child found with exactly the
	 * given name (case sensitive.)
	 *
	 * @param name
	 *            the name of the child to retrieve. If null, we'll return null.
	 * @return the child if found, or null.
	 */
	public function getChildByName(name:String):Spatial
	{
		for (child in children)
		{
			if (child.name == name)
			{
				return child;
			}
			else if (Std.is(child,Node))
			{
				var node:Node = cast(child,Node);
				var out:Spatial = node.getChildByName(name);
				if (out != null)
				{
					return out;
				}
			}
		}
		return null;
	}

	/**
	 * determines if the provided Spatial is contained in the children list of
	 * this node.
	 *
	 * @param spat
	 *            the child object to look for.
	 * @return true if the object is contained, false otherwise.
	 */
	public function hasChild(sp:Spatial):Bool
	{
		if (children.contains(sp))
		{
			return true;
		}

		for (child in children)
		{
			if (Std.is(child,Node))
			{
				var node:Node = cast child;
				if (node.hasChild(sp))
				{
					return true;
				}
			}
		}

		return false;
	}
	
	override public function setLodLevel(lod:Int):Void
	{
		super.setLodLevel(lod);
		
		for (child in children)
		{
			child.setLodLevel(lod);
		}
	}

	override public function collideWith(other:Collidable, results:CollisionResults):Int
	{
		var total:Int = 0;
		for (child in children)
		{
			total += child.collideWith(other, results);
		}
		return total;
	}

	override public function setModelBound(bound:BoundingVolume):Void
	{
		for (child in children)
		{
			child.setModelBound(bound != null ? bound.clone() : null);
		}
	}

	override public function updateModelBound():Void
	{
		for (child in children)
		{
			child.updateModelBound();
		}
	}

	override public function depthFirstTraversal(visitor:SceneGraphVisitor):Void
	{
		for (child in children)
		{
			child.depthFirstTraversal(visitor);
		}
		visitor.visit(this);
	}

	override private function breadthFirstTraversalQueue(visitor:SceneGraphVisitor,queue:Array<Spatial>):Void
	{
		for (child in children)
		{
			queue.push(child);
		}
	}

	override public function clone(newName:String, cloneMaterial:Bool = true, result:Spatial = null):Spatial
	{
		var node:Node;
		if (result == null || !Std.is(result,Node))
		{
			node = new Node(newName);
		}
		else
		{
			node = Std.instance(result, Node);
		}

		node = cast super.clone(newName, cloneMaterial, node);

		for (child in children)
		{
			var childClone:Spatial = child.clone(newName, cloneMaterial);
			node.attachChild(childClone);
		}

		return node;
	}

	private inline function get_numChildren():Int
	{
		return children.length;
	}
}

