uniform float4x4 ViewProj;
uniform texture2d image;

uniform float elapsed_time;
uniform float2 uv_offset;
uniform float2 uv_scale;
uniform float2 uv_pixel_interval;

sampler_state textureSampler {
	Filter    = Linear;
	AddressU  = Border;
	AddressV  = Border;
	BorderColor = 00000000;
};

struct VertData {
	float4 pos : POSITION;
	float2 uv  : TEXCOORD0;
};

VertData mainTransform(VertData v_in)
{
	VertData vert_out;
	vert_out.pos = mul(float4(v_in.pos.xyz, 1.0), ViewProj);
	vert_out.uv = v_in.uv * uv_scale + uv_offset;
	return vert_out;
}

uniform float pixelation;// <float min = 1; float step = 0.1;>;

float4 mainImage(VertData v_in) : TARGET
{
	float strength = max(1.0,abs(pixelation));
	float2 px = (v_in.uv / uv_pixel_interval.xy);

	float2 pixelated_high = px / float(strength);
	float2 pixelated_low = float2(floor(pixelated_high.x), floor(pixelated_high.y)) * strength;
	pixelated_high = pixelated_low + ((strength - 1) / strength);
	
	return (image.Sample(textureSampler, pixelated_low * uv_pixel_interval) +
			image.Sample(textureSampler, pixelated_high * uv_pixel_interval)) / 2.0;
}

technique Draw
{
	pass p0
	{
		vertex_shader = mainTransform(v_in);
		pixel_shader = mainImage(v_in);
	}
}