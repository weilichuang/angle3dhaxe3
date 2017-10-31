package org.angle3d.shadow;
import org.angle3d.bounding.BoundingVolume;
import org.angle3d.math.FastMath;
import org.angle3d.math.Matrix4f;
import org.angle3d.math.Transform;
import org.angle3d.math.Vector2f;
import org.angle3d.renderer.Camera;

import org.angle3d.bounding.BoundingBox;
import org.angle3d.math.Vector3f;
import org.angle3d.renderer.queue.GeometryList;
import org.angle3d.renderer.queue.ShadowMode;
import org.angle3d.renderer.ViewPort;
import org.angle3d.scene.CullHint;
import org.angle3d.renderer.FrustumIntersect;
import org.angle3d.scene.Geometry;
import org.angle3d.scene.Node;
import org.angle3d.scene.Spatial;
import org.angle3d.utils.TempVars;

/**
 * Includes various useful shadow mapping functions.
 *
 * @see http://appsrv.cse.cuhk.edu.hk/~fzhang/pssm_vrcia/
 * @see http://http.developer.nvidia.com/GPUGems3/gpugems3_ch10.html
 * for more info.
 */
class ShadowUtil
{
	private static var tmpVec3:Vector3f = new Vector3f();
	private static var min:Vector3f = new Vector3f();
	private static var max:Vector3f = new Vector3f();
	private static var right:Vector3f = new Vector3f();
	
	private static var casterBB:BoundingBox = new BoundingBox();
    private static var receiverBB:BoundingBox = new BoundingBox();
	private static var occExt:OccludersExtractor = new OccludersExtractor();
	private static var splitBB:BoundingBox = new BoundingBox();
	private static var recvBox:BoundingBox = new BoundingBox();
	private static var tmpMatrix:Matrix4f = new Matrix4f();
	private static var cropMatrix:Matrix4f = new Matrix4f();
	private static var tmpDir:Vector3f = new Vector3f();
    private static var tmpUp:Vector3f = new Vector3f();

    /**
     * Updates a points arrays with the frustum corners of the provided camera.
     *
     * @param viewCam
     * @param points
     */
    public static function updateFrustumPoints2(viewCam:Camera, points:Vector<Vector3f>):Void 
	{
        var w:Int = viewCam.getWidth();
        var h:Int = viewCam.getHeight();

        viewCam.getWorldCoordinates(0, 0, 0, points[0]);
        viewCam.getWorldCoordinates(0, h, 0, points[1]);
        viewCam.getWorldCoordinates(w, h, 0, points[2]);
        viewCam.getWorldCoordinates(w, 0, 0, points[3]);

        viewCam.getWorldCoordinates(0, 0, 1, points[4]);
        viewCam.getWorldCoordinates(0, h, 1, points[5]);
        viewCam.getWorldCoordinates(w, h, 1, points[6]);
        viewCam.getWorldCoordinates(w, 0, 1, points[7]);
    }

    /**
     * Updates the points array to contain the frustum corners of the given
     * camera. The nearOverride and farOverride variables can be used to
     * override the camera's near/far values with own values.
     *
     * @param viewCam
     * @param nearOverride
     * @param farOverride
     */
    public static function updateFrustumPoints(viewCam:Camera,
												nearOverride:Float,
												farOverride:Float,
												scale:Float,
												points:Vector<Vector3f>):Void 
	{

        var pos:Vector3f = viewCam.getLocation();
        var dir:Vector3f = viewCam.getDirection(tmpDir);
        var up:Vector3f = viewCam.getUp(tmpUp);

        var depthHeightRatio:Float = viewCam.frustumTop / viewCam.frustumNear;
        var near:Float = nearOverride;
        var far:Float = farOverride;
        var ftop:Float = viewCam.frustumTop;
        var fright:Float = viewCam.frustumRight;
        var ratio:Float = fright / ftop;

        var near_height:Float;
        var near_width:Float;
        var far_height:Float;
        var far_width:Float;

        if (viewCam.isParallelProjection())
		{
            near_height = ftop;
            near_width = near_height * ratio;
            far_height = ftop;
            far_width = far_height * ratio;
        } 
		else
		{
            near_height = depthHeightRatio * near;
            near_width = near_height * ratio;
            far_height = depthHeightRatio * far;
            far_width = far_height * ratio;
        }

        dir.cross(up, right).normalizeLocal();

		var farCenterX:Float = dir.x * far + pos.x;
		var farCenterY:Float = dir.y * far + pos.y;
		var farCenterZ:Float = dir.z * far + pos.z;
		
		var nearCenterX:Float = dir.x * near + pos.x;
		var nearCenterY:Float = dir.y * near + pos.y;
		var nearCenterZ:Float = dir.z * near + pos.z;

        var nearUpX:Float = up.x * near_height;
	    var nearUpY:Float = up.y * near_height;
		var nearUpZ:Float = up.z * near_height;
			
			
        var farUpX:Float = up.x * far_height;
		var farUpY:Float = up.y * far_height;
		var farUpZ:Float = up.z * far_height;
		
        var nearRightX:Float = right.x * near_width;
		var nearRightY:Float = right.y * near_width;
		var nearRightZ:Float = right.z * near_width;
		
        var farRightX:Float = right.x * far_width;
		var farRightY:Float = right.y * far_width;
		var farRightZ:Float = right.z * far_width;
		
		//points[0].copyFrom(nearCenter).subtractLocal(nearUp).subtractLocal(nearRight);
        //points[1].copyFrom(nearCenter).addLocal(nearUp).subtractLocal(nearRight);
        //points[2].copyFrom(nearCenter).addLocal(nearUp).addLocal(nearRight);
        //points[3].copyFrom(nearCenter).subtractLocal(nearUp).addLocal(nearRight);
        //points[4].copyFrom(farCenter).subtractLocal(farUp).subtractLocal(farRight);
        //points[5].copyFrom(farCenter).addLocal(farUp).subtractLocal(farRight);
        //points[6].copyFrom(farCenter).addLocal(farUp).addLocal(farRight);
        //points[7].copyFrom(farCenter).subtractLocal(farUp).addLocal(farRight);
		
		points[0].x = nearCenterX - nearUpX - nearRightX;
		points[0].y = nearCenterY - nearUpY - nearRightY;
		points[0].z = nearCenterZ - nearUpZ - nearRightZ;
		
		points[1].x = nearCenterX + nearUpX - nearRightX;
		points[1].y = nearCenterY + nearUpY - nearRightY;
		points[1].z = nearCenterZ + nearUpZ - nearRightZ;
		
		points[2].x = nearCenterX + nearUpX + nearRightX;
		points[2].y = nearCenterY + nearUpY + nearRightY;
		points[2].z = nearCenterZ + nearUpZ + nearRightZ;
		
		points[3].x = nearCenterX - nearUpX + nearRightX;
		points[3].y = nearCenterY - nearUpY + nearRightY;
		points[3].z = nearCenterZ - nearUpZ + nearRightZ;
		
		points[4].x = farCenterX - farUpX - farRightX;
		points[4].y = farCenterY - farUpY - farRightY;
		points[4].z = farCenterZ - farUpZ - farRightZ;
		
		points[5].x = farCenterX + farUpX - farRightX;
		points[5].y = farCenterY + farUpY - farRightY;
		points[5].z = farCenterZ + farUpZ - farRightZ;
		
		points[6].x = farCenterX + farUpX + farRightX;
		points[6].y = farCenterY + farUpY + farRightY;
		points[6].z = farCenterZ + farUpZ + farRightZ;
		
		points[7].x = farCenterX - farUpX + farRightX;
		points[7].y = farCenterY - farUpY + farRightY;
		points[7].z = farCenterZ - farUpZ + farRightZ;

        if (scale != 1.0)
		{
            // find center of frustum
            var cx:Float = 0;
			var cy:Float = 0;
			var cz:Float = 0;
            for (i in 0...8)
			{
				var p:Vector3f = points[i];
				cx += p.x;
				cy += p.y;
				cz += p.z;
            }
			
			var s:Float = 1 / 8;
			cx *= s;
			cy *= s;
			cz *= s;

			var scale1:Float = scale - 1.0;
            for (i in 0...8)
			{
				var p:Vector3f = points[i];
				
				p.x += (p.x - cx ) * scale1;
				p.y += (p.y - cy ) * scale1;
				p.z += (p.z - cz ) * scale1;
            }
        }
    }

    /**
     * Compute bounds of a geomList
     * @param list
     * @param transform
     */
    public static function computeUnionBound(list:GeometryList, transform:Transform):BoundingBox
	{
        var bbox:BoundingBox = new BoundingBox();
        var tempv:TempVars = TempVars.get();
        for (i in 0...list.size) 
		{
            var vol:BoundingVolume = list.getGeometry(i).getWorldBound();
            var newVol:BoundingVolume = vol.transform(transform, tempv.bbox);
            //Nehon : prevent NaN and infinity values to screw the final bounding box
			var centerX:Float = newVol.center.x;
            if (!FastMath.isNaN(centerX) && !FastMath.isInfinite(centerX)) 
			{
                bbox.mergeLocal(newVol);
            }
        }
        tempv.release();
        return bbox;
    }

    /**
     * Compute bounds of a geomList
     * @param list
     * @param mat
     */
    public static function computeUnionBoundForMatrix4(list:GeometryList, mat:Matrix4f):BoundingBox
	{
        var bbox:BoundingBox = new BoundingBox();
        var tempv:TempVars = TempVars.get();
        for (i in 0...list.size) 
		{
			var vol:BoundingVolume = list.getGeometry(i).getWorldBound();
            var newVol:BoundingVolume = vol.transformMatrix(mat, tempv.bbox);
			
			//Nehon : prevent NaN and infinity values to screw the final bounding box
			var centerX:Float = newVol.center.x;
            if (!FastMath.isNaN(centerX) && !FastMath.isInfinite(centerX)) 
			{
                bbox.mergeLocal(newVol);
            }
        }
        tempv.release();
        return bbox;
    }

    /**
     * Computes the bounds of multiple bounding volumes
     *
     * @param bv
     */
    public static function computeUnionBoundForList(list:Vector<BoundingVolume>):BoundingBox
	{
        var bbox:BoundingBox = new BoundingBox();
        for (i in 0...list.length) 
		{
            bbox.mergeLocal(list[i]);
        }
        return bbox;
    }

    /**
     * Compute bounds from an array of points
     *
     * @param pts
     * @param transform
     */
    public static function computeBoundForPoints(pts:Vector<Vector3f>, transform:Transform):BoundingBox
	{
        var min:Vector3f = new Vector3f(FastMath.POSITIVE_INFINITY,FastMath.POSITIVE_INFINITY,FastMath.POSITIVE_INFINITY);
        var max:Vector3f = new Vector3f(FastMath.NEGATIVE_INFINITY,FastMath.NEGATIVE_INFINITY,FastMath.NEGATIVE_INFINITY);
        var temp:Vector3f = new Vector3f();
        for (i in 0...pts.length)
		{
            transform.transformVector(pts[i], temp);

            min.minLocal(temp);
            max.maxLocal(temp);
        }
        var center:Vector3f = min.add(max).scaleLocal(0.5);
        var extent:Vector3f = max.subtract(min).scaleLocal(0.5);
        return new BoundingBox(center, extent);
    }

    /**
     * Compute bounds from an array of points
     * @param pts
     * @param mat
	 * @param result
     */
    public static function computeBoundForPoints2(pts:Vector<Vector3f>, mat:Matrix4f, result:BoundingBox = null):BoundingBox
	{
		if (result == null)
		{
			result = new BoundingBox();
		}
		
		min.setTo(FastMath.POSITIVE_INFINITY,FastMath.POSITIVE_INFINITY,FastMath.POSITIVE_INFINITY);
        max.setTo(FastMath.NEGATIVE_INFINITY, FastMath.NEGATIVE_INFINITY, FastMath.NEGATIVE_INFINITY);
		
        for (i in 0...pts.length)
		{
            var w:Float = 1 / mat.multProj(pts[i], tmpVec3);
			
			tmpVec3.x *= w;
            tmpVec3.y *= w;
            tmpVec3.z *= w;
			
			if (min.x > tmpVec3.x)
				min.x = tmpVec3.x;
				
			if (min.y > tmpVec3.y)
				min.y = tmpVec3.y;
			
			if (min.z > tmpVec3.z)
				min.z = tmpVec3.z;
				
			if (max.x < tmpVec3.x)
				max.x = tmpVec3.x;
				
			if (max.y < tmpVec3.y)
				max.y = tmpVec3.y;
			
			if (max.z < tmpVec3.z)
				max.z = tmpVec3.z;
        }
		
		result.center.x = (min.x + max.x) * 0.5;
		result.center.y = (min.y + max.y) * 0.5;
		result.center.z = (min.z + max.z) * 0.5;
		
		//Added an offset to the extend to avoid banding artifacts when the frustum are aligned
		result.xExtent = (max.x - min.x) * 0.5 + 2.0;
		result.yExtent = (max.y - min.y) * 0.5 + 2.0;
		result.zExtent = (max.z - min.z) * 0.5 + 2.0;

        return result;
    }

    /**
     * Updates the shadow camera to properly contain the given points (which
     * contain the eye camera frustum corners)
     *
     * @param shadowCam
     * @param points
     */
    public static function updateShadowCamera(shadowCam:Camera, points:Vector<Vector3f>):Void 
	{
        var ortho:Bool = shadowCam.isParallelProjection();
        shadowCam.setProjectionMatrix(null);

        if (ortho)
		{
            shadowCam.setFrustum(-1, 1, -1, 1, 1, -1);
        }
		else 
		{
            shadowCam.setFrustumPerspective(45, 1, 1, 150);
        }

        var viewProjMatrix:Matrix4f = shadowCam.getViewProjectionMatrix();
        var projMatrix:Matrix4f = shadowCam.getProjectionMatrix();

        splitBB = computeBoundForPoints2(points, viewProjMatrix, splitBB);

        var splitMin:Vector3f = splitBB.getMin(min);
        var splitMax:Vector3f = splitBB.getMax(max);

//        splitMin.z = 0;

        // Create the crop matrix.
        var scaleX:Float, scaleY:Float, scaleZ:Float;
        var offsetX:Float, offsetY:Float, offsetZ:Float;

        scaleX = 2.0 / (splitMax.x - splitMin.x);
        scaleY = 2.0 / (splitMax.y - splitMin.y);
        offsetX = -0.5 * (splitMax.x + splitMin.x) * scaleX;
        offsetY = -0.5 * (splitMax.y + splitMin.y) * scaleY;
        scaleZ = 1.0 / (splitMax.z - splitMin.z);
        offsetZ = -splitMin.z * scaleZ;

        cropMatrix.setTo(scaleX, 0, 0, offsetX,
						0, scaleY, 0, offsetY,
						0, 0, scaleZ, offsetZ,
						0, 0, 0, 1);


        var result:Matrix4f = new Matrix4f();
        result.copyFrom(cropMatrix);
        cropMatrix.multLocal(projMatrix);

        shadowCam.setProjectionMatrix(result);
    }

    /**
     * Updates the shadow camera to properly contain the given points (which
     * contain the eye camera frustum corners) and the shadow occluder objects
     * collected through the traverse of the scene hierarchy
     */
    public static function updateShadowCameraFromViewPort(viewPort:ViewPort,
												receivers:GeometryList,
												shadowCam:Camera,
												points:Vector<Vector3f>,
												splitOccluders:GeometryList,
												shadowMapSize:Float,
												checkCasterCulling:Bool):Void 
	{
        
        var ortho:Bool = shadowCam.isParallelProjection();

        shadowCam.setProjectionMatrix(null);

        if (ortho)
		{
            shadowCam.setFrustum(-shadowCam.frustumFar, shadowCam.frustumFar, -1, 1, 1, -1);
        }

        // create transform to rotate points to viewspace        
        var viewProjMatrix:Matrix4f = shadowCam.getViewProjectionMatrix();

        splitBB = computeBoundForPoints2(points, viewProjMatrix, splitBB);

        var casterCount:Int = 0, receiverCount:Int = 0;
		
		casterBB.reset();
		receiverBB.reset();
		
        for (i in 0...receivers.size) 
		{
            // convert bounding box to light's viewproj space
            var receiver:Geometry = receivers.getGeometry(i);
            var bv:BoundingVolume = receiver.getWorldBound();
			
            recvBox = cast bv.transformMatrix(viewProjMatrix, recvBox);

            if (splitBB.intersects(recvBox))
			{
                //Nehon : prevent NaN and infinity values to screw the final bounding box
                if (!FastMath.isNaN(recvBox.center.x) && !FastMath.isInfinite(recvBox.center.x)) 
				{
                    receiverBB.mergeLocal(recvBox);
                    receiverCount++;
                }
            }
        }

        // collect splitOccluders through scene recursive traverse
        occExt.initialize(viewProjMatrix, casterCount, splitBB, casterBB, splitOccluders, checkCasterCulling);
		var scenes:Vector<Spatial> = viewPort.getScenes();
        for (i in 0...scenes.length)
		{
            occExt.addOccluders(scenes[i]);
        }
        casterCount = occExt.casterCount;
  
        //Nehon 08/18/2010 this is to avoid shadow bleeding when the ground is set to only receive shadows
        if (casterCount != receiverCount)
		{
            casterBB.xExtent += 2.0;
            casterBB.yExtent += 2.0;
            casterBB.zExtent += 2.0;
        }
		
		//var casterMin:Vector3f = casterBB.getMin(vars.vect1);
        //var casterMax:Vector3f = casterBB.getMax(vars.vect2);
		
		var center:Vector3f = casterBB.center;
		
		var casterMinx:Float = center.x - casterBB.xExtent;
		var casterMiny:Float = center.y - casterBB.yExtent;
		var casterMinz:Float = center.z - casterBB.zExtent;
		
		var casterMaxx:Float = center.x + casterBB.xExtent;
		var casterMaxy:Float = center.y + casterBB.yExtent;
		var casterMaxz:Float = center.z + casterBB.zExtent;

        //var receiverMin:Vector3f = receiverBB.getMin(vars.vect3);
        //var receiverMax:Vector3f = receiverBB.getMax(vars.vect4);
		
		center = receiverBB.center;
		
		var receiverMinx:Float = center.x - receiverBB.xExtent;
		var receiverMiny:Float = center.y - receiverBB.yExtent;
		var receiverMinz:Float = center.z - receiverBB.zExtent;
		
		var receiverMaxx:Float = center.x + receiverBB.xExtent;
		var receiverMaxy:Float = center.y + receiverBB.yExtent;
		var receiverMaxz:Float = center.z + receiverBB.zExtent;

        //var splitMin:Vector3f = splitBB.getMin(vars.vect5);
        //var splitMax:Vector3f = splitBB.getMax(vars.vect6);
		
		center = splitBB.center;
		
		var splitMinx:Float = center.x - splitBB.xExtent;
		var splitMiny:Float = center.y - splitBB.yExtent;
		var splitMinz:Float = center.z - splitBB.zExtent;
		
		var splitMaxx:Float = center.x + splitBB.xExtent;
		var splitMaxy:Float = center.y + splitBB.yExtent;
		var splitMaxz:Float = center.z + splitBB.zExtent;

        splitMinz = 0;

//        if (!ortho) {
//            shadowCam.setFrustumPerspective(45, 1, 1, splitMax.z);
//        }

        var projMatrix:Matrix4f = shadowCam.getProjectionMatrix();

        // IMPORTANT: Special handling for Z values
        var cropMinx = FastMath.max(FastMath.max(casterMinx, receiverMinx), splitMinx);
        var cropMaxx = FastMath.min(FastMath.min(casterMaxx, receiverMaxx), splitMaxx);

        var cropMiny = FastMath.max(FastMath.max(casterMiny, receiverMiny), splitMiny);
        var cropMaxy = FastMath.min(FastMath.min(casterMaxy, receiverMaxy), splitMaxy);

        var cropMinz = FastMath.min(casterMinz, splitMinz);
        var cropMaxz = FastMath.min(receiverMaxz, splitMaxz);


        // Create the crop matrix.
        var scaleX:Float, scaleY:Float, scaleZ:Float;
        var offsetX:Float, offsetY:Float, offsetZ:Float;

        scaleX = 2.0 / (cropMaxx - cropMinx);
        scaleY = 2.0 / (cropMaxy - cropMiny);

        //Shadow map stabilization approximation from shaderX 7
        //from Practical Cascaded Shadow maps adapted to PSSM
        //scale stabilization
        var halfTextureSize:Float = shadowMapSize * 0.5;

        if (halfTextureSize != 0 && scaleX > 0 && scaleY > 0)
		{
            var scaleQuantizer:Float = 0.1;            
            scaleX = 1.0 / Math.ceil(1.0 / scaleX * scaleQuantizer) * scaleQuantizer;
            scaleY = 1.0 / Math.ceil(1.0 / scaleY * scaleQuantizer) * scaleQuantizer;
        }

        offsetX = -0.5 * (cropMaxx + cropMinx) * scaleX;
        offsetY = -0.5 * (cropMaxy + cropMiny) * scaleY;


        //Shadow map stabilization approximation from shaderX 7
        //from Practical Cascaded Shadow maps adapted to PSSM
        //offset stabilization
        if (halfTextureSize != 0  && scaleX > 0 && scaleY > 0)
		{
            offsetX = Math.ceil(offsetX * halfTextureSize) / halfTextureSize;
            offsetY = Math.ceil(offsetY * halfTextureSize) / halfTextureSize;
        }

        scaleZ = 1.0 / (cropMaxz - cropMinz);
        offsetZ = -cropMinz * scaleZ;

        cropMatrix.setTo(scaleX, 0, 0, offsetX,
                0, scaleY, 0, offsetY,
                0, 0, scaleZ, offsetZ,
                0, 0, 0, 1);


        tmpMatrix.copyFrom(cropMatrix);
        tmpMatrix.multLocal(projMatrix);
		
        shadowCam.setProjectionMatrix(tmpMatrix);
    }
    
    /**
     * Populates the outputGeometryList with the geometry of the
     * inputGeomtryList that are in the frustum of the given camera
     *
     * @param inputGeometryList The list containing all geometry to check
     * against the camera frustum
     * @param camera the camera to check geometries against
     * @param outputGeometryList the list of all geometries that are in the
     * camera frustum
     */
    public static function getGeometriesInCamFrustum(inputGeometryList:GeometryList,
													 camera:Camera,
													 outputGeometryList:GeometryList):Void 
	{
        for (i in 0...inputGeometryList.size) 
		{
            var g:Geometry = inputGeometryList.getGeometry(i);
            var planeState:Int = camera.planeState;
            camera.planeState = 0;
            if (camera.contains(g.getWorldBound()) != FrustumIntersect.Outside)
			{
                outputGeometryList.add(g);
            }
            camera.planeState = planeState;
        }
    }

    /**
     * Populates the outputGeometryList with the rootScene children geometries
     * that are in the frustum of the given camera
     *
     * @param rootScene the rootNode of the scene to traverse
     * @param camera the camera to check geometries against
     * @param outputGeometryList the list of all geometries that are in the
     * camera frustum
     */    
    public static function getGeometriesInCamFrustumFromScene(rootScene:Spatial, camera:Camera, mode:ShadowMode, outputGeometryList:GeometryList):Void 
	{
        if (rootScene != null && Std.is(rootScene, Node))
		{
            var planeState:Int = camera.planeState;
            addGeometriesInCamFrustumFromNode(camera, cast rootScene, mode, outputGeometryList);
            camera.planeState = planeState;
        }
    }
    
    /**
     * Helper function to distinguish between Occluders and Receivers
     * 
     * @param shadowMode the ShadowMode tested
     * @param desired the desired ShadowMode 
     * @return true if tested ShadowMode matches the desired one
     */
    static private function checkShadowMode(shadowMode:ShadowMode, desired:ShadowMode):Bool
    {
        if (shadowMode != ShadowMode.Off)
        {
            switch (desired)
			{
                case ShadowMode.Cast : 
                    return shadowMode == ShadowMode.Cast || shadowMode == ShadowMode.CastAndReceive;
                case ShadowMode.Receive: 
                    return shadowMode == ShadowMode.Receive || shadowMode== ShadowMode.CastAndReceive;
                case ShadowMode.CastAndReceive:
                    return true;
				case ShadowMode.Off:
					return false;
				case ShadowMode.Inherit:
					return false;
            }
        }
        return false;
    }
    
    /**
     * Helper function used to recursively populate the outputGeometryList 
     * with geometry children of scene node
     * 
     * @param camera
     * @param scene
     * @param outputGeometryList 
     */
    private static function addGeometriesInCamFrustumFromNode(camera:Camera, scene:Node, mode:ShadowMode, outputGeometryList:GeometryList):Void 
	{
        if (scene.cullHint == CullHint.Always) 
			return;
			
        camera.planeState = 0;
		
		var OutSide:FrustumIntersect = FrustumIntersect.Outside;
        if (camera.contains(scene.getWorldBound()) != OutSide)
		{
			var children:Vector<Spatial> = scene.children;
            for (i in 0...children.length) 
			{
				var child:Spatial = children[i];
                if (Std.is(child, Node))
				{
					addGeometriesInCamFrustumFromNode(camera, cast child, mode, outputGeometryList);
				}
                else if (Std.is(child, Geometry) && child.cullHint != CullHint.Always)
				{
					var geom:Geometry = cast child;
					
                    camera.planeState = 0;
                    if (checkShadowMode(child.shadowMode, mode) &&
						!geom.isGrouped() &&
						camera.contains(child.getWorldBound()) != OutSide)
					{
                        outputGeometryList.add(geom);
                    }
                }
            }
        }
    }
    
    /**
     * Populates the outputGeometryList with the geometry of the
     * inputGeomtryList that are in the radius of a light.
     * The array of camera must be an array of 6 cameras initialized so they represent the light viewspace of a pointlight
     *
     * @param inputGeometryList The list containing all geometry to check
     * against the camera frustum
     * @param cameras the camera array to check geometries against
     * @param outputGeometryList the list of all geometries that are in the
     * camera frustum
     */
    public static function getGeometriesInLightRadius(inputGeometryList:GeometryList,
													cameras:Vector<Camera>,
													outputGeometryList:GeometryList):Void 
	{
        for (i in 0...inputGeometryList.size)
		{
            var g:Geometry = inputGeometryList.getGeometry(i);
            var inFrustum:Bool = false;
			var j:Int = 0;
            while (j < cameras.length && inFrustum == false)
			{
                var camera:Camera = cameras[j];
                var planeState:Int = camera.planeState;
                camera.planeState = 0;
                inFrustum = camera.contains(g.getWorldBound()) != FrustumIntersect.Outside;
                camera.planeState = planeState;
				
				j++;
            }
			
            if (inFrustum)
			{
                outputGeometryList.add(g);
            }
        }
    }

    /**
     * Populates the outputGeometryList with the geometries of the children 
     * of OccludersExtractor.rootScene node that are both in the frustum of the given vpCamera and some camera inside cameras array.
     * The array of cameras must be initialized to represent the light viewspace of some light like pointLight or spotLight
     *
     * @param camera the viewPort camera 
     * @param cameras the camera array to check geometries against, representing the light viewspace
     * @param outputGeometryList the output list of all geometries that are in the camera frustum
     */
    public static function getLitGeometriesInViewPort(rootScene:Spatial, vpCamera:Camera, cameras:Vector<Camera>, mode:ShadowMode, outputGeometryList:GeometryList):Void 
	{
        if (rootScene != null && Std.is(rootScene, Node))
		{
            addGeometriesInCamFrustumAndViewPortFromNode(vpCamera, cameras, cast rootScene, mode, outputGeometryList);
        }
    }
    /**
     * Helper function to recursively collect the geometries for getLitGeometriesInViewPort function.
     * 
     * @param vpCamera the viewPort camera 
     * @param cameras the camera array to check geometries against, representing the light viewspace
     * @param scene the Node to traverse or geometry to possibly add
     * @param outputGeometryList the output list of all geometries that are in the camera frustum
     */
    private static function addGeometriesInCamFrustumAndViewPortFromNode(vpCamera:Camera, cameras:Vector<Camera>, scene:Spatial, mode:ShadowMode, outputGeometryList:GeometryList):Void 
	{
        if (scene.cullHint == CullHint.Always) 
			return;

        var inFrustum:Bool = false;
        var j:Int = 0;
		while (j < cameras.length && inFrustum == false)
		{
            var camera:Camera = cameras[j];
			var planeState:Int = camera.planeState;
			camera.planeState = 0;
            inFrustum = camera.contains(scene.getWorldBound()) != FrustumIntersect.Outside && scene.checkCulling(vpCamera);
            camera.planeState = planeState;
			
			j++;
        }
		
        if (inFrustum)
		{
            if (Std.is(scene,Node))
            {
                var node:Node = cast scene;
                for (child in node.children)
				{
                    addGeometriesInCamFrustumAndViewPortFromNode(vpCamera, cameras, child, mode, outputGeometryList);
                }
            }
            else if (Std.is(scene, Geometry))
			{
				var geom:Geometry = cast scene;
                if (checkShadowMode(geom.shadowMode, mode) && !geom.isGrouped() )
				{
                    outputGeometryList.add(geom);
                }
            }
        }
    }

}


/**
 * OccludersExtractor is a helper class to collect splitOccluders from scene recursively.
 * It utilizes the scene hierarchy, instead of making the huge flat geometries list first.
 * Instead of adding all geometries from scene to the RenderQueue.shadowCast and checking
 * all of them one by one against camera frustum the whole Node is checked first
 * to hopefully avoid the check on its children.
 */
class OccludersExtractor
{
	// global variables set in order not to have recursive process method with too many parameters
	public var viewProjMatrix:Matrix4f;
	public var casterCount:Int;
	public var splitBB:BoundingBox;
	public var casterBB:BoundingBox;
	public var splitOccluders:GeometryList;
	
	private var zExtend:Float = 50;
	private var zCenter:Float = 25;
	private var checkCasterCulling:Bool = true;
	
	private var tmpBB:BoundingBox = new BoundingBox();

	public function new()
	{
		
	}
	
	/**
	 * initialize the global OccludersExtractor variables
	 * @param	vpm
	 * @param	cc
	 * @param	sBB
	 * @param	cBB
	 * @param	sOCC
	 */ 
	public function initialize(vpm:Matrix4f, cc:Int, 
						sBB:BoundingBox, cBB:BoundingBox,
						sOCC:GeometryList,checkCasterCulling:Bool, zExtend:Float = 50)
	{
		this.viewProjMatrix = vpm; 
		this.casterCount = cc;
		this.splitBB = sBB;
		this.casterBB = cBB;
		this.splitOccluders = sOCC;
		this.checkCasterCulling = checkCasterCulling;
		this.zExtend = zExtend;
		this.zCenter = zExtend * 0.5;
	}

	/**
	 * Check the rootScene against camera frustum and if intersects process it recursively.
	 * The global OccludersExtractor variables need to be initialized first.
	 * Variables are updated and used in `ShadowUtil.updateShadowCamera` at last.
	 */
	public function addOccluders(scene:Spatial):Int
	{
		if ( scene != null )
			process(scene);
		return casterCount;
	}
	
	private function process(scene:Spatial):Void
	{
		if (scene.cullHint == CullHint.Always) 
			return;

		var bound:BoundingVolume = scene.getWorldBound();
		if (bound == null)
			return;
			
		if ( Std.is(scene,Geometry))
		{
			var shadowMode:ShadowMode = scene.shadowMode;
			// convert bounding box to light's viewproj space
			var occluder:Geometry = cast scene;
			if (shadowMode != ShadowMode.Off && shadowMode != ShadowMode.Receive && !occluder.isGrouped())
			{
				var occBox:BoundingVolume = bound.transformMatrix(viewProjMatrix, tmpBB);
				//有些复杂场景检查包围体可能会导致一些应该产生阴影的物体被过滤掉，导致无阴影，此时可屏蔽检查包围体
				if (!checkCasterCulling)
				{
					casterBB.mergeLocal(occBox);
					casterCount++;
					splitOccluders.add(occluder);
				}
				else
				{
					var intersects:Bool = splitBB.intersects(occBox);
					if (intersects)
					{
						casterBB.mergeLocal(occBox);
						casterCount++;
						splitOccluders.add(occluder);
					}
					else if(Std.is(occBox, BoundingBox))
					{
						var occBB:BoundingBox = cast occBox;
						//Kirill 01/10/2011
						// Extend the occluder further into the frustum
						// This fixes shadow dissapearing issues when
						// the caster itself is not in the view camera
						// but its shadow is in the camera
						//      The number is in world units
						occBB.zExtent += zExtend;
						occBB.center.z += zCenter;
						
						if (splitBB.intersects(occBB))
						{
							//Nehon : prevent NaN and infinity values to screw the final bounding box
							if (!FastMath.isNaN(occBox.center.x) && !FastMath.isInfinite(occBox.center.x))
							{
								// To prevent extending the depth range too much
								// We return the bound to its former shape
								// Before adding it
								occBB.zExtent -= zExtend;
								occBB.center.z -= zCenter;                   
								casterBB.mergeLocal(occBox);
								casterCount++;
								splitOccluders.add(occluder);
							}
						}
					} 
				}
			}
		}
		else if (Std.is(scene, Node))
		{
			var nodeOcc:Node = cast scene;
			
			var intersects:Bool;
			if (!checkCasterCulling)
			{
				intersects = true;
			}
			else
			{
				var occBox:BoundingVolume = bound.transformMatrix(viewProjMatrix, tmpBB);
				intersects = splitBB.intersects(occBox);
				if (!intersects && Std.is(occBox, BoundingBox))
				{
					var occBB:BoundingBox = cast occBox;
					//Kirill 01/10/2011
					// Extend the occluder further into the frustum
					// This fixes shadow dissapearing issues when
					// the caster itself is not in the view camera
					// but its shadow is in the camera
					//      The number is in world units
					occBB.zExtent += zExtend;
					occBB.center.z += zCenter;
					intersects = splitBB.intersects(occBB);
				}
			}
			
			if ( intersects ) 
			{
				var children:Vector<Spatial> = nodeOcc.getChildren();
				for (i in 0...children.length) 
				{
					process(children[i]);
				}
			}
		}
	}
}
