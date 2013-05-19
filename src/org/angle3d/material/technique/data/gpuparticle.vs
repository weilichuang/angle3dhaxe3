/**
 * u_size ---> x=beginSize,y=endSize,z= endSize - beginSize
 */
attribute vec4 a_position(POSITION);
attribute vec4 a_texCoord(TEXCOORD);
attribute vec4 a_velocity(PARTICLE_VELOCITY);
//x-出生时间,y-生命时间,z-默认缩放,w-默认旋转角度
attribute vec4 a_lifeScaleSpin(PARTICLE_LIFE_SCALE_ANGLE);

#ifdef(USE_LOCAL_COLOR){  
	attribute vec4 a_color(COLOR);
} 

#ifdef(USE_LOCAL_ACCELERATION){  
	attribute vec3 a_acceleration(PARTICLE_ACCELERATION);
} 

uniform mat4 u_invertViewMat(ViewMatrixInverse);
uniform mat4 u_viewProjectionMat(WorldViewProjectionMatrix);
uniform vec4 u_vertexOffset[4];
uniform vec4 u_curTime;
uniform vec4 u_size;

//使用重力
#ifdef(USE_ACCELERATION){  
	uniform vec4 u_acceleration;
} 

varying vec4 v_texCoord;

//全局颜色
#ifdef(USE_COLOR){  
	uniform vec4 u_beginColor;
	uniform vec4 u_incrementColor;
} 


#ifdef(USE_COLOR || USE_LOCAL_COLOR){  
	varying vec4 v_color;
} 

//使用SpriteSheet
#ifdef(USE_SPRITESHEET){  
	uniform vec4 u_spriteSheet;
} 

void function main(){ 
	//计算粒子当前运行时间
	float t_time = sub(u_curTime.x,a_lifeScaleSpin.x);
	//时间少于0时，代表粒子还未触发，设置其时间为0
	t_time = max(t_time,0.0);

	//进度  = 当前运行时间/总生命时间
	float t_interp = divide(t_time,a_lifeScaleSpin.y);
	//取小数部分
	t_interp = fract(t_interp);

	//判断是否生命结束,非循环时生命结束后保持最后一刻或者应该使其不可见
	#ifdef(NOT_LOOP){ 
		//粒子生命周期结束，停在最后一次
		//float t_finish = greaterThanEqual(t_time,a_lifeScaleSpin.y);
		//t_interp = add(t_interp,t_finish);
		//t_interp = min(t_interp,1.0);
		//粒子生命周期结束，不可见
		float t_finish = greaterThanEqual(a_lifeScaleSpin.y,t_time);
		t_interp = mul(t_interp,t_finish);
	} 

	//使用全局颜色和自定义颜色
	#ifdef(USE_COLOR && USE_LOCAL_COLOR){  
		vec4 t_offsetColor = mul(u_incrementColor,t_interp);
		t_offsetColor = add(u_beginColor,t_offsetColor);
		//混合全局颜色和粒子自定义颜色
		v_color = mul(a_color,t_offsetColor);
	} 
	//只使用全局颜色
	#elseif(USE_COLOR){  
		vec4 t_offsetColor = mul(u_incrementColor,t_interp);
		v_color = add(u_beginColor,t_offsetColor);
	} 
	//只使用粒子本身颜色
	#elseif(USE_LOCAL_COLOR){  
		v_color = a_color;
	} 

	//当前运行时间
	float t_curLife = mul(t_interp,a_lifeScaleSpin.y);

	//计算移动速度和重力影响
	vec3 t_offsetPos;	vec3 t_localAcceleration;
	#ifdef(USE_ACCELERATION){  
		#ifdef(USE_LOCAL_ACCELERATION){  
			t_localAcceleration = add(u_acceleration.xyz,a_acceleration);
			t_localAcceleration = mul(t_localAcceleration,t_curLife);
		}  
		#else {  
			t_localAcceleration = mul(u_acceleration,t_curLife);
		}  
		t_offsetPos = add(a_velocity,t_localAcceleration);
		t_offsetPos = mul(t_offsetPos,t_curLife);
	}  
	#else {  
		#ifdef(USE_LOCAL_ACCELERATION){  
			t_localAcceleration = mul(a_acceleration,t_curLife);
			t_localAcceleration = add(t_localAcceleration,a_velocity);
			t_offsetPos = mul(t_localAcceleration,t_curLife);
		}  
		#else {  
			t_offsetPos = mul(a_velocity,t_curLife);
		}  
	} 

	//顶点的偏移位置（2个三角形的4个顶点）
	vec4 t_pos = u_vertexOffset[a_position.w];

	//自转
	#ifdef(USE_SPIN){  
		float t_angle = mul(t_curLife,a_velocity.w);
		t_angle = add(t_angle,a_lifeScaleSpin.w);
		float t_cos = cos(t_angle);
		float t_sin = sin(t_angle);
		float t_cosx = mul(t_cos,t_pos.x);
		float t_siny = mul(t_sin,t_pos.y);
		vec2 t_xy;
		t_xy.x = sub(t_cosx,t_siny);
		float t_sinx = mul(t_sin,t_pos.x);
		float t_cosy = mul(t_cos,t_pos.y);
		t_xy.y = add(t_sinx,t_cosy);
		t_pos.xy = t_xy.xy;
	} 

	//使其面向相机
	t_pos.xyz = m33(t_pos.xyz,u_invertViewMat);
	//加上位移
	t_pos.xyz = add(t_pos.xyz,t_offsetPos.xyz);

	//根据粒子大小确定未转化前的位置
	//u_size.x == start size,u_size.y == end size,u_size.z = end size - start size
	//a_lifeScaleSpin.z == particle scale
	float t_offsetSize = mul(u_size.z,t_interp);
	float t_size = add(u_size.x,t_offsetSize);
	t_size = mul(t_size,a_lifeScaleSpin.z);
	t_pos.xyz = mul(t_pos.xyz,t_size);
	//加上中心点
	t_pos.xyz = add(t_pos.xyz,a_position.xyz);

	//判断此时粒子是否已经发出，没有放出的话设置该点坐标为0，4个顶点皆为0，所以此粒子不可见
	float t_active = notEqual(t_time,0.0);
	t_pos.xyz = mul(t_pos.xyz,t_active);
	//如果支持条件语句的话，可以使用下面的语句代替上面
	//if(t_time == 0.0){
	//	t_pos.xyz = mul(t_pos.xyz,t_time);
	//}

	//最终位置
	output = m44(t_pos,u_viewProjectionMat);

	//计算当前动画所到达的帧数，没有使用SpriteSheet时则直接设置UV为a_texCoord
	//a_texCoord.x --> u,a_texCoord.y --> v
	//a_texCoord.z -->totalFrame,a_texCoord.w --> defaultFrame
	#ifdef(USE_SPRITESHEET){ 
		float t_frame;   
		#ifdef(USE_ANIMATION){ 
			t_frame = divide(t_curLife,u_spriteSheet.x);
			t_frame = add(a_texCoord.w,t_frame);

			float t_frameInterp = divide(t_frame,a_texCoord.z);
			t_frameInterp  = fract(t_frameInterp);
			t_frame = mul(t_frameInterp,a_texCoord.z);
			t_frame = floor(t_frame);
		}  
		#else {  
			t_frame = a_texCoord.z;
		} 

		//计算当前帧时贴图的UV坐标
		//首先计算其在第几行，第几列
		float t_curRowIndex = divide(t_frame,u_spriteSheet.y);
		t_curRowIndex = floor(t_curRowIndex);
		float t_curColIndex = mul(t_curRowIndex,u_spriteSheet.y);
		t_curColIndex = sub(t_frame,t_curColIndex);

		vec2 t_texCoord;

		//每个单元格所占用的UV坐标
		float t_dx = u_spriteSheet.y;
		t_dx = reciprocal(t_dx);
		float t_x0 = add(t_curColIndex,a_texCoord.x);
		t_texCoord.x = mul(t_x0,t_dx);

		float t_dy = u_spriteSheet.z;
		t_dy = reciprocal(t_dy);
		float t_y0 = add(t_curRowIndex,a_texCoord.y);
		t_texCoord.y = mul(t_y0,t_dy);

		v_texCoord = t_texCoord;
	} 
	#else {
		v_texCoord = a_texCoord;
	} 
}