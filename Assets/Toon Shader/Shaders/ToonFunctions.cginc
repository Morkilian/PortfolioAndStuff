
			float3 GetLightPos( int index )
			{
				//If index 0, we return the world light dir already, that's why we do -1
				return float3(unity_4LightPosX0[index-1],unity_4LightPosY0[index-1],unity_4LightPosZ0[index-1]);
			}
			
			float3 GetLightDir( int index , float3 worldPos)
			{
				
				return index==0?_WorldSpaceLightPos0.xyz:normalize(worldPos - GetLightPos(index));
			}
			
			float3 GetLightningGradient( int index , float3 worldPos , float3 worldNormal )
			{
				return dot(worldNormal,GetLightDir(index, worldPos));
			}
			
			float4 GetLightColor(int index)
			{
				return index == 0? _LightColor0:float4(unity_LightColor[index-1].xyz, unity_4LightAtten0[index-1]);
			}
			float4 GetGlossinessGradient(int index, float3 viewToPixelDir , float3 worldNormal, float3 lightDir,  float doSaturate)
			{
				
				float3 H = normalize(viewToPixelDir+ (-1)*lightDir);
				float dotResult = dot(worldNormal,H);
				return doSaturate? saturate(dotResult):dotResult;
			}
			
			float Remap(float value, float minOld, float maxOld, float minNew, float maxNew)
			{
				return ((minNew + (value - minOld)*(maxNew - minNew)/(maxOld - minOld)));
			}
			
			float SampleGradient(sampler2D tex, int index, float3 worldPos, float3 worldNormal)
			{
				float xVal = GetLightningGradient(index, worldPos, worldNormal);
				xVal = Remap(xVal,-1,1,0.01,0.99);
				float4 color = GetLightColor(index);
				return color;
				
				//return tex2D(tex, float2(xVal, color.w)).r;
				return tex2Dlod(tex, float4(xVal, color.w,0,0)).r;
			}

			
			

				