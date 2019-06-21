// Shine Shader By Charles Fettinger (https://github.com/Oncorporation)  3/2019
// use color to control shine amount, use transition wipes or make your own alpha texture
// slerp not currently used, for circular effects
uniform texture2d l_tex;
uniform float4 shine_color ;
uniform int speed_percent = 100;
uniform int gradient_percent = 20;
uniform int delay_percent = 0;
uniform bool Apply_To_Alpha_Layer = false;
uniform bool ease = false;
uniform bool hide = false;
uniform bool reverse = false;
uniform bool One_Direction = false;
uniform bool glitch = false;
uniform string notes = "Use Luma Wipes ( C:\Program Files (x86)\OBS\obs-studio\data\obs-plugins\obs-transitions\luma_wipes ) 'ease' makes the animation pause at the begin and end for a moment, 'hide' will make the image disappear, 'glitch' is random and amazing, 'reverse' quickly allows you to test settings";

uniform float start_adjust;
uniform float stop_adjust;

float EaseInOutCircTimer(float t,float b,float c,float d){
	t /= d/2;
	if (t < 1) return -c/2 * (sqrt(1 - t*t) - 1) + b;
	t -= 2;
	return c/2 * (sqrt(1 - t*t) + 1) + b;	
}

float Styler(float t,float b,float c,float d,bool ease)
{
	if (ease) return EaseInOutCircTimer(t,0,c,d);
	return t;
}

float4 convert_pmalpha(float4 color)
{
	float4 ret = color;
	if (color.a >= 0.001)
		ret.xyz /= color.a;
	else
		ret = float4(0.0, 0.0, 0.0, 0.0);
	return ret;
}

float4 slerp(float4 start, float4 end, float percent)
{
	// Dot product - the cosine of the angle between 2 vectors.
	float dotf = dot(start, end);
	// Clamp it to be in the range of Acos()
	// This may be unnecessary, but floating point
	// precision can be a fickle mistress.
	dotf = clamp(dotf, -1.0f, 1.0f);
	// Acos(dot) returns the angle between start and end,
	// And multiplying that by percent returns the angle between
	// start and the final result.
	float theta = acos(dotf)*percent;
	float4 RelativeVec = normalize(end - start * dotf);
	
	// Orthonormal basis
	// The final result.
	return ((start*cos(theta)) + (RelativeVec*sin(theta)));
}

float4 mainImage(VertData v_in) : TARGET
{
	// convert input for vector math
	float4 rgba = convert_pmalpha(image.Sample(textureSampler, v_in.uv));
	float speed = (float)speed_percent * 0.01;	
	float softness = max(abs((float)gradient_percent * 0.01), 0.01) * sign(gradient_percent);
	float delay = max((float)delay_percent * 0.01, 0.01);
	

	// circular easing variable
	float PI = 3.1415926535897932384626433832795;//acos(-1);
	float direction = cos(elapsed_time * speed);
	//float t = 1.0 + cos(PI* elapsed_time * speed);//
	
	float hidden = 0.0;
	if (delay > 0.0)
		hidden = (1 / cos((PI * elapsed_time * speed) * (1 / (1 + delay))));
		//pow(sin((elapsed_time * speed) / (1.0 + delay)),5.0) * sin((elapsed_time * speed) / (1.0 + delay));
	float t = sin(elapsed_time* speed);
	
	if (t < hidden)
	{
		t = 0;
	}
	t = 1 + t;

	float b = 0.0; //start value
	float c = 2.0; //change value
	float d = 2.0; //duration

	if (glitch) t = clamp(t + ((rand_f *2) - 1), 0.0,2.0);

	//if Unidirectional disable on return
	if (One_Direction && (direction < 0.0))
	{ 
		b = 0;
	}
	else
	{
		b = Styler(t, 0, c, d, ease);
	}

	// combine luma texture and user defined shine color
	float luma = l_tex.Sample(textureSampler, v_in.uv).x;

	// - adjust for min and max
	if ((luma >= (start_adjust)) && (luma <= (1 - stop_adjust)))
	{

		if (reverse)
		{
			luma = 1.0 - luma;
		}
	
		// user color with luma
		float4 output_color = float4(shine_color.rgb, luma);

		float time = lerp(0.0f, 1.0f + abs(2*softness), b - 1.0);

		// use luma texture to add alpha and shine

		// if behind glow, consider trailing gradient shine then show underlying image
		if (luma <= time - softness)
		{
			float alpha_behind = clamp(1.0 - (time - softness - luma ) / softness, 0.00, 1.0);	
			if (Apply_To_Alpha_Layer)
				alpha_behind *= rgba.a;
			return lerp(rgba, rgba + output_color, alpha_behind);		
		}

		// if in front of glow, consider if the underlying image is hidden
		if (luma >= time)
		{
			// if hide, make the transition better
			if (hide)
			{
				return float4(rgba.rgb, lerp(0.0, rgba.a, (time + softness) / (1 + abs(2*softness))));
			}
			else
			{
				return rgba;
			}
		}

		// else show the glow area, with luminance
		float alpha = (time - luma) / softness;
		if (Apply_To_Alpha_Layer)
			alpha *= rgba.a;
		return lerp(rgba, rgba + output_color, alpha);
	}
	else
	{
		return rgba;
	}
}
