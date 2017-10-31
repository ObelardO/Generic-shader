//##################  Varriables  ##################
const float4x4 MatWorldViewProj : MATRIX_WORLDVIEWPROJ;
const float4x4 MatWorld : MATRIX_WORLD;

const float3 AmbientClr;

int EnableLight = 0;
#define MAX_LIGHTS 16
float3 lightPosition[ MAX_LIGHTS ];
float3 lightColor[ MAX_LIGHTS ] ;
float lightRange[ MAX_LIGHTS ] ;
float lightInt[ MAX_LIGHTS ] ;
int lightCount = 0;
float3 NormLight;

// Other
static float3 Color;
static float3 cD;
static float  cR;
static float3 cN;
static float  cF;
static float  cS;
static float3 cRf;
static float  cL;
static float3 vecCam;
static float3 vecLight;
static float3 vecLightNM;
static float3 vecSpec;
static float3 nSpec;

float3 CameraPosition;	    // Camera Position

const half SpecInt = 10.0f; // Specular Intensity
const half SpecDot = 1.0f;  // Specular Soft
const half SpecRng = 40.0f;


//##################  Textures  ##################
const texture tDiffuse : TEXTURE_0; // Diffuse Texture
sampler TexDiffuse=sampler_state {
    Texture   = <tDiffuse>;
    ADDRESSU  = WRAP;
    ADDRESSV  = WRAP;
    ADDRESSW  = WRAP;
    MAGFILTER = LINEAR;
    MINFILTER = LINEAR;
    MIPFILTER = LINEAR;
};

const texture tNormal : TEXTURE_2; // NormalMap Texture
sampler TexNormal=sampler_state {
    Texture   = <tNormal>;
    ADDRESSU  = WRAP;
    ADDRESSV  = WRAP;
    ADDRESSW  = WRAP;
    MAGFILTER = LINEAR;
    MINFILTER = LINEAR;
    MIPFILTER = LINEAR;
};

const texture tSpecular : TEXTURE_3; // SpecularMap Texture
sampler TexSpecular=sampler_state {
    Texture   = <tSpecular>;
    ADDRESSU  = WRAP;
    ADDRESSV  = WRAP;
    ADDRESSW  = WRAP;
    MAGFILTER = LINEAR;
    MINFILTER = LINEAR;
    MIPFILTER = LINEAR;
};


//##################  Input VS  ##################
struct sv_N_TC {
  float4 Position	: POSITION0;
  float3 Tangent	: TANGENT;
  float3 Binormal	: BINORMAL;
  float3 Normal		: NORMAL;
  float2 TexCoords	: TEXCOORD0;
};
//##################  Output VS  ##################
struct sp_PW_N_TC {	
	float4 Position		: POSITION0;
	float4 pWorld		: TEXCOORD0;
	float3 Tangent		: TEXCOORD1;
	float3 Binormal		: TEXCOORD2;
	float3 Normal		: TEXCOORD3;
	float2 TexCoords	: TEXCOORD4;	
};


//##################  VS  ##################
void vs_PW_N_TC( in sv_N_TC IN, out sp_PW_N_TC OUT ) {
        OUT.Position	        = mul(IN.Position,MatWorldViewProj);
	OUT.pWorld		= mul(IN.Position,MatWorld);
	OUT.Tangent		= normalize(mul(IN.Tangent,MatWorld));
	OUT.Binormal	        = normalize(mul(IN.Binormal,MatWorld));
	OUT.Normal		= normalize(mul(IN.Normal,MatWorld));
	OUT.TexCoords	        = IN.TexCoords;
}

//##################  PS  ##################
float4 psMain( in sp_PW_N_TC IN ) : COLOR {
	cD			= tex2D(TexDiffuse,IN.TexCoords).rgb;
	cR			= tex2D(TexSpecular,IN.TexCoords).r;//.r;
	cN			= normalize(tex2D(TexNormal,IN.TexCoords).rgb*2.0f-1.0f);
	
	vecCam		        = normalize(CameraPosition-IN.pWorld);

	Color		        = cD*AmbientClr;

	for( int i = 0; i < lightCount; i++ ) {
	
		lightRange[i]	= pow(saturate(1.0f-(distance(IN.pWorld,lightPosition[i])/lightRange[i])),SpecDot);
	
		vecLight	= normalize(lightPosition[i]-IN.pWorld);
		vecSpec		= normalize(vecLight+vecCam);
		
		vecLightNM	= float3(dot(vecLight,IN.Tangent),
							dot(vecLight,IN.Binormal),dot(vecLight,IN.Normal));
		vecSpec		= float3(dot(vecSpec,IN.Tangent),
							dot(vecSpec,IN.Binormal),dot(vecSpec,IN.Normal));
							
		cF		= pow(max(dot(vecCam,IN.Normal),0.0f),0.2f);
		cL		= max(dot(vecLightNM,cN),0.0f)*lightInt[i];
		cS		= pow(max(dot(vecSpec,cN),0.0f),SpecRng)*SpecInt;
		cR		= cR*cF;
		
		
		Color	   += cD*cL*lightColor[i]*(1.0f-cR)*lightRange[i]*lightInt[i]+cD*cS*lightColor[i]*cR*lightRange[i]*lightInt[i];
	
	}
	
	return float4(Color,1.0f);
	
}


//##################  Technique  ##################
technique Default {
	pass p0 {
		AlphaBlendEnable= false;
		vertexshader	= compile vs_3_0 vs_PW_N_TC();
		pixelshader	= compile ps_3_0 psMain();
	}
}

