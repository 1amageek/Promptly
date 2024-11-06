//
//  EffectShader.swift
//  Promptly
//
//  Created by Norikazu Muramoto on 2024/11/06.
//

import SwiftUI
import MetalKit

class MentionEffectView: NSView {
    private var metalLayer: CAMetalLayer
    private let device: MTLDevice
    private var commandQueue: MTLCommandQueue
    private var pipelineState: MTLRenderPipelineState
    private var vertices: MTLBuffer
    private var uniforms: MTLBuffer
    private var startTime: CFTimeInterval
    private var displayLink: CVDisplayLink?
    
    struct Vertex {
        var position: SIMD2<Float>
        var textureCoordinate: SIMD2<Float>
    }
    
    struct Uniforms {
        var time: Float
        var intensity: Float
    }
    
    override init(frame: NSRect) {
        guard let device = MTLCreateSystemDefaultDevice(),
              let commandQueue = device.makeCommandQueue() else {
            fatalError("Metal is not supported")
        }
        
        self.device = device
        self.commandQueue = commandQueue
        self.metalLayer = CAMetalLayer()
        
        // 頂点データの設定
        let vertices = [
            Vertex(position: SIMD2(-1, -1), textureCoordinate: SIMD2(0, 1)),
            Vertex(position: SIMD2(-1,  1), textureCoordinate: SIMD2(0, 0)),
            Vertex(position: SIMD2( 1, -1), textureCoordinate: SIMD2(1, 1)),
            Vertex(position: SIMD2( 1,  1), textureCoordinate: SIMD2(1, 0))
        ]
        
        self.vertices = device.makeBuffer(bytes: vertices,
                                          length: MemoryLayout<Vertex>.stride * vertices.count,
                                          options: [])!
        
        let uniforms = Uniforms(time: 0, intensity: 1.0)
        self.uniforms = device.makeBuffer(bytes: &uniforms,
                                          length: MemoryLayout<Uniforms>.size,
                                          options: [])!
        
        // シェーダーの設定
        let library = try! device.makeDefaultLibrary()
        let vertexFunction = library.makeFunction(name: "mention_vertex")
        let fragmentFunction = library.makeFunction(name: "mention_fragment")
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        
        self.pipelineState = try! device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        
        self.startTime = CACurrentMediaTime()
        
        super.init(frame: frame)
        
        self.wantsLayer = true
        self.layer = metalLayer
        self.metalLayer.device = device
        self.metalLayer.pixelFormat = .bgra8Unorm
        self.metalLayer.framebufferOnly = true
        
        setupDisplayLink()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupDisplayLink() {
        CVDisplayLinkCreateWithActiveCGDisplays(&displayLink)
        if let displayLink = displayLink {
            CVDisplayLinkSetOutputCallback(displayLink, { (displayLink, _, _, _, _, userData) -> CVReturn in
                let view = Unmanaged<MentionEffectView>.fromOpaque(userData!).takeUnretainedValue()
                view.render()
                return kCVReturnSuccess
            }, Unmanaged.passUnretained(self).toOpaque())
            
            CVDisplayLinkStart(displayLink)
        }
    }
    
    func render() {
        guard let drawable = metalLayer.nextDrawable(),
              let commandBuffer = commandQueue.makeCommandBuffer(),
              let renderPassDescriptor = MTLRenderPassDescriptor() else {
            return
        }
        
        renderPassDescriptor.colorAttachments[0].texture = drawable.texture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        
        if let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) {
            let currentTime = Float(CACurrentMediaTime() - startTime)
            var uniforms = Uniforms(time: currentTime, intensity: 1.0)
            self.uniforms.contents().copyMemory(from: &uniforms, byteCount: MemoryLayout<Uniforms>.size)
            
            encoder.setRenderPipelineState(pipelineState)
            encoder.setVertexBuffer(vertices, offset: 0, index: 0)
            encoder.setFragmentBuffer(self.uniforms, offset: 0, index: 0)
            encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
            encoder.endEncoding()
        }
        
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
    
    deinit {
        if let displayLink = displayLink {
            CVDisplayLinkStop(displayLink)
        }
    }
}

// CustomTextEditorの修正部分
struct CustomTextEditor: NSViewRepresentable {
    // ... 既存のコード ...
    
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        guard let textView = scrollView.documentView as? NSTextView else { return scrollView }
        
        // MentionEffectViewを追加
        let effectView = MentionEffectView(frame: textView.bounds)
        effectView.autoresizingMask = [.width, .height]
        textView.addSubview(effectView)
        
        // 既存の設定
        textView.delegate = context.coordinator
        textView.string = text
        textView.isRichText = true
        textView.isEditable = true
        textView.allowsUndo = true
        textView.font = .systemFont(ofSize: NSFont.systemFontSize)
        
        return scrollView
    }
    
    // ... 残りのコード ...
}
