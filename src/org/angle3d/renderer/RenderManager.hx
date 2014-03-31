package org.angle3d.renderer;

import flash.display3D.Program3D;
import flash.Vector;
import org.angle3d.light.Light;
import org.angle3d.light.LightList;
import org.angle3d.light.LightType;
import org.angle3d.material.Material;
import org.angle3d.material.post.SceneProcessor;
import org.angle3d.material.shader.Shader;
import org.angle3d.material.shader.ShaderType;
import org.angle3d.material.shader.Uniform;
import org.angle3d.material.shader.UniformBindingManager;
import org.angle3d.material.technique.Technique;
import org.angle3d.math.Matrix4f;
import org.angle3d.math.PlaneSide;
import org.angle3d.math.Rect;
import org.angle3d.math.Vector3f;
import org.angle3d.renderer.queue.GeometryList;
import org.angle3d.renderer.queue.QueueBucket;
import org.angle3d.renderer.queue.RenderQueue;
import org.angle3d.renderer.queue.ShadowMode;
import org.angle3d.scene.CullHint;
import org.angle3d.scene.Geometry;
import org.angle3d.scene.mesh.Mesh;
import org.angle3d.scene.Node;
import org.angle3d.scene.Spatial;
import org.angle3d.utils.Assert;
using org.angle3d.utils.ArrayUtil;


/**
 * <code>RenderManager</code> is a high-level rendering interface that is
 * above the Renderer implementation. RenderManager takes care
 * of rendering the scene graphs attached to each viewport and
 * handling SceneProcessors.
 *
 * @see SceneProcessor
 * @see ViewPort
 * @see Spatial
 */
class RenderManager
{
	private var mRenderer:IRenderer;
	private var mUniformBindingManager:UniformBindingManager;

	private var mPreViewPorts:Array<ViewPort>;
	private var mViewPorts:Array<ViewPort>;
	private var mPostViewPorts:Array<ViewPort>;

	private var mCamera:Camera;

	private var mViewX:Int;
	private var mViewY:Int;
	private var mViewWidth:Int;
	private var mViewHeight:Int;

	private var mOrthoMatrix:Matrix4f;

	private var mHandleTranlucentBucket:Bool;

	private var mForcedMaterial:Material;

	/**
	 * Create a high-level rendering interface over the
	 * low-level rendering interface.
	 * @param renderer
	 */
	public function new(renderer:IRenderer)
	{
		mRenderer = renderer;
		_init();
	}

	private function _init():Void
	{
		mUniformBindingManager = new UniformBindingManager();

		mPreViewPorts = new Array<ViewPort>();
		mViewPorts = new Array<ViewPort>();
		mPostViewPorts = new Array<ViewPort>();

		mOrthoMatrix = new Matrix4f();

		mHandleTranlucentBucket = false;
	}

	public function setForcedMaterial(mat:Material):Void
	{
		mForcedMaterial = mat;
	}

	public function clearForcedMaterial():Void
	{
		mForcedMaterial = null;
	}

	/**
	 * Returns the pre ViewPort with the given name.
	 *
	 * @param viewName The name of the pre ViewPort to look up
	 * @return The ViewPort, or null if not found.
	 *
	 * @see #createPreView(String, com.jme3.renderer.Camera)
	 */
	public function getPreView(viewName:String):ViewPort
	{
		var length:Int = mPreViewPorts.length;
		for (i in 0...length)
		{
			if (mPreViewPorts[i].name == viewName)
			{
				return mPreViewPorts[i];
			}
		}
		return null;
	}

	/**
	 * Removes the specified pre ViewPort.
	 *
	 * @param view The pre ViewPort to remove
	 * @return True if the ViewPort was removed successfully.
	 *
	 * @see #createPreView(String, com.jme3.renderer.Camera)
	 */
	public function removePreView(view:ViewPort):Bool
	{
		return mPreViewPorts.remove(view);
	}
	
	public function removePreViewByName(name:String):Bool
	{
		for (i in 0...mPreViewPorts.length)
		{
            if (mPreViewPorts[i].name == name)
			{
                removePreView(mPreViewPorts[i]);
                return true;
            }
        }
        return false;
	}

	/**
	 * Returns the main ViewPort with the given name.
	 *
	 * @param viewName The name of the main ViewPort to look up
	 * @return The ViewPort, or null if not found.
	 *
	 * @see #createMainView(String, com.jme3.renderer.Camera)
	 */
	public function getMainView(viewName:String):ViewPort
	{
		var length:Int = mViewPorts.length;
		for (i in 0...length)
		{
			if (mViewPorts[i].name == viewName)
			{
				return mViewPorts[i];
			}
		}
		return null;
	}

	/**
	 * Removes the main ViewPort with the specified name.
	 *
	 * @param view The main ViewPort name to remove
	 * @return True if the ViewPort was removed successfully.
	 *
	 * @see #createMainView(String, com.jme3.renderer.Camera)
	 */
	public function removeMainViewByName(viewName:String):Bool
	{
		var length:Int = mViewPorts.length;
		for (i in 0...length)
		{
			if (mViewPorts[i].name == viewName)
			{
				mViewPorts.splice(i, 1);
				return true;
			}
		}
		return false;
	}

	/**
	 * Removes the specified main ViewPort.
	 *
	 * @param view The main ViewPort to remove
	 * @return True if the ViewPort was removed successfully.
	 *
	 * @see #createMainView(String, com.jme3.renderer.Camera)
	 */
	public function removeMainView(view:ViewPort):Bool
	{
		return mViewPorts.remove(view);
	}

	/**
	 * Returns the post ViewPort with the given name.
	 *
	 * @param viewName The name of the post ViewPort to look up
	 * @return The ViewPort, or null if not found.
	 *
	 * @see #createPostView(String, com.jme3.renderer.Camera)
	 */
	public function getPostView(viewName:String):ViewPort
	{
		var length:Int = mPostViewPorts.length;
		for (i in 0...length)
		{
			if (mPostViewPorts[i].name == viewName)
			{
				return mPostViewPorts[i];
			}
		}
		return null;
	}

	/**
	 * Removes the post ViewPort with the specified name.
	 *
	 * @param view The post ViewPort name to remove
	 * @return True if the ViewPort was removed successfully.
	 *
	 * @see #createPostView(String, com.jme3.renderer.Camera)
	 */
	public function removePostViewByName(viewName:String):Bool
	{
		var pLength:Int = mPostViewPorts.length;
		for (i in 0...pLength)
		{
			if (mPostViewPorts[i].name == viewName)
			{
				mPostViewPorts.splice(i, 1);
				return true;
			}
		}
		return false;
	}

	/**
	 * Removes the specified pre ViewPort.
	 *
	 * @param view The pre ViewPort to remove
	 * @return True if the ViewPort was removed successfully.
	 *
	 * @see #createPreView(String, com.jme3.renderer.Camera)
	 */
	public function removePostView(view:ViewPort):Bool
	{
		return mPostViewPorts.remove(view);
	}

	/**
	 * Returns a read-only list of all pre ViewPorts
	 * @return a read-only list of all pre ViewPorts
	 * @see #createPreView(String, com.jme3.renderer.Camera)
	 */
	public function getPreViews():Array<ViewPort>
	{
		return mPreViewPorts;
	}

	/**
	 * Returns a read-only list of all main ViewPorts
	 * @return a read-only list of all main ViewPorts
	 * @see #createMainView(String, com.jme3.renderer.Camera)
	 */
	public function getMainViews():Array<ViewPort>
	{
		return mViewPorts;
	}

	/**
	 * Returns a read-only list of all post ViewPorts
	 * @return a read-only list of all post ViewPorts
	 * @see #createPostView(String, com.jme3.renderer.Camera)
	 */
	public function getPostViews():Array<ViewPort>
	{
		return mPostViewPorts;
	}

	/**
	 * Creates a new pre ViewPort, to display the given camera's content.
	 * <p>
	 * The view will be processed before the main and post viewports.
	 */
	public function createPreView(viewName:String, cam:Camera):ViewPort
	{
		var vp:ViewPort = new ViewPort(viewName, cam);
		mPreViewPorts.push(vp);
		return vp;
	}

	/**
	 * Creates a new main ViewPort, to display the given camera's content.
	 * <p>
	 * The view will be processed before the post viewports but after
	 * the pre viewports.
	 */
	public function createMainView(viewName:String, cam:Camera):ViewPort
	{
		var vp:ViewPort = new ViewPort(viewName, cam);
		mViewPorts.push(vp);
		return vp;
	}

	/**
	 * Creates a new post ViewPort, to display the given camera's content.
	 * <p>
	 * The view will be processed after the pre and main viewports.
	 */
	public function createPostView(viewName:String, cam:Camera):ViewPort
	{
		var vp:ViewPort = new ViewPort(viewName, cam);
		mPostViewPorts.push(vp);
		return vp;
	}

	private function resizeViewPort(vp:ViewPort, w:Int, h:Int):Void
	{
		if (vp.frameBuffer == null)
		{
			vp.camera.resize(w, h, true);
		}

		var processors:Vector<SceneProcessor> = vp.processors;
		var processor:SceneProcessor;
		for (processor in processors)
		{
			if (!processor.isInitialized)
			{
				processor.initialize(this, vp);
			}
			else
			{
				processor.reshape(vp, w, h);
			}
		}
	}

	/**
	 * Internal use only.
	 * Updates the resolution of all on-screen cameras to match
	 * the given width and height.
	 */
	public function resize(w:Int, h:Int):Void
	{
		var vp:ViewPort;
		var size:Int = mPreViewPorts.length;
		for (i in 0...size)
		{
			vp = mPreViewPorts[i];
			resizeViewPort(vp, w, h);
		}

		size = mViewPorts.length;
		for (i in 0...size)
		{
			vp = mViewPorts[i];
			resizeViewPort(vp, w, h);
		}

		size = mPostViewPorts.length;
		for (i in 0...size)
		{
			vp = mPostViewPorts[i];
			resizeViewPort(vp, w, h);
		}
	}

	public function updateShaderBinding(shader:Shader):Void
	{
		updateUniformBindings(shader.getUniformList(ShaderType.VERTEX).bindList);
		updateUniformBindings(shader.getUniformList(ShaderType.FRAGMENT).bindList);
	}

	/**
	 * Internal use only.
	 * Updates the given list of uniforms with {@link UniformBinding uniform bindings}
	 * based on the current world state.
	 */
	 private inline function updateUniformBindings(params:Vector<Uniform>):Void
	{
		mUniformBindingManager.updateUniformBindings(params);
	}

	/**
	 * True if the translucent bucket should automatically be rendered
	 * by the RenderManager.
	 *
	 * @return Whether or not the translucent bucket is rendered.
	 *
	 * @see #setHandleTranslucentBucket(Bool)
	 */
	public function isHandleTranslucentBucket():Bool
	{
		return mHandleTranlucentBucket;
	}

	/**
	 * Enable or disable rendering of the
	 * {@link Bucket#Translucent translucent bucket}
	 * by the RenderManager. The default is enabled.
	 *
	 * @param handleTranslucentBucket Whether or not the translucent bucket should
	 * be rendered.
	 */
	public function setHandleTranslucentBucket(handleTranslucentBucket:Bool):Void
	{
		this.mHandleTranlucentBucket = handleTranslucentBucket;
	}

	/**
	 * Internal use only. Sets the world matrix to use for future
	 * rendering. This has no effect unless objects are rendered manually
	 * using {@link Material#render(com.jme3.scene.Geometry, com.jme3.renderer.RenderManager) }.
	 * Using {@link #renderGeometry(com.jme3.scene.Geometry) } will
	 * override this value.
	 *
	 * @param mat The world matrix to set
	 */
	public function setWorldMatrix(mat:Matrix4f):Void
	{
		mUniformBindingManager.setWorldMatrix(mat);
	}

	/**
	 * Renders the given geometry.
	 * <p>
	 * First the proper world matrix is set, if
	 * the geometry's {@link Geometry#setIgnoreTransform(Bool) ignore transform}
	 * feature is enabled, the identity world matrix is used, otherwise, the
	 * geometry's {@link Geometry#getWorldMatrix() world transform matrix} is used.
	 * <p>
	 * Once the world matrix is applied, the proper material is chosen for rendering.
	 * If a {@link #setForcedMaterial(com.jme3.material.Material) forced material} is
	 * set_on this RenderManager, then it is used for rendering the geometry,
	 * otherwise, the {@link Geometry#getMaterial() geometry's material} is used.
	 * <p>
	 * If a {@link #setForcedTechnique(String) forced technique} is
	 * set_on this RenderManager, then it is selected automatically
	 * on the geometry's material and is used for rendering. Otherwise, one
	 * of the {@link MaterialDef#getDefaultTechniques() default techniques} is
	 * used.
	 * <p>
	 * If a {@link #setForcedRenderState(com.jme3.material.RenderState) forced
	 * render state} is set_on this RenderManager, then it is used
	 * for rendering the material, and the material's own render state is ignored.
	 * Otherwise, the material's render state is used as intended.
	 *
	 * @param g The geometry to render
	 *
	 * @see Technique
	 * @see RenderState
	 * @see Material#selectTechnique(String, com.jme3.renderer.RenderManager)
	 * @see Material#render(com.jme3.scene.Geometry, com.jme3.renderer.RenderManager)
	 */
	public function renderGeometry(geom:Geometry):Void
	{
		//没有模型数据，忽略
		var mesh:Mesh = geom.getMesh();
		if (mesh == null)
			return;

		if (geom.isIgnoreTransform())
		{
			setWorldMatrix(Matrix4f.IDENTITY);
		}
		else
		{
			setWorldMatrix(geom.getWorldMatrix());
		}

		var mat:Material;
		//强制材质不为空时，需使用它
		if (mForcedMaterial != null)
		{
			mat = mForcedMaterial;
		}
		else
		{
			mat = geom.getMaterial();
		}

		mat.render(geom, this);

	}

	/**
	 * Renders the given GeometryList.
	 * <p>
	 * For every geometry in the list, the
	 * {@link #renderGeometry(com.jme3.scene.Geometry) } method is called.
	 *
	 * @param gl The geometry list to render.
	 *
	 * @see GeometryList
	 * @see #renderGeometry(com.jme3.scene.Geometry)
	 */
	public function renderGeometryList(gl:GeometryList):Void
	{
		var size:Int = gl.size;
		for (i in 0...size)
		{
			renderGeometry(gl.getGeometry(i));
		}
	}

	/**
	 * TODO还未实现
	 * If a spatial is not inside the eye frustum, it
	 * is still rendered in the shadow frustum (shadow casting queue)
	 * through this recursive method.
	 */
	private function renderShadow(s:Spatial, rq:RenderQueue):Void
	{
		if (Std.is(s,Node))
		{
			var n:Node = Std.instance(s, Node);
			var children:Vector<Spatial> = n.children;
			var length:Int = children.length;
			for (i in 0...length)
			{
				renderShadow(children[i], rq);
			}
		}
		else if (Std.is(s,Geometry))
		{
			var gm:Geometry = Std.instance(s, Geometry);

			var shadowMode:ShadowMode = s.shadowMode;
			if (shadowMode != ShadowMode.Off && shadowMode != ShadowMode.Receive)
			{
				//forcing adding to shadow cast mode, culled objects doesn't have to be in the receiver queue
				rq.addToShadowQueue(gm, ShadowMode.Cast);
			}
		}
	}

	/**
	 * Flattens the given scene graph into the ViewPort's RenderQueue,
	 * checking for culling as the call goes down the graph recursively.
	 * <p>
	 * First, the scene is checked for culling based on the <code>Spatial</code>s
	 * {@link Spatial#setCullHint(com.jme3.scene.Spatial.CullHint) cull hint},
	 * if the camera frustum contains the scene, then this method is recursively
	 * called on its children.
	 * <p>
	 * When the scene's leaves or {@link Geometry geometries} are reached,
	 * they are each enqueued into the
	 * {@link ViewPort#getQueue() ViewPort's render queue}.
	 * <p>
	 * In addition to enqueuing the visible geometries, this method
	 * also scenes which cast or receive shadows, by putting them into the
	 * RenderQueue's
	 * {@link RenderQueue#addToShadowQueue(com.jme3.scene.Geometry, com.jme3.renderer.queue.RenderQueue.ShadowMode)
	 * shadow queue}. Each Spatial which has its
	 * {@link Spatial#setShadowMode(com.jme3.renderer.queue.RenderQueue.ShadowMode) shadow mode}
	 * set_to not off, will be put into the appropriate shadow queue, note that
	 * this process does not check for frustum culling on any
	 * {@link ShadowMode#Cast shadow casters}, as they don't have to be
	 * in the eye camera frustum to cast shadows on objects that are inside it.
	 *
	 * @param scene The scene to flatten into the queue
	 * @param vp The ViewPort provides the {@link ViewPort#getCamera() camera}
	 * used for culling and the {@link ViewPort#getQueue() queue} used to
	 * contain the flattened scene graph.
	 */
	public function renderScene(scene:Spatial, vp:ViewPort):Void
	{
		if (!scene.visible)
			return;

		if (scene.parent == null)
		{
			vp.camera.planeState = PlaneSide.None;
		}

		// check culling first.
		if (!scene.checkCulling(vp.camera))
		{
			// move on to shadow-only render
			if ((scene.shadowMode != ShadowMode.Off || 
				Std.is(scene, Node)) && 
				scene.cullHint != CullHint.Always)
			{
				renderShadow(scene, vp.renderQueue);
			}
			return;
		}

		scene.runControlRender(this, vp);

		if (Std.is(scene,Node))
		{
			//recurse for all children
			var n:Node = Std.instance(scene, Node);

			var children:Vector<Spatial> = n.children;
			//saving cam state for culling
			var camState:Int = vp.camera.planeState;
			var cLength:Int = children.length;
			for (i in 0...cLength)
			{
				//restoring cam state before proceeding children recusively
				vp.camera.planeState = camState;
				renderScene(children[i], vp);
			}
		}
		else if (Std.is(scene,Geometry))
		{
			// add to the render queue
			var gm:Geometry = Std.instance(scene, Geometry);

			Assert.assert(gm.getMaterial() != null, "No material is set_for Geometry: " + gm.name);

			vp.renderQueue.addToQueue(gm, gm.queueBucket);

			//add to shadow queue if needed
			var shadowMode:ShadowMode = gm.shadowMode;
			if (shadowMode != ShadowMode.Off)
			{
				vp.renderQueue.addToShadowQueue(gm, shadowMode);
			}
		}
	}

	/**
	 * Returns the camera currently used for rendering.
	 * <p>
	 * The camera can be set_with {@link #setCamera(com.jme3.renderer.Camera, Bool) }.
	 *
	 * @return the camera currently used for rendering.
	 */
	public function getCamera():Camera
	{
		return mCamera;
	}

	/**
	 * The renderer implementation used for rendering operations.
	 *
	 * @return The renderer implementation
	 *
	 * @see #RenderManager(com.jme3.renderer.Renderer)
	 * @see Renderer
	 */
	public function getRenderer():IRenderer
	{
		return mRenderer;
	}

	/**
	 * Flushes the ViewPort's {@link ViewPort#getQueue() render queue}
	 * by rendering each of its visible buckets.
	 * By default the queues will automatically be cleared after rendering,
	 * so there's no need to clear them manually.
	 *
	 * @param vp The ViewPort of which the queue will be flushed
	 *
	 * @see RenderQueue#renderQueue(com.jme3.renderer.queue.RenderQueue.Bucket, com.jme3.renderer.RenderManager, com.jme3.renderer.Camera)
	 * @see #renderGeometryList(com.jme3.renderer.queue.GeometryList)
	 */
	public function flushQueue(vp:ViewPort):Void
	{
		renderViewPortQueues(vp, true);
	}

	/**
	 * Clears the queue of the given ViewPort.
	 * Simply calls {@link RenderQueue#clear() } on the ViewPort's
	 * {@link ViewPort#getQueue() render queue}.
	 *
	 * @param vp The ViewPort of which the queue will be cleared.
	 *
	 * @see RenderQueue#clear()
	 * @see ViewPort#getQueue()
	 */
	public function clearQueue(vp:ViewPort):Void
	{
		vp.renderQueue.clear();
	}

	/**
	 * Render the given viewport queues.
	 * <p>
	 * Changes the {@link Renderer#setDepthRange(float, float) depth range}
	 * appropriately as expected by each queue and then calls
	 * {@link RenderQueue#renderQueue(com.jme3.renderer.queue.RenderQueue.Bucket, com.jme3.renderer.RenderManager, com.jme3.renderer.Camera, Bool) }
	 * on the queue. Makes sure to restore the depth range to [0, 1]
	 * at the end of the call.
	 * Note that the {@link Bucket#Translucent translucent bucket} is NOT
	 * rendered by this method. Instead the user should call
	 * {@link #renderTranslucentQueue(com.jme3.renderer.ViewPort) }
	 * after this call.
	 *
	 * @param vp the viewport of which queue should be rendered
	 * @param flush If true, the queues will be cleared after
	 * rendering.
	 *
	 * @see RenderQueue
	 * @see #renderTranslucentQueue(com.jme3.renderer.ViewPort)
	 */
	private function renderViewPortQueues(vp:ViewPort, flush:Bool):Void
	{
		var queue:RenderQueue = vp.renderQueue;
		var cam:Camera = vp.camera;

		// render the sky, with depth range set_to the farthest
		//首先绘制天空体
		if (!queue.isQueueEmpty(QueueBucket.Sky))
		{
			queue.renderQueue(QueueBucket.Sky, this, cam, flush);
		}

		// render opaque objects with default depth range
		// opaque objects are sorted front-to-back, reducing overdraw
		//不透明物体按从前向后排序，减少重绘
		queue.renderQueue(QueueBucket.Opaque, this, cam, flush);

		// transparent objects are last because they require blending with the
		// rest of the scene's objects. Consequently, they are sorted
		// back-to-front.
		//透明物体按从后向前排序
		if (!queue.isQueueEmpty(QueueBucket.Transparent))
		{
			queue.renderQueue(QueueBucket.Transparent, this, cam, flush);
		}
		
		if (!queue.isQueueEmpty(QueueBucket.Translucent))
		{
			queue.renderQueue(QueueBucket.Translucent, this, cam, flush);
		}

		var isParallelProjection:Bool = cam.parallelProjection;

		//绘制GUI
		if (!queue.isQueueEmpty(QueueBucket.Gui))
		{
			//GUI需要使用正交矩阵
			setCamera(cam, true);
			queue.renderQueue(QueueBucket.Gui, this, cam, flush);
			//恢复原来的矩阵类型
			setCamera(cam, isParallelProjection);
		}
	}

	/**
	 * Renders the {@link Bucket#Translucent translucent queue} on the viewPort.
	 * <p>
	 * This call does nothing unless {@link #setHandleTranslucentBucket(Bool) }
	 * is set_to true. This method clears the translucent queue after rendering
	 * it.
	 *
	 * @param vp The viewport of which the translucent queue should be rendered.
	 *
	 * @see #renderViewPortQueues(com.jme3.renderer.ViewPort, Bool)
	 * @see #setHandleTranslucentBucket(Bool)
	 */
	public function renderTranslucentQueue(vp:ViewPort):Void
	{
		var rq:RenderQueue = vp.renderQueue;
		if (!rq.isQueueEmpty(QueueBucket.Translucent) && mHandleTranlucentBucket)
		{
			rq.renderQueue(QueueBucket.Translucent, this, vp.camera, true);
		}
	}

	private function setViewPort(cam:Camera):Void
	{
		// this will make sure to update viewport only if needed
		if (cam != this.mCamera || cam.isViewportChanged())
		{
			var rect:Rect = cam.viewPortRect;

			mViewX = Std.int(rect.left * cam.width);
			mViewY = Std.int(rect.bottom * cam.height);
			mViewWidth = Std.int(rect.width * cam.width);
			mViewHeight = Std.int(rect.height * cam.height);

			mUniformBindingManager.setViewPort(mViewX, mViewY, mViewWidth, mViewHeight);
			mRenderer.setViewPort(mViewX, mViewY, mViewWidth, mViewHeight);
			//mRenderer.setClipRect(mViewX, mViewY, mViewWidth, mViewHeight);

			cam.clearViewportChanged();
			this.mCamera = cam;
		}

		mOrthoMatrix.makeIdentity();
		mOrthoMatrix.setTranslation(new Vector3f(-1, -1, 0));
		mOrthoMatrix.setScale(new Vector3f(2 / cam.width, 2 / cam.height, 0));
	}

	private function setViewProjection(cam:Camera, ortho:Bool):Void
	{
		if (ortho)
		{
			mUniformBindingManager.setCamera(cam, Matrix4f.IDENTITY, mOrthoMatrix, mOrthoMatrix);
		}
		else
		{
			mUniformBindingManager.setCamera(cam, cam.getViewMatrix(), cam.getProjectionMatrix(), cam.getViewProjectionMatrix());
		}
	}

	/**
	 * set_the camera to use for rendering.
	 * <p>
	 * First, the camera's
	 * {@link Camera#setViewPort(float, float, float, float) view port parameters}
	 * are applied. Then, the camera's {@link Camera#getViewMatrix() view} and
	 * {@link Camera#getProjectionMatrix() projection} matrices are set
	 * on the renderer. If <code>ortho</code> is <code>true</code>, then
	 * instead of using the camera's view and projection matrices, an ortho
	 * matrix is computed and used instead of the view projection matrix.
	 * The ortho matrix converts from the range (0 ~ Width, 0 ~ Height, -1 ~ +1)
	 * to the clip range (-1 ~ +1, -1 ~ +1, -1 ~ +1).
	 *
	 * @param cam The camera to set
	 * @param ortho True if to use orthographic projection (for GUI rendering),
	 * false if to use the camera's view and projection matrices.
	 */
	public function setCamera(cam:Camera, ortho:Bool = false):Void
	{
		setViewPort(cam);
		setViewProjection(cam, ortho);
	}

	/**
	 * Draws the viewport but without notifying {@link SceneProcessor scene
	 * processors} of any rendering events.
	 *
	 * @param vp The ViewPort to render
	 *
	 * @see #renderViewPort(com.jme3.renderer.ViewPort, float)
	 */
	public function renderViewPortRaw(vp:ViewPort):Void
	{
		setCamera(vp.camera, false);

		var scenes:Vector<Spatial> = vp.getScenes();
		var i:Int = scenes.length;
		while (i-- >= 0)
		{
			renderScene(scenes[i], vp);
		}
		flushQueue(vp);
	}

	/**
	 * Renders the {@link ViewPort}.
	 * <p>
	 * If the ViewPort is {@link ViewPort#isEnabled() disabled}, this method
	 * returns immediately. Otherwise, the ViewPort is rendered by
	 * the following process:<br>
	 * <ul>
	 * <li>All {@link SceneProcessor scene processors} that are attached
	 * to the ViewPort are {@link SceneProcessor#initialize(com.jme3.renderer.RenderManager, com.jme3.renderer.ViewPort) initialized}.
	 * </li>
	 * <li>The SceneProcessors' {@link SceneProcessor#preFrame(float) } method
	 * is called.</li>
	 * <li>The ViewPort's {@link ViewPort#getOutputFrameBuffer() output framebuffer}
	 * is set_on the Renderer</li>
	 * <li>The camera is set_on the renderer, including its view port parameters.
	 * (see {@link #setCamera(com.jme3.renderer.Camera, Bool) })</li>
	 * <li>Any buffers that the ViewPort requests to be cleared are cleared
	 * and the {@link ViewPort#getBackgroundColor() background color} is set</li>
	 * <li>Every scene that is attached to the ViewPort is flattened into
	 * the ViewPort's render queue
	 * (see {@link #renderViewPortQueues(com.jme3.renderer.ViewPort, Bool) })
	 * </li>
	 * <li>The SceneProcessors' {@link SceneProcessor#postQueue(com.jme3.renderer.queue.RenderQueue) }
	 * method is called.</li>
	 * <li>The render queue is sorted and then flushed, sending
	 * rendering commands to the underlying Renderer implementation.
	 * (see {@link #flushQueue(com.jme3.renderer.ViewPort) })</li>
	 * <li>The SceneProcessors' {@link SceneProcessor#postFrame(com.jme3.texture.FrameBuffer) }
	 * method is called.</li>
	 * <li>The translucent queue of the ViewPort is sorted and then flushed
	 * (see {@link #renderTranslucentQueue(com.jme3.renderer.ViewPort) })</li>
	 * <li>If any objects remained in the render queue, they are removed
	 * from the queue. This is generally objects added to the
	 * {@link RenderQueue#renderShadowQueue(com.jme3.renderer.queue.RenderQueue.ShadowMode, com.jme3.renderer.RenderManager, com.jme3.renderer.Camera, Bool)
	 * shadow queue}
	 * which were not rendered because of a missing shadow renderer.</li>
	 * </ul>
	 *
	 * @param vp
	 * @param tpf
	 */
	//TODO 
	public function renderViewPort(vp:ViewPort, tpf:Float):Void
	{
		if (!vp.enabled)
			return;

		var processors:Vector<SceneProcessor> = vp.processors;
		var processor:SceneProcessor;
		for (processor in processors)
		{
			if (!processor.isInitialized)
			{
				processor.initialize(this, vp);
			}
			processor.preFrame(tpf);
		}

		mRenderer.setFrameBuffer(vp.frameBuffer);

		setCamera(vp.camera, false);

		if (vp.isClearDepth() || vp.isClearColor() || vp.isClearStencil())
		{
			if (vp.isClearColor())
			{
				mRenderer.backgroundColor = vp.backgroundColor;
			}

			mRenderer.clearBuffers(vp.isClearColor(), vp.isClearDepth(), vp.isClearStencil());
		}

		var scenes:Vector<Spatial> = vp.getScenes();
		var i:Int = scenes.length;
		while (i-- > 0)
		{
			renderScene(scenes[i], vp);
		}

		for (processor in processors)
		{
			processor.postQueue(vp.renderQueue);
		}

		flushQueue(vp);

		for (processor in processors)
		{
			processor.postFrame(vp.frameBuffer);
		}

		//renders the translucent objects queue after processors have been rendered
		renderTranslucentQueue(vp);

		// clear any remaining spatials that were not rendered.
		clearQueue(vp);
	}

	/**
	 * Called by the application to render any ViewPorts
	 * added to this RenderManager.
	 * <p>
	 * Renders any viewports that were added using the following methods:
	 * @param tpf Time per frame value
	 */
	public function render(tpf:Float):Void
	{
		for (i in 0...mPreViewPorts.length)
		{
			renderViewPort(mPreViewPorts[i], tpf);
		}

		for (i in 0...mViewPorts.length)
		{
			renderViewPort(mViewPorts[i], tpf);
		}

		for (i in 0...mPostViewPorts.length)
		{
			renderViewPort(mPostViewPorts[i], tpf);
		}

		mRenderer.present();
	}
}

