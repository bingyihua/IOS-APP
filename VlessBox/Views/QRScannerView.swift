import SwiftUI
import AVFoundation

struct QRScannerView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var proxyManager: ProxyManager
    @State private var isCameraAvailable = false
    @State private var scannedCode: String?
    @State private var errorMessage: String = ""
    @State private var showingResult = false
    @State private var resultConfigs: [VmessConfig] = []
    
    var body: some View {
        ZStack {
            CameraView(delegate: self)
                .edgesIgnoringSafeArea(.all)
            
            // Scan overlay
            VStack {
                Spacer()
                
                // Scan area indicator
                ZStack {
                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: 280, height: 280)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .strokeBorder(Color.white.opacity(0.5), lineWidth: 2)
                        )
                        .overlay(
                            scanCorners
                        )
                    
                    // Scanning line animation
                    if !showingResult {
                        Rectangle()
                            .fill(Color.green.opacity(0.6))
                            .frame(width: 260, height: 2)
                            .anchorPreference(key: ScanLinePositionKey.self, value: .bounds) {
                                [\"center\": .center.y]
                            }
                    }
                }
                .frame(width: 300, height: 300)
                
                Spacer()
            }
            
            // Top info bar
            VStack {
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundStyle(.white)
                    }
                    Spacer()
                    Text("将二维码对准框内")
                        .font(.caption)
                        .foregroundStyle(.white)
                    Spacer()
                    Button {
                        // Flash toggle
                    } label: {
                        Image(systemName: "flashlight.off.fill")
                            .font(.title2)
                            .foregroundStyle(.white)
                    }
                }
                .padding()
                .padding(.top, 50)
            }
            
            // Result overlay
            if showingResult {
                Color.black.opacity(0.7)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture { dismissingResult() }
                
                VStack(spacing: 16) {
                    Text("找到 \(resultConfigs.count) 个配置")
                        .font(.headline)
                        .foregroundStyle(.white)
                    
                    ForEach(resultConfigs) { config in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(config.name.isEmpty ? config.server : config.name)
                                .font(.subheadline)
                                .foregroundStyle(.white)
                            Text(\"\\(config.server):\\(config.port)\")
                                .font(.caption)
                                .foregroundStyle(.gray)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.gray.opacity(0.3))
                        .cornerRadius(12)
                        .onTapGesture {
                            resultConfigs.forEach { proxyManager.addConfig() }
                            if resultConfigs.count == 1 {
                                proxyManager.currentConfig = resultConfigs[0]
                            }
                            dismissingResult()
                        }
                    }
                    
                    Button { dismissingResult() } label: {
                        Text("完成")
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                .frame(width: 300)
                .background(Color.black.opacity(0.8))
                .cornerRadius(16)
            }
        }
        .onAppear { checkCameraAvailability() }
    }
    
    private var scanCorners: some View {
       ZStack {
            // Top-left corner
            Path { path in
                path.move(to: CGPoint(x: 0, y: 20))
                path.addLine(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: 20, y: 0))
            }
            .stroke(Color.green, lineWidth: 4)
            
            // Top-right corner
            Path { path in
                path.move(to: CGPoint(x: 260, y: 0))
                path.addLine(to: CGPoint(x: 280, y: 0))
                path.addLine(to: CGPoint(x: 280, y: 20))
            }
            .stroke(Color.green, lineWidth: 4)
            
            // Bottom-left corner
            Path { path in
                path.move(to: CGPoint(x: 0, y: 260))
                path.addLine(to: CGPoint(x: 0, y: 280))
                path.addLine(to: CGPoint(x: 20, y: 280))
            }
            .stroke(Color.green, lineWidth: 4)
            
            // Bottom-right corner
            Path { path in
                path.move(to: CGPoint(x: 260, y: 280))
                path.addLine(to: CGPoint(x: 280, y: 280))
                path.addLine(to: CGPoint(x: 280, y: 260))
            }
            .stroke(Color.green, lineWidth: 4)
        }
    }
    
    private func checkCameraAvailability() {
        isCameraAvailable = AVCaptureDevice.authorizationStatus(for: .video) == .authorized ||
                           AVCaptureDevice.authorizationStatus(for: .video) == .notDetermined
        
        if AVCaptureDevice.authorizationStatus(for: .video) == .notDetermined {
            AVCaptureDevice.requestAccess(for: .video) { granted in
                isCameraAvailable = granted
            }
        }
    }
    
    private func dismissingResult() {
        showingResult = false
        dismiss()
    }
}

// MARK: - Camera View Coordinator
struct CameraView: UIViewRepresentable {
    let delegate: QRCodeDelegate
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        context.coordinator.setup(delegate: delegate)
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
    
    func makeCoordinator() -> QRCodeDelegate {
        QRCodeDelegate()
    }
}

class QRCodeDelegate: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    private let captureSession = AVCaptureSession()
    private let metadataOutput = AVCaptureMetadataOutput()
    private weak var videoPreviewLayer: UIView?
    
    func setup(delegate: QRCodeDelegate) {
        self = delegate
        // This is a simplified camera view - real implementation uses AVFoundation
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: [
            CIDetectorAccuracy: CIDetectorAccuracyHigh
        ])
        
        if let features = detector?.features(in: ciImage) as? [QRCodeFeature] {
            for feature in features {
                if let code = feature.messageString {
                    handleScannedCode(code)
                }
            }
        }
    }
    
    private func handleScannedCode(_ code: String) {
        let configs = QRCodeParser.parseAny(code)
        if !configs.isEmpty {
            // Post notification or callback
        }
    }
}

// MARK: - Preference Key
struct ScanLinePositionKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
