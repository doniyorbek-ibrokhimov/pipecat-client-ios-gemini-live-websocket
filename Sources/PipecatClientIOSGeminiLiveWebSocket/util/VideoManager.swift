//
//  File.swift
//  PipecatClientIOSGeminiLiveWebSocket
//
//  Created by Doniyorbek Ibrokhimov on 26/04/25.
//

import AVFoundation

final class VideoManager {
    
    /// the set of available devices on the system.
    private var isManaging: Bool = false
    private let notificationCenter: NotificationCenter
    
    // The AVAudioSession class is only available as a singleton:
    // https://developer.apple.com/documentation/avfaudio/avaudiosession/1648777-init
    
    private let videoSession = AVCaptureSession()
    
    internal convenience init() {
        self.init(
            notificationCenter: .default
        )
    }
    
    internal init(
        notificationCenter: NotificationCenter
    ) {
        // We have an issue with iOS 17 simulator, more details in this thread:
        // https://forums.developer.apple.com/forums/thread/738346
        // If the current iOS version is greater than 17, we are applying a workaround to fix it
#if targetEnvironment(simulator)
        if UIDevice.current.systemVersion.compare("17", options: .numeric) == .orderedDescending {
            Logger.shared.info("Applying workaround for iOS 17 simulator")
            do {
                try self.audioSession.setActive(true)
            } catch let error {
                Logger.shared.error("Error when applying workaroung for iOS 17 simulator: \(error)")
            }
        }
#endif
        
        self.notificationCenter = notificationCenter
                
        self.addNotificationObservers()
    }
    
    // MARK: - API
    
    func startManagingIfNecessary() {
        guard !self.isManaging else {
            return
        }
        self.startManaging()
    }
    
    func startManaging() {
        assert(self.isManaging == false)
        
        self.isManaging = true
            
        // Set initial device state (videoDevice and availableDevices) and configure the audio
        // session if needed.
        // Note: initial state after startManaging() does not represent a "change", so don't fire
        // callbacks
        self.configureVideoSessionIfNeeded(suppressDelegateCallbacks: true)
    }
    
    func stopManaging() {
        assert(self.isManaging == true)
        
        self.isManaging = false
        
        self.resetAudioSession()
    }
    
    // MARK: - Notifications
    private func addNotificationObservers() {
        self.notificationCenter.addObserver(
            self,
            selector: #selector(routeDidChange(_:)),
            name: AVAudioSession.routeChangeNotification,
            object: self.videoSession
        )
        
        self.notificationCenter.addObserver(
            self,
            selector: #selector(mediaServicesWereReset(_:)),
            name: AVAudioSession.mediaServicesWereResetNotification,
            object: self.videoSession
        )
    }
    
    @objc private func routeDidChange(_ notification: Notification) {
        configureVideoSessionIfNeeded()
    }
    
    @objc private func mediaServicesWereReset(_ notification: Notification) {
        self.configureVideoSessionIfNeeded()
    }
    
    // MARK: - Configuration
    
    private func resetAudioSession() {
        do {
            // Restoring the session to the previous values
           //FIXME: implement
        } catch {
            Logger.shared.error("Error configuring audio session")
        }
    }
    
    private func configureVideoSessionIfNeeded(suppressDelegateCallbacks: Bool = false) {
        // Do nothing if we still not in a call
        if !self.isManaging {
            return
        }
        
        do {
            // If the current audio device is not the one we want...
            //
            // Note: here we use self.getCurrentAudioDevice() and not self.videoDevice because
            // we'll only update self.videoDevice (and fire the corresponding delegate callback)
            // *after* applying our configuration. We don't want to broadcast brief transient
            // periods of routing through a non-preferred device.
           
        } catch {
            Logger.shared.error("Error configuring audio session")
        }
    }
    
    // swiftlint:disable:next function_body_length cyclomatic_complexity
    internal func applyConfiguration() throws {
        //FIXME: implement
        
    }
    
    // MARK: - Available Devices
    
    private func captureDevice(forPosition position: AVCaptureDevice.Position = .front) -> AVCaptureDevice? {
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInDualCamera, .builtInWideAngleCamera, .builtInTelephotoCamera, .builtInTrueDepthCamera],
            mediaType: .video,
            position: position
        )
        return discoverySession.devices.first { $0.position == position }
    }
}
