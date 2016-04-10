package org.angle3d.scene;

import de.polygonal.ds.error.Assert;
import flash.Vector;
import org.angle3d.bounding.BoundingVolume;
import org.angle3d.collision.Collidable;
import org.angle3d.collision.CollisionResults;
import org.angle3d.material.Material;
import org.angle3d.utils.VectorUtil;
import org.angle3d.utils.Logger;

/**
 * Node defines an internal node of a scene graph. The internal
 * node maintains a collection of children and handles merging said children
 * into a single bound to allow for very fast culling of multiple nodes. Node
 * allows for any number of children to be attached.
 *
 */
class Node extends Spatial
{
	public var children:Vector<Spatial> = new Vector<Spatial>();
	public var numChildren(get, null):Int;
	
	/**
     * If this node is a root, this list will contain the current
     * set of children (and children of children) that require 
     * updateLogicalState() to be called as indicated by their
     * requiresUpdate() method.
     */
    private var updateList:Vector<Spatial> = null;
	
	/**
     * False if the update list requires rebuilding.  This is Node.class
     * specific and therefore not included as part of the Spatial update flags.
     * A flag is used instead of nulling the updateList to avoid reallocating
     * a whole list every time the scene graph changes.
     */     
    private var updateListValid:Bool = false;  

	public function new(name:String)
	{
		super(name);
		
		// For backwards compatibility, only clear the "requires
        // update" flag if we are not a subclass of Node.
        // This prevents subclass from silently failing to receive
        // updates when they upgrade.
		setRequiresUpdates(Node != Type.getClass(this)); 
	}
	
	override public function dispose():Void 
	{
		super.dispose();
		
		for (i in 0...children.length)
		{
			children[i].dispose();
		}
		children = null;
		updateList = null;
	}
	
	public function getChildren():Vector<Spatial>
	{
		return children;
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
	
	override private function set_parent(value:Node):Node
	{
		if (this.parent == null && value == null)
		{
			// We were a root before and now we aren't... make sure if
            // we had an updateList then we clear it completely to 
            // avoid holding the dead array.
            updateList = null;
            updateListValid = false;
		}
		return super.set_parent(value);
	}
	
	private function addUpdateChildren(results:Vector<Spatial>):Void
	{
		for (i in 0...children.length)
		{
			var child:Spatial = children[i];
			if (child.requiresUpdates())
			{
				results[results.length] = child;
			}
			
			if (Std.is(child, Node))
			{
				cast(child, Node).addUpdateChildren(results);
			}
		}
	}
	
	/**
     *  Called to invalidate the root node's update list.  This is
     *  called whenever a spatial is attached/detached as well as
     *  when a control is added/removed from a Spatial in a way
     *  that would change state.
     */
    public function invalidateUpdateList():Void
	{
        updateListValid = false;
        if ( parent != null )
		{
			parent.invalidateUpdateList();
        }
    }
	
	private function getUpdateList():Vector<Spatial>
	{
		if (updateListValid)
		{
			return updateList;
		}
		
		if (updateList == null)
		{
			updateList = new Vector<Spatial>();
		}
		else
		{
			updateList.length = 0;
		}
		
		// Build the list
        addUpdateChildren(updateList);
        updateListValid = true;       
        return updateList;  
	}
	
	override public function updateLogicalState(tpf:Float):Void
	{
		super.updateLogicalState(tpf);
		
		// Only perform updates on children if we are the
        // root and then only peform updates on children we
        // know to require updates.
        // So if this isn't the root, abort.
		if (parent != null)
			return;
			
		var list:Vector<Spatial> = getUpdateList();
		var cLength:Int = list.length;
		for (i in 0...cLength)
		{
			list[i].updateLogicalState(tpf);
		}	
	}

	override public function updateGeometricState():Void
	{
		if (refreshFlags == RefreshFlag.NONE) 
		{
            // This branch has no geometric state that requires updates.
            return;
        }
		
		if (needLightListUpdate())
		{
			updateWorldLightList();
		}

		if (needTransformUpdate())
		{
			// combine with parent transforms- same for all spatial subclasses.
			updateWorldTransforms();
		}

		refreshFlags = refreshFlags.remove(RefreshFlag.RF_CHILD_LIGHTLIST);
		
		var childCount:Int = numChildren;
		if (childCount > 0)
		{
			// the important part- make sure child geometric state is refreshed
			// first before updating own world bound. This saves
			// a round-trip later on.
			for (i in 0...childCount)
			{
				children[i].updateGeometricState();
			}
		}

		if (needBoundUpdate())
		{
			updateWorldBound();
		}

		Assert.assert(refreshFlags == RefreshFlag.NONE, "refreshFlags == 0");
	}
	
	override public function getTriangleCount():Int 
	{
		var count:Int = 0;
		for (i in 0...children.length)
		{
			count += children[i].getTriangleCount();
		}
		return count;
	}
	
	override public function getVertexCount():Int 
	{
		var count:Int = 0;
		for (i in 0...children.length)
		{
			count += children[i].getVertexCount();
		}
		return count;
	}

	/**
	 *
	 * `attachChild` attaches a child to this node. This node
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
		if (child == null)
			return;
			
		var cParent:Node = child.parent;
		if (cParent != this && child != this)
		{
			if (cParent != null)
			{
				cParent.detachChild(child);
			}

			child.parent = this;
			children[children.length] = child;

			// XXX: Not entirely correct? Forces bound update up the
			// tree stemming from the attached child. Also forces
			// transform update down the tree-
			child.setTransformRefresh();
			child.setLightListRefresh();

			#if debug
			Logger.log(child.toString() + " attached to " + this.toString());
			#end
			
			invalidateUpdateList();
		}
	}

	/**
	 *
	 * `attachChildAt` attaches a child to this node at an index. This node
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
			
			VectorUtil.insert(children, index, child);

			child.parent = this;
			child.setTransformRefresh();
			child.setLightListRefresh();

			#if debug
			Logger.log(child.toString() + " attached to " + this.toString());
			#end
			
			invalidateUpdateList();
		}
	}

	/**
	 * `detachChild` removes a given child from the node's list.
	 * This child will no longe be maintained.
	 *
	 * @param child
	 *            the child to remove.
	 * @return the index the child was at. -1 if the child was not in the list.
	 */
	public function detachChild(child:Spatial):Int
	{
		if (child == null)
			return -1;
			
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
	 * `detachChild` removes a given child from the node's list.
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
	 * `detachChildAt` removes a child at a given index. That child
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
			
			invalidateUpdateList();
		}
		return child;
	}

	/**
	 *
	 * `detachAllChildren` removes all children attached to this
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

		children.length = 0;

		setBoundRefresh();
		
		invalidateUpdateList();

		#if debug
		Logger.log("All children removed from " + this.toString());
		#end
	}

	/**
	 * `getChildIndex` returns the index of the given spatial
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
	 * `getChild` returns a child at a given index.
	 *
	 * @param i
	 *            the index to retrieve the child from.
	 * @return the child at a specified index.
	 */
	public inline function getChildAt(index:Int):Spatial
	{
		return children[index];
	}

	/**
	 * getChildByName returns the first child found with exactly the
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
		}
		return null;
	}
	
	/**
     * getFirstChildByName returns the first child found with exactly the
     * given name (case sensitive.) This method does a depth first recursive
     * search of all descendants of this node, it will return the first spatial
     * found with a matching name.
     * 
     * @param name
     *            the name of the child to retrieve. If null, we'll return null.
     * @return the child if found, or null.
     */
	public function getFirstChildByName(name:String):Spatial
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
				var out:Spatial = node.getFirstChildByName(name);
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
		if (children.indexOf(sp) != -1)
		{
			return true;
		}

		for (child in children)
		{
			if (Std.is(child,Node) && cast(child,Node).hasChild(sp))
			{
				return true;
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
		
		// optimization: try collideWith BoundingVolume to avoid possibly redundant tests on children
        // number 4 in condition is somewhat arbitrary. When there is only one child, the boundingVolume test is redundant at all. 
        // The idea is when there are few children, it can be too expensive to test boundingVolume first.
		var childCount:Int = children.length;
        if (childCount > 4)
        {
			var bv:BoundingVolume = this.getWorldBound();
		    if (bv == null) 
				return 0;

			// collideWith without CollisionResults parameter used to avoid allocation when possible
			if (bv.collideWithNoResult(other) == 0) 
				return 0;
        }
		
		for (i in 0...childCount)
		{
			total += children[i].collideWith(other, results);
		}
		return total;
	}

	override public function setModelBound(modelBound:BoundingVolume):Void
	{
		for (child in children)
		{
			child.setModelBound(modelBound != null ? modelBound.clone() : null);
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

	override private function breadthFirstTraversalQueue(visitor:SceneGraphVisitor,queue:Vector<Spatial>):Void
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
		
		// Reset the fields of the clone that should be in a 'new' state.
        node.updateList = null;
        node.updateListValid = false; // safe because parent is nulled out in super.clone()

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

