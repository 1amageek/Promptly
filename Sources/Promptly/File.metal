//
//  File.metal
//  Promptly
//
//  Created by Norikazu Muramoto on 2024/11/06.
//

#include <metal_stdlib>
using namespace metal;

struct VertexIn {
    float2 position [[attribute(0)]];
    float2 textureCoordinate [[attribute(1)]];
};

struct VertexOut {
    float4 position [[position]];
    float2 textureCoordinate;
};

struct Uniforms {
    float time;
    float intensity;
};

vertex VertexOut mention_vertex(VertexIn in [[stage_in]]) {
    VertexOut out;
    out.position = float4(in.position, 0.0, 1.0);
    out.textureCoordinate = in.textureCoordinate;
    return out;
}

fragment half4 mention_fragment(VertexOut in [[stage_in]],
                                texture2d<half> texture [[texture(0)]],
                                constant Uniforms &uniforms [[buffer(0)]]) {
    constexpr sampler textureSampler(mag_filter::linear, min_filter::linear);
    
    float2 uv = in.textureCoordinate;
    
    // 波紋エフェクト
    float wave = sin(uniforms.time * 4.0 + length(uv - 0.5) * 10.0) * 0.5 + 0.5;
    wave *= smoothstep(1.0, 0.0, length(uv - 0.5) * 2.0);
    
    // テキストの色を取得
    half4 color = texture.sample(textureSampler, uv);
    
    // アクセントカラー（システムの色に合わせて調整可能）
    half4 accentColor = half4(0.0, 0.5, 1.0, 1.0);
    
    // エフェクトの強度を時間とともに減衰
    float fadeOut = exp(-uniforms.time * 2.0);
    float effect = wave * fadeOut * uniforms.intensity;
    
    // 元の色とアクセントカラーをブレンド
    return mix(color, accentColor, effect * color.a);
}
