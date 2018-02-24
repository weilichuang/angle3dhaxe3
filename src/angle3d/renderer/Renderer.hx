package angle3d.renderer;
import angle3d.math.Color;
import angle3d.shader.Shader;
import angle3d.shader.ShaderSource;
import angle3d.scene.mesh.VertexBuffer;
import angle3d.texture.FrameBuffer;
import angle3d.texture.Texture;
/**
 * The `Renderer` is responsible for taking rendering commands and
 * executing them on the underlying video hardware.
 * @author
 */
interface Renderer {
	var backgroundColor:Color;

	function initialize():Void;
	function getStatistics():Statistics;
	function invalidateState():Void;
	function clearBuffers(color:Bool, depth:Bool, stencil:Bool):Void;

	function applyRenderState(state:RenderState):Void;
	function setDepthRange(start:Float, end:Float):Void;
	function postFrame():Void;
	/**
	 * Set the viewport location and resolution on the screen.
	 * @param	x
	 * @param	y
	 * @param	width
	 * @param	height
	 */
	function setViewPort(x:Int, y:Int, width:Int, height:Int):Void;
	function setClipRect(x:Int, y:Int, width:Int, height:Int):Void;
	function clearClipRect():Void;
	function setShader(shader:Shader):Void;
	function deleteShader(shader:Shader):Void;
	function deleteShaderSource(source:ShaderSource):Void;
	function copyFrameBuffer(src:FrameBuffer, dst:FrameBuffer, copyDepth:Bool):Void;
	function setFrameBuffer(fb:FrameBuffer):Void;
	function setMainFrameBufferOverride(fb:FrameBuffer):Void;
	function deleteFrameBuffer(fb:FrameBuffer):Void;
	function setTexture(index:Int, texture:Texture):Void;
	function updateBufferData(vb:VertexBuffer):Void;
	function deleteBuffer(vb:VertexBuffer):Void;
	/**
	 * Renders <code>count</code> meshes, with the geometry data supplied and
	 * per-instance data supplied.
	 * The shader which is currently set with <code>setShader</code> is
	 * responsible for transforming the input vertices into clip space
	 * and shading it based on the given vertex attributes.
	 * The integer variable gl_InstanceID can be used to access the current
	 * instance of the mesh being rendered inside the vertex shader.
	 * If the instance data is non-null, then it is submitted as a
	 * per-instance vertex attribute to the shader.
	 *
	 * @param mesh The mesh to render
	 * @param lod The LOD level to use, see {@link Mesh#setLodLevels(com.jme3.scene.VertexBuffer[]) }.
	 * @param count Number of mesh instances to render
	 * @param instanceData When count is greater than 1, these buffers provide
	 *                     the per-instance attributes.
	 */
	function renderMesh(mesh:Mesh, lod:Int, count:Int, instanceData:Array<VertexBuffer>):Void;
	function cleanup():Void;
	function setDefaultAnisotropicFilter(level:Int):Void;
	function setAlphaToCoverage(value:Bool):Void;
}