package org.angle3d.renderer.queue;

import flash.Lib;
import org.angle3d.renderer.Camera;
import org.angle3d.renderer.RenderManager;
import org.angle3d.scene.Geometry;
import de.polygonal.ds.error.Assert;

/**
 * <code>RenderQueue</code> is used to queue up and sort
 * {@link Geometry geometries} for rendering.
 *
 */
class RenderQueue
{
	private var opaqueList:GeometryList;
	private var guiList:GeometryList;
	private var transparentList:GeometryList;
	private var translucentList:GeometryList;
	private var skyList:GeometryList;
	private var shadowRecv:GeometryList;
	private var shadowCast:GeometryList;

	/**
	 * Creates a new RenderQueue, the default {@link GeometryComparator comparators}
	 * are used for all {@link GeometryList geometry lists}.
	 */
	public function new()
	{
		opaqueList = new GeometryList(new OpaqueComparator());
		guiList = new GeometryList(new GuiComparator());
		transparentList = new GeometryList(new TransparentComparator());
		translucentList = new GeometryList(new TransparentComparator());
		skyList = new GeometryList(new NullComparator());
		shadowRecv = new GeometryList(new OpaqueComparator());
		shadowCast = new GeometryList(new OpaqueComparator());
	}

	/**
	 *  Sets a different geometry comparator for the specified bucket, one
	 *  of Gui, Opaque, Sky, or Transparent.  The GeometryComparators are
	 *  used to sort the accumulated list of geometries before actual rendering
	 *  occurs.
	 *
	 *  <p>The most significant comparator is the one for the transparent
	 *  bucket since there is no correct way to sort the transparent bucket
	 *  that will handle all geometry all the time.  In certain cases, the
	 *  application may know the best way to sort and now has the option of
	 *  configuring a specific implementation.</p>
	 *
	 *  <p>The default comparators are:</p>
	 *  <ul>
	 *  <li>Bucket.Opaque: {@link org.angle3d.renderer.queue.OpaqueComparator} which sorts
	 *                     by material first and front to back within the same material.
	 *  <li>Bucket.Transparent: {@link org.angle3d.renderer.queue.TransparentComparator} which
	 *                     sorts purely back to front by leading bounding edge with no material sort.
	 *  <li>Bucket.Translucent: {@link org.angle3d.renderer.queue.TransparentComparator} which
	 *                     sorts purely back to front by leading bounding edge with no material sort. this bucket is rendered after post processors.
	 *  <li>Bucket.Sky: {@link org.angle3d.renderer.queue.NullComparator} which does no sorting
	 *                     at all.
	 *  <li>Bucket.Gui: {@link org.angle3d.renderer.queue.GuiComparator} sorts geometries back to
	 *                     front based on their Z values.
	 */
	public function setGeometryComparator(bucket:QueueBucket, c:GeometryComparator):Void
	{
		switch (bucket)
		{
			case QueueBucket.Gui:
				guiList = new GeometryList(c);
			case QueueBucket.Opaque:
				opaqueList = new GeometryList(c);
			case QueueBucket.Sky:
				skyList = new GeometryList(c);
			case QueueBucket.Transparent:
				transparentList = new GeometryList(c);
			case QueueBucket.Translucent:
				translucentList = new GeometryList(c);
			default:
				Assert.assert(false, "Unknown bucket type: " + bucket);
		}
	}

	/**
	 *  Returns the current GeometryComparator used by the specified bucket,
	 *  one of Gui, Opaque, Sky, Transparent, or Translucent.
	 */
	public function getGeometryComparator(bucket:QueueBucket):GeometryComparator
	{
		switch (bucket)
		{
			case QueueBucket.Gui:
				return guiList.getComparator();
			case QueueBucket.Opaque:
				return opaqueList.getComparator();
			case QueueBucket.Sky:
				return skyList.getComparator();
			case QueueBucket.Transparent:
				return transparentList.getComparator();
			case QueueBucket.Translucent:
				return translucentList.getComparator();
			default:
				Assert.assert(false, "Unknown bucket type: " + bucket);
		}
		return null;
	}

	/**
	 * Adds a geometry to a shadow bucket.
	 * Note that this operation is done automatically by the
	 * {@link RenderManager}. {@link SceneProcessor}s that handle
	 * shadow rendering should fetch the queue by using
	 * {@link #getShadowQueueContent(org.angle3d.renderer.queue.RenderQueue.ShadowMode) },
	 * by default no action is taken on the shadow queues.
	 *
	 * @param g The geometry to add
	 * @param shadBucket The shadow bucket type, if it is
	 * {@link ShadowMode#CastAndReceive}, it is added to both the cast
	 * and the receive buckets.
	 */
	public function addToShadowQueue(g:Geometry, shadeMode:ShadowMode):Void
	{
		switch (shadeMode)
		{
			case ShadowMode.Cast:
				shadowCast.add(g);
			case ShadowMode.Receive:
				shadowRecv.add(g);
			case ShadowMode.CastAndReceive:
				shadowCast.add(g);
				shadowRecv.add(g);
			case ShadowMode.Inherit,ShadowMode.Off:
				Lib.trace("Inherit or Off");
			//default:
				//Assert.assert(false, "Unrecognized shadow bucket type: " + shadeMode);
		}
	}

	/**
	 * Adds a geometry to the given bucket.
	 * The {@link RenderManager} automatically handles this task
	 * when flattening the scene graph. The bucket to add
	 * the geometry is determined by {@link Geometry#getQueueBucket() }.
	 *
	 * @param g  The geometry to add
	 * @param bucket The bucket to add to, usually
	 * {@link Geometry#getQueueBucket() }.
	 */
	public function addToQueue(g:Geometry, bucket:QueueBucket):Void
	{
		switch (bucket)
		{
			case QueueBucket.Gui:
				guiList.add(g);
			case QueueBucket.Opaque:
				opaqueList.add(g);
			case QueueBucket.Sky:
				skyList.add(g);
			case QueueBucket.Transparent:
				transparentList.add(g);
			case QueueBucket.Translucent:
				translucentList.add(g);
			default:
				#if debug
				Assert.assert(false, "Unknown bucket type: " + bucket);
				#end
		}
	}

	/**
	 *
	 * @param shadBucket
	 * @return
	 */
	public function getShadowQueueContent(shadeMode:ShadowMode):GeometryList
	{
		switch (shadeMode)
		{
			case ShadowMode.Cast:
				return shadowCast;
			case ShadowMode.Receive:
				return shadowRecv;
			default:
				Assert.assert(false, "Only Cast or Receive are allowed");
				return null;
		}
	}

	private function renderGeometryList(list:GeometryList, rm:RenderManager, cam:Camera, clear:Bool = true):Void
	{
		if (list.isEmpty)
			return;
			
		//select camera for sorting
		list.setCamera(cam);
		list.sort();

		var size:Int = list.size;
		for (i in 0...size)
		{
			var obj:Geometry = list.getGeometry(i);

			#if debug
			Assert.assert(obj != null, "list.getGeometry(" + i + ") is not null");
			#end

			rm.renderGeometry(obj);
			obj.queueDistance = Math.NEGATIVE_INFINITY;
		}

		if (clear)
		{
			list.clear();
		}
	}

	public function renderShadowQueue(list:GeometryList, rm:RenderManager, cam:Camera, clear:Bool = true):Void
	{
		renderGeometryList(list, rm, cam, clear);
	}

	public function renderShadowQueueByShadowMode(mode:ShadowMode, rm:RenderManager, cam:Camera, clear:Bool = true):Void
	{
		switch (mode)
		{
			case ShadowMode.Cast:
				renderGeometryList(shadowCast, rm, cam, clear);
			case ShadowMode.Receive:
				renderGeometryList(shadowRecv, rm, cam, clear);
			default:
				Assert.assert(false, "Unexpected shadow mode: " + mode);
		}
	}

	public function isQueueEmpty(bucket:QueueBucket):Bool
	{
		switch (bucket)
		{
			case QueueBucket.Gui:
				return guiList.isEmpty;
			case QueueBucket.Opaque:
				return opaqueList.isEmpty;
			case QueueBucket.Sky:
				return skyList.isEmpty;
			case QueueBucket.Transparent:
				return transparentList.isEmpty;
			case QueueBucket.Translucent:
				return translucentList.isEmpty;
			default:
				Assert.assert(false, "Unsupported bucket type: " + bucket);
				return true;
		}
	}

	public function renderQueue(bucket:QueueBucket, rm:RenderManager, cam:Camera, clear:Bool = true):Void
	{
		switch (bucket)
		{
			case QueueBucket.Gui:
				renderGeometryList(guiList, rm, cam, clear);
			case QueueBucket.Opaque:
				renderGeometryList(opaqueList, rm, cam, clear);
			case QueueBucket.Sky:
				renderGeometryList(skyList, rm, cam, clear);
			case QueueBucket.Transparent:
				renderGeometryList(transparentList, rm, cam, clear);
			case QueueBucket.Translucent:
				renderGeometryList(translucentList, rm, cam, clear);
			default:
				Assert.assert(false, "Unsupported bucket type: " + bucket);
		}
	}

	public function clear():Void
	{
		opaqueList.clear();
		guiList.clear();
		transparentList.clear();
		translucentList.clear();
		skyList.clear();
		shadowCast.clear();
		shadowRecv.clear();
	}
}

