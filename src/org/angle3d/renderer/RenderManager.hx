package org.angle3d.renderer;
import org.angle3d.error.Assert;
import flash.Vector;
import org.angle3d.light.DefaultLightFilter;
import org.angle3d.light.LightFilter;
import org.angle3d.light.LightList;
import org.angle3d.material.LightMode;
import org.angle3d.material.MatParamOverride;
import org.angle3d.material.Material;
import org.angle3d.material.MaterialDef;
import org.angle3d.material.TechniqueDef;
import org.angle3d.material.RenderState;
import org.angle3d.material.Technique;
import org.angle3d.material.shader.Shader;
import org.angle3d.material.shader.Uniform;
import org.angle3d.material.shader.UniformBindingManager;
import org.angle3d.math.Matrix4f;
import org.angle3d.post.SceneProcessor;
import org.angle3d.profile.AppProfiler;
import org.angle3d.renderer.queue.GeometryList;
import org.angle3d.renderer.queue.QueueBucket;
import org.angle3d.renderer.queue.RenderQueue;
import org.angle3d.scene.Geometry;
import org.angle3d.scene.mesh.Mesh;
import org.angle3d.scene.Node;
import org.angle3d.scene.Spatial;

/**
 * `RenderManager` is a high-level rendering interface that is
 * above the Renderer implementation. RenderManager takes care
 * of rendering the scene graphs attached to each viewport and
 * handling SceneProcessors.
 *
 */
class RenderManager
{
	private var mRenderer:Stage3DRenderer;
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

	private var mHandleTranlucentBucket:Bool = true;

	private var mForcedMaterial:Material;
	private var forcedTechnique:String = null;
	private var mForceRenderState:RenderState;
	
	private var forcedOverrides:Vector<MatParamOverride>;
	
	private var mLightFilter:LightFilter;
	private var mFilteredLightList:LightList;
	
	private var preferredLightMode:LightMode;
	private var singlePassLightBatchSize:Int = 4;
	
	private var mProf:AppProfiler;

	/**
	 * Create a high-level rendering interface over the low-level rendering interface.
	 * @param renderer
	 */
	public function new(renderer:Stage3DRenderer)
	{
		mRenderer = renderer;
		mUniformBindingManager = new UniformBindingManager();

		mPreViewPorts = new Array<ViewPort>();
		mViewPorts = new Array<ViewPort>();
		mPostViewPorts = new Array<ViewPort>();

		mOrthoMatrix = new Matrix4f();

		mLightFilter = new DefaultLightFilter();
		mFilteredLightList = new LightList(null);
		
		preferredLightMode = LightMode.MultiPass;
		
		forcedOverrides = new Vector<MatParamOverride>();
	}
	
	/**
     * Sets an AppProfiler hook that will be called back for
     * specific steps within a single update frame.  Value defaults
     * to null.
     */
    public function setAppProfiler(prof:AppProfiler):Void
	{
        this.mProf = prof;
    }
	
	public function setPreferredLightMode(preferredLightMode:LightMode):Void
	{
        this.preferredLightMode = preferredLightMode;
    }

    public inline function getPreferredLightMode():LightMode
	{
        return preferredLightMode;
    }

    public inline function getSinglePassLightBatchSize():Int
	{
        return singlePassLightBatchSize;
    }

	/**
	 * 单次Pass中最多支持4个光源，不包括AmbientLight，超出数量则会分成多个Pass
	 * @param	singlePassLightBatchSize
	 */
    public function setSinglePassLightBatchSize(singlePassLightBatchSize:Int):Void
	{
        this.singlePassLightBatchSize = singlePassLightBatchSize;
		if (this.singlePassLightBatchSize < 1)
			this.singlePassLightBatchSize = 1;
		if (this.singlePassLightBatchSize > 4)
			this.singlePassLightBatchSize = 4;
    }
	
	/**
     * Set the material to use to render all future objects.
     * This overrides the material set on the geometry and renders
     * with the provided material instead.
     * Use null to clear the material and return renderer to normal
     * functionality.
     */
	public function setForcedMaterial(mat:Material):Void
	{
		mForcedMaterial = mat;
	}

	public function getForcedMaterial():Material
	{
		return mForcedMaterial;
	}
	
	/**
     * Returns the forced technique name set.
     * 
     * @return the forced technique name set.
     * 
     * @see setForcedTechnique(String) 
     */
    public function getForcedTechnique():String
	{
        return forcedTechnique;
    }

    /**
     * Sets the forced technique to use when rendering geometries.
     * <p>
     * If the specified technique name is available on the geometry's
     * material, then it is used, otherwise, the `setForcedMaterial` is used.
     * If a forced material is not set and the forced technique name cannot
     * be found on the material, the geometry will <em>not</em> be rendered.
     * 
     * @param forcedTechnique The forced technique name to use, set to null
     * to return to normal functionality.
     * 
     * @see `renderGeometry`
     */
    public function setForcedTechnique(forcedTechnique:String):Void
	{
        this.forcedTechnique = forcedTechnique;
    }

	/**
     * Set the render state to use for all future objects.
     * This overrides the render state set on the material and instead
     * forces this render state to be applied for all future materials
     * rendered. Set to null to return to normal functionality.
     */
	public function setForcedRenderState(state:RenderState):Void
	{
		mForceRenderState = state;
	}

	public function getForcedRenderState():RenderState
	{
		return mForceRenderState;
	}

	/**
     * Adds a forced material parameter to use when rendering geometries.
     * <p>
     * The provided parameter takes precedence over parameters set on the
     * material or any overrides that exist in the scene graph that have the
     * same name.
     *
     * @param override The override to add
     * @see MatParamOverride
     * @see `removeForcedMatParam`
     */
    public function addForcedMatParam(matOverride:MatParamOverride):Void 
	{
		if(forcedOverrides.indexOf(matOverride) == -1)
			forcedOverrides.push(matOverride);
    }

    /**
     * Remove a forced material parameter previously added.
     *
     * @param override The override to remove.
     * @see `addForcedMatParam`
     */
    public function removeForcedMatParam(matOverride:MatParamOverride):Void
	{
		var index:Int = forcedOverrides.indexOf(matOverride);
		if (index != -1)
		{
			forcedOverrides.splice(index, 1);
		}
    }

    /**
     * Get the forced material parameters applied to rendered geometries.
     * <p>
     * Forced parameters can be added via `addForcedMatParam` or 
	 * removed via `removeForcedMatParam`.
     *
     * @return The forced material parameters.
     */
    public function getForcedMatParams():Vector<MatParamOverride>
	{
        return forcedOverrides;
    }
	
	/**
	 * Returns the pre `ViewPort` with the given name.
	 *
	 * @param viewName The name of the pre ViewPort to look up
	 * @return The ViewPort, or null if not found.
	 *
	 * @see `createPreView`
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
	 * @see `createPreView`
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
	 * Returns the main `ViewPort` with the given name.
	 *
	 * @param viewName The name of the main ViewPort to look up
	 * @return The ViewPort, or null if not found.
	 *
	 * @see `createMainView`
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
	 * @see `createMainView`
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
	 * @see `createMainView`
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
	 * @see `createPostView`
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
	 * @see `createPostView`
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
	 * @see `createPreView`
	 */
	public function removePostView(view:ViewPort):Bool
	{
		return mPostViewPorts.remove(view);
	}

	/**
	 * Returns a read-only list of all pre ViewPorts
	 * @return a read-only list of all pre ViewPorts
	 * @see `createPreView`
	 */
	public function getPreViews():Array<ViewPort>
	{
		return mPreViewPorts;
	}

	/**
	 * Returns a read-only list of all main ViewPorts
	 * @return a read-only list of all main ViewPorts
	 * @see `createMainView`
	 */
	public function getMainViews():Array<ViewPort>
	{
		return mViewPorts;
	}

	/**
	 * Returns a read-only list of all post ViewPorts
	 * @return a read-only list of all post ViewPorts
	 * @see `createPostView`
	 */
	public function getPostViews():Array<ViewPort>
	{
		return mPostViewPorts;
	}

	/**
	 * Creates a new pre `ViewPort`, to display the given camera's content.
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
	 * Creates a new main `ViewPort`, to display the given camera's content.
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
	 * Creates a new post `ViewPort`, to display the given camera's content.
	 * <p>
	 * The view will be processed after the pre and main viewports.
	 */
	public function createPostView(viewName:String, cam:Camera):ViewPort
	{
		var vp:ViewPort = new ViewPort(viewName, cam);
		mPostViewPorts.push(vp);
		return vp;
	}

	private function reshapeViewPort(vp:ViewPort, w:Int, h:Int):Void
	{
		if (vp.getOutputFrameBuffer() == null)
		{
			vp.camera.resize(w, h, true);
		}

		var processors:Vector<SceneProcessor> = vp.processors;
		var processor:SceneProcessor;
		for (processor in processors)
		{
			if (!processor.isInitialized())
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
	public function notifyReshape(w:Int, h:Int):Void
	{
		var vp:ViewPort;
		var size:Int = mPreViewPorts.length;
		for (i in 0...size)
		{
			vp = mPreViewPorts[i];
			reshapeViewPort(vp, w, h);
		}

		size = mViewPorts.length;
		for (i in 0...size)
		{
			vp = mViewPorts[i];
			reshapeViewPort(vp, w, h);
		}

		size = mPostViewPorts.length;
		for (i in 0...size)
		{
			vp = mPostViewPorts[i];
			reshapeViewPort(vp, w, h);
		}
	}

	public function updateShaderBinding(shader:Shader):Void
	{
		updateUniformBindings(shader);
	}

	/**
	 * Internal use only.
	 * Updates the given list of uniforms with {UniformBinding uniform bindings}
	 * based on the current world state.
	 */
	public inline function updateUniformBindings(shader:Shader):Void
	{
		mUniformBindingManager.updateUniformBindings(shader);
	}

	/**
	 * True if the translucent bucket should automatically be rendered
	 * by the RenderManager.
	 *
	 * @return Whether or not the translucent bucket is rendered.
	 *
	 * @see `setHandleTranslucentBucket`
	 */
	public function isHandleTranslucentBucket():Bool
	{
		return mHandleTranlucentBucket;
	}

	/**
	 * Enable or disable rendering of the `Bucket.Translucent
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
	 * using `Material.render`.
	 * Using `renderGeometry` will override this value.
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
     * the geometry's `Geometry.setIgnoreTransform` feature is enabled, 
	 * the identity world matrix is used, otherwise, the 
     * geometry's `Geometry.getWorldMatrix()` is used. 
     * <p>
     * Once the world matrix is applied, the proper material is chosen for rendering.
     * If a `etForcedMaterial` is
     * set on this RenderManager, then it is used for rendering the geometry,
     * otherwise, the `Geometry.etMaterial()` is used.
     * <p>
     * If a `setForcedTechnique` is
     * set on this RenderManager, then it is selected automatically
     * on the geometry's material and is used for rendering. Otherwise, one
     * of the `MaterialDef.getDefaultTechniques()` is
     * used.
     * <p>
     * If a `setForcedRenderState` is set on this RenderManager, then it is used
     * for rendering the material, and the material's own render state is ignored.
     * Otherwise, the material's render state is used as intended.
     * 
     * @param geom The geometry to render
       * 
     * @see `Technique`
     * @see `RenderState`
     * @see `Material.selectTechnique`
     * @see `Material.render`
     */
	public function renderGeometry(geom:Geometry):Void
	{
		var mesh:Mesh = geom.getMesh();
		if (mesh == null)
			return;
	
		if (!geom.isIgnoreTransform())
		{
			setWorldMatrix(geom.getWorldMatrix());
		}
		else
		{
			setWorldMatrix(Matrix4f.IDENTITY);
		}
		
		//TODO 有些模型不需要灯光的则不需要执行这些操作
		var lightList:LightList = null;
		if (geom.useLight)
		{
			// Perform light filtering if we have a light filter.
			lightList = geom.getWorldLightList();
			if (mLightFilter != null)
			{
				mFilteredLightList.clear();
				mLightFilter.filterLights(geom, mFilteredLightList);
				lightList = mFilteredLightList;
			}
		}
		
		#if USE_STATISTICS
		// Report the number of lights we're about to render to the statistics.
		if(lightList != null)
			mRenderer.getStatistics().onLights(lightList.getSize());
		#end
		
		var material:Material = geom.getMaterial();
		
		//if forcedTechnique we try to force it for render,
        //if it does not exists in the mat def, we check for forcedMaterial and render the geom if not null
        //else the geom is not rendered
        if (forcedTechnique != null) 
		{
			var matDef:MaterialDef = material.getMaterialDef();
            if (matDef != null && matDef.getTechniqueDefs(forcedTechnique) != null)
			{
				var activeTechnique:Technique = material.getActiveTechnique();
				
				var previousTechniqueName:String = activeTechnique != null
                        ? activeTechnique.getDef().name
                        : TechniqueDef.DEFAULT_TECHNIQUE_NAME;
				
                material.selectTechnique(forcedTechnique, this);
				
                //saving forcedRenderState for future calls
                var tmpRs:RenderState = getForcedRenderState();
				
				var activeDef:TechniqueDef = material.getActiveTechnique().getDef();
                if (activeDef.forcedRenderState != null) 
				{
                    //forcing forced technique renderState
                    setForcedRenderState(activeDef.forcedRenderState);
                }
				
                // use geometry's material
                material.render(geom, lightList, this);
                material.selectTechnique(previousTechniqueName, this);

                //restoring forcedRenderState
                setForcedRenderState(tmpRs);
            } 
			else if (mForcedMaterial != null)
			{
                // use forced material
                mForcedMaterial.render(geom, lightList, this);
            }
        } 
		else if (mForcedMaterial != null) 
		{
            // use forced material
            mForcedMaterial.render(geom, lightList, this);
        } 
		else
		{
            material.render(geom, lightList, this);
        }
	}

	/**
	 * Renders the given GeometryList.
	 * <p>
	 * For every geometry in the list, the
	 * `renderGeometry` method is called.
	 *
	 * @param gl The geometry list to render.
	 *
	 * @see `GeometryList`
	 * @see `renderGeometry`
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
     * Flattens the given scene graph into the ViewPort's RenderQueue,
     * checking for culling as the call goes down the graph recursively.
     * <p>
     * First, the scene is checked for culling based on the `Spatial`s `Spatial.setCullHint`,
     * if the camera frustum contains the scene, then this method is recursively
     * called on its children.
     * <p>
     * When the scene's leaves or geometries are reached,
     * they are each enqueued into the ViewPort's render queue.
     * <p>
     * In addition to enqueuing the visible geometries, this method
     * also scenes which cast or receive shadows, by putting them into the
     * RenderQueue's shadow queue.
     * Each Spatial which has its `Spatial.setShadowMode`
     * set to not off, will be put into the appropriate shadow queue, note that
     * this process does not check for frustum culling on any shadow casters}, as they don't have to be
     * in the eye camera frustum to cast shadows on objects that are inside it.
     * 
     * @param scene The scene to flatten into the queue
     * @param vp The ViewPort provides the camera
     * used for culling and the queue used to contain the flattened scene graph.
     */
	public function renderScene(scene:Spatial, vp:ViewPort):Void
	{
		//reset of the camera plane state for proper culling (must be 0 for the first note of the scene to be rendered)
        vp.camera.planeState = 0;

		//rendering the scene
        renderSubScene(scene, vp);
	}
	
	// recursively renders the scene
	private function renderSubScene(scene:Spatial, vp:ViewPort):Void
	{
		// check culling first.
		if (!scene.checkCulling(vp.camera))
		{
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
				renderSubScene(children[i], vp);
			}
		}
		else if (Std.is(scene,Geometry))
		{
			if (!scene.truelyVisible)
				return;
				
			// add to the render queue
			var gm:Geometry = Std.instance(scene, Geometry);

			Assert.assert(gm.getMaterial() != null, "No material is set for Geometry: " + gm.name);

			vp.renderQueue.addToQueue(gm, gm.queueBucket);
		}
	}

	/**
	 * the camera currently used for rendering.
	 */
	public function getCurrentCamera():Camera
	{
		return mCamera;
	}

	/**
	 * The renderer implementation used for rendering operations.
	 *
	 * @return The renderer implementation
	 *
	 * @see `RenderManager`
	 * @see `Stage3DRenderer`
	 */
	public inline function getRenderer():Stage3DRenderer
	{
		return mRenderer;
	}

	/**
	 * Flushes the ViewPort's `ViewPort.getQueue`
	 * by rendering each of its visible buckets.
	 * By default the queues will automatically be cleared after rendering,
	 * so there's no need to clear them manually.
	 *
	 * @param vp The ViewPort of which the queue will be flushed
	 *
	 * @see `RenderQueue.renderQueue`
	 * @see `renderGeometryList`
	 */
	public function flushQueue(vp:ViewPort):Void
	{
		renderViewPortQueues(vp, true);
	}

	/**
	 * Clears the queue of the given ViewPort.
	 * Simply calls `RenderQueue.clear` on the ViewPort's `ViewPort.getQueue`
	 *
	 * @param vp The ViewPort of which the queue will be cleared.
	 *
	 * @see `RenderQueue.clear`
	 * @see `ViewPort.getQueue`
	 */
	public function clearQueue(vp:ViewPort):Void
	{
		vp.renderQueue.clear();
	}

	/**
	 * Render the given viewport queues.
	 * <p>
	 * Note that the `Bucket.Translucent` is NOT
	 * rendered by this method. Instead the user should call
	 * `renderTranslucentQueue`
	 * after this call.
	 *
	 * @param vp the viewport of which queue should be rendered
	 * @param flush If true, the queues will be cleared after
	 * rendering.
	 *
	 * @see `RenderQueue`
	 * @see `renderTranslucentQueue`
	 */
	public function renderViewPortQueues(vp:ViewPort, flush:Bool):Void
	{
		var queue:RenderQueue = vp.renderQueue;
		var cam:Camera = vp.camera;

		// render the sky, with depth range set to the farthest
		//首先绘制天空体
		if (!queue.isQueueEmpty(QueueBucket.Sky))
		{
			queue.renderQueue(QueueBucket.Sky, this, cam, flush);
		}

		// render opaque objects with default depth range
		// opaque objects are sorted front-to-back, reducing overdraw
		//不透明物体按从前向后排序，减少重绘
		queue.renderQueue(QueueBucket.Opaque, this, cam, flush);

		// transparent objects are last because they require blending with the rest of the scene's objects. 
		// Consequently, they are sorted back-to-front.
		//透明物体按从后向前排序
		if (!queue.isQueueEmpty(QueueBucket.Transparent))
		{
			queue.renderQueue(QueueBucket.Transparent, this, cam, flush);
		}

		//绘制GUI
		if (!queue.isQueueEmpty(QueueBucket.Gui))
		{
			var isParallelProjection:Bool = cam.isParallelProjection();
			//GUI需要使用正交矩阵
			setCamera(cam, true);
			queue.renderQueue(QueueBucket.Gui, this, cam, flush);
			//恢复原来的矩阵类型
			setCamera(cam, isParallelProjection);
		}
	}

	/**
	 * Renders the `Bucket.Translucent` on the viewPort.
	 * <p>
	 * This call does nothing unless `setHandleTranslucentBucket()`
	 * is set to true. This method clears the translucent queue after rendering
	 * it.
	 *
	 * @param vp The viewport of which the translucent queue should be rendered.
	 *
	 * @see `renderViewPortQueues`
	 * @see `setHandleTranslucentBucket`
	 */
	public function renderTranslucentQueue(vp:ViewPort):Void
	{
		var rq:RenderQueue = vp.renderQueue;
		if (mHandleTranlucentBucket && !rq.isQueueEmpty(QueueBucket.Translucent))
		{
			rq.renderQueue(QueueBucket.Translucent, this, vp.camera, true);
		}
	}

	private function setViewPort(cam:Camera):Void
	{
		// this will make sure to update viewport only if needed
		if (cam != this.mCamera || cam.isViewportChanged())
		{
			mViewX = Std.int(cam.viewPortLeft * cam.width);
			mViewY = Std.int(cam.viewPortBottom * cam.height);
			
			var viewX2:Int = Std.int(cam.viewPortRight * cam.width);
            var viewY2:Int = Std.int(cam.viewPortTop * cam.height);
			
			mViewWidth = viewX2 - mViewX;
			mViewHeight = viewY2 - mViewY;

			mUniformBindingManager.setViewPort(mViewX, mViewY, mViewWidth, mViewHeight);
			mRenderer.setViewPort(mViewX, mViewY, mViewWidth, mViewHeight);
			#if flash
			//opengl屏幕Y是从下到上，和stage3D相反
			mRenderer.setClipRect(mViewX, cam.height - (mViewHeight + mViewY), mViewWidth, mViewHeight);
			#else
			mRenderer.setClipRect(mViewX, mViewY, mViewWidth, mViewHeight);
			#end
			cam.clearViewportChanged();
			
			this.mCamera = cam;
			
			mOrthoMatrix.loadIdentity();
			mOrthoMatrix.setTranslation(-1, -1, 0);
			mOrthoMatrix.setScale(2 / cam.width, 2 / cam.height, 0);
		}
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
	 * set the camera to use for rendering.
	 * <p>
	 * First, the camera's `Camera.setViewPort`
	 * are applied. Then, the camera's `Camera.getViewMatrix()` and
	 * `Camera.getProjectionMatrix()` matrices are set
	 * on the renderer. If `ortho` is `true`, then
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
		// Tell the light filter which camera to use for filtering.
        if (mLightFilter != null) 
		{
            mLightFilter.setCamera(cam);
        }
		setViewPort(cam);
		setViewProjection(cam, ortho);
	}

	/**
	 * Draws the viewport but without notifying `SceneProcessor` of any rendering events.
	 *
	 * @param vp The ViewPort to render
	 *
	 * @see `renderViewPort`
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
	 * Renders the `ViewPort`.
	 * <p>
	 * If the ViewPort is `ViewPort.isEnabled()` disabled, this method
	 * returns immediately. Otherwise, the ViewPort is rendered by
	 * the following process:<br>
	 * <ul>
	 * <li>All `SceneProcessor` that are attached
	 * to the ViewPort are `SceneProcessor.initialize` initialized.
	 * </li>
	 * <li>The SceneProcessors' `SceneProcessor.preFrame` method
	 * is called.</li>
	 * <li>The ViewPort's `ViewPort.getOutputFrameBuffer`
	 * is set on the Renderer</li>
	 * <li>The camera is set on the renderer, including its view port parameters.
	 * (see `setCamera`)</li>
	 * <li>Any buffers that the ViewPort requests to be cleared are cleared
	 * and the `ViewPort.getBackgroundColor` is set</li>
	 * <li>Every scene that is attached to the ViewPort is flattened into
	 * the ViewPort's render queue
	 * (see `renderViewPortQueues`)
	 * </li>
	 * <li>The SceneProcessors' `SceneProcessor.postQueue` method is called.</li>
	 * <li>The render queue is sorted and then flushed, sending
	 * rendering commands to the underlying Renderer implementation.
	 * (see `flushQueue`)</li>
	 * <li>The SceneProcessors' `SceneProcessor.postFrame`
	 * method is called.</li>
	 * <li>The translucent queue of the ViewPort is sorted and then flushed
	 * (see `renderTranslucentQueue`)</li>
	 * <li>If any objects remained in the render queue, they are removed
	 * from the queue. This is generally objects added to the `RenderQueue.renderShadowQueue`
	 * which were not rendered because of a missing shadow renderer.</li>
	 * </ul>
	 *
	 * @param vp
	 * @param tpf
	 */
	public function renderViewPort(vp:ViewPort, tpf:Float):Void
	{
		if (!vp.isEnabled())
			return;

		var processors:Vector<SceneProcessor> = vp.processors;
		var processor:SceneProcessor;
		for (processor in processors)
		{
			if (!processor.isInitialized())
			{
				processor.initialize(this, vp);
			}
			processor.preFrame(tpf);
		}

		mRenderer.setFrameBuffer(vp.getOutputFrameBuffer());

		setCamera(vp.camera, false);

		if (vp.isClearDepth() || vp.isClearColor() || vp.isClearStencil())
		{
			if (vp.isClearColor())
			{
				mRenderer.backgroundColor.copyFrom(vp.backgroundColor);
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
			processor.postFrame(vp.getOutputFrameBuffer());
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
		mRenderer.resetStates();
		
		if (mRenderer.backBufferDirty)
		{
			mRenderer.configureBackBuffer();
		}
		
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

