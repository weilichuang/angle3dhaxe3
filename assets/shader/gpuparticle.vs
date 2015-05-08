/**
 * u_size ---> x=beginSize,y=endSize,z= endSize - beginSize
 * 
 */
attribute vec4 a_Position(POSITION);
attribute vec4 a_TexCoord(TEXCOORD);
attribute vec4 a_velocity(PARTICLE_VELOCITY);
//x-出生时间,y-生命时间,z-默认缩放,w-默认旋转角度
attribute vec4 a_LifeScaleSpin(PARTICLE_LIFE_SCALE_ANGLE);

#ifdef(USE_LOCAL_COLOR)
{  
	attribute vec4 a_Color(COLOR);
} 

#ifdef(USE_LOCAL_ACCELERATION)
{  
	attribute vec3 a_Acceleration(PARTICLE_ACCELERATION);
} 

uniform mat4 u_invertViewMat(ViewMatrixInverse);
uniform mat4 u_viewProjectionMat(WorldViewProjectionMatrix);
uniform vec4 u_vertexOffset[4];
uniform vec4 u_curTime;
uniform vec4 u_size;

//使用重力
#ifdef(USE_ACCELERATION)
{  
	uniform vec4 u_acceleration;
} 

varying vec4 v_TexCoord;

//全局颜色
#ifdef(USE_COLOR)
{  
	uniform vec4 u_beginColor;
	uniform vec4 u_incrementColor;
} 


#ifdef(USE_COLOR || USE_LOCAL_COLOR)
{  
	varying vec4 v_Color;
} 

//使用SpriteSheet
#ifdef(USE_SPRITESHEET)
{  
	uniform vec4 u_spriteSheet;
} 

void function main()
{ 
	//计算粒子当前运行时间
	float t_time = sub(u_curTime.x,a_LifeScaleSpin.x);
	//时间少于0时，代表粒子还未触发，设置其时间为0
	t_time = max(t_time,0.0);

	//进度  = 当前运行时间/总生命时间
	float t_interp = t_time / a_LifeScaleSpin.y;
	//取小数部分
	t_interp = fract(t_interp);

	//判断是否生命结束,非循环时生命结束后保持最后一刻或者应该使其不可见
	#ifdef(NOT_LOOP)
	{ 
		//粒子生命周期结束，停在最后一次
		//float t_finish = greaterThanEqual(t_time,a_LifeScaleSpin.y);
		//t_interp = add(t_interp,t_finish);
		//t_interp = min(t_interp,1.0);
		//粒子生命周期结束，不可见
		float t_finish = greaterThanEqual(a_LifeScaleSpin.y,t_time);
		t_interp *= t_finish;
	} 

	//使用全局颜色和自定义颜色
	#ifdef(USE_COLOR && USE_LOCAL_COLOR)
	{  
		vec4 t_offsetColor = u_incrementColor * t_interp + u_beginColor;
		//混合全局颜色和粒子自定义颜色
		v_Color = a_Color * t_offsetColor;
	} 
	//只使用全局颜色
	#elseif(USE_COLOR)
	{  
		vec4 t_offsetColor = u_incrementColor * t_interp;
		v_Color = u_beginColor + t_offsetColor;
	} 
	//只使用粒子本身颜色
	#elseif(USE_LOCAL_COLOR)
	{  
		v_Color = a_Color;
	} 

	//当前运行时间
	float t_curLife = t_interp * a_LifeScaleSpin.y;

	//计算移动速度和重力影响
	vec3 t_offsetPos;	vec3 t_localAcceleration;
	#ifdef(USE_ACCELERATION)
	{  
		#ifdef(USE_LOCAL_ACCELERATION)
		{  
			t_localAcceleration = u_acceleration.xyz + a_Acceleration;
			t_localAcceleration *= t_curLife;
		}  
		#else 
		{  
			t_localAcceleration = u_acceleration * t_curLife;
		}  
		t_offsetPos = a_velocity + t_localAcceleration;
		t_offsetPos *= t_curLife;
	}  
	#else 
	{  
		#ifdef(USE_LOCAL_ACCELERATION)
		{  
			t_localAcceleration = a_Acceleration * t_curLife;
			t_localAcceleration += a_velocity;
			t_offsetPos = t_localAcceleration * t_curLife;
		}  
		#else 
		{  
			t_offsetPos = a_velocity * t_curLife;
		}  
	} 

	//顶点的偏移位置（2个三角形的4个顶点）
	vec4 t_pos = u_vertexOffset[a_Position.w];

	//自转
	#ifdef(USE_SPIN)
	{  
		float t_angle = t_curLife * a_velocity.w;
		t_angle += a_LifeScaleSpin.w;
		float t_cos = cos(t_angle);
		float t_sin = sin(t_angle);
		float t_cosx = t_cos * t_pos.x;
		float t_siny = t_sin * t_pos.y;
		vec2 t_xy;
		t_xy.x = t_cosx - t_siny;
		float t_sinx = t_sin * t_pos.x;
		float t_cosy = t_cos * t_pos.y;
		t_xy.y = t_sinx + t_cosy;
		t_pos.xy = t_xy.xy;
	} 

	//使其面向相机
	t_pos.xyz = m33(t_pos.xyz,u_invertViewMat);
	//加上位移
	t_pos.xyz += t_offsetPos.xyz;

	//根据粒子大小确定未转化前的位置
	//u_size.x == start size,u_size.y == end size,u_size.z = end size - start size
	//a_LifeScaleSpin.z == particle scale
	float t_offsetSize = u_size.z * t_interp;
	float t_size = u_size.x + t_offsetSize;
	t_size = t_size * a_LifeScaleSpin.z;
	t_pos.xyz = t_pos.xyz * t_size;
	//加上中心点
	t_pos.xyz += a_Position.xyz;

	//判断此时粒子是否已经发出，没有放出的话设置该点坐标为0，4个顶点皆为0，所以此粒子不可见
	float t_active = notEqual(t_time,0.0);
	t_pos.xyz = t_pos.xyz * t_active;
	//如果支持条件语句的话，可以使用下面的语句代替上面
	//if(t_time == 0.0){
	//	t_pos.xyz = mul(t_pos.xyz,t_time);
	//}

	//最终位置
	output = m44(t_pos,u_viewProjectionMat);

	//计算当前动画所到达的帧数，没有使用SpriteSheet时则直接设置UV为a_TexCoord
	//a_TexCoord.x --> u,a_TexCoord.y --> v
	//a_TexCoord.z -->totalFrame,a_TexCoord.w --> defaultFrame
	#ifdef(USE_SPRITESHEET)
	{ 
		float t_frame;   
		#ifdef(USE_ANIMATION)
		{ 
			//t_frame = divide(t_curLife,u_spriteSheet.x);
			//t_frame = add(a_TexCoord.w,t_frame);

			//float t_frameInterp = divide(t_frame,a_TexCoord.z);
			//t_frameInterp  = fract(t_frameInterp);
			//t_frame = mul(t_frameInterp,a_TexCoord.z);
			//t_frame = floor(t_frame);
			
			t_frame = t_curLife/u_spriteSheet.x + a_TexCoord.w;
			
			float t_frameInterp = fract(t_frame/a_TexCoord.z);
			t_frame = floor(t_frameInterp * a_TexCoord.z);
		}  
		#else 
		{  
			t_frame = a_TexCoord.z;
		} 

		//计算当前帧时贴图的UV坐标
		//首先计算其在第几行，第几列
		float t_curRowIndex = t_frame / u_spriteSheet.y;
		t_curRowIndex = floor(t_curRowIndex);
		float t_curColIndex = t_curRowIndex * u_spriteSheet.y;
		t_curColIndex = t_frame - t_curColIndex;

		vec2 t_texCoord;

		//每个单元格所占用的UV坐标
		float t_dx = u_spriteSheet.y;
		t_dx = reciprocal(t_dx);
		float t_x0 = t_curColIndex + a_TexCoord.x;
		t_texCoord.x = t_x0 * t_dx;

		float t_dy = u_spriteSheet.z;
		t_dy = reciprocal(t_dy);
		float t_y0 = t_curRowIndex + a_TexCoord.y;
		t_texCoord.y = t_y0 * t_dy;

		v_TexCoord = t_texCoord;
	} 
	#else 
	{
		v_TexCoord = a_TexCoord;
	} 
}