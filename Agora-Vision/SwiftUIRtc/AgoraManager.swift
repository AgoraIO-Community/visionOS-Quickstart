//
//  AgoraManager.swift
//  Agora-Vision
//
//  Created by Max Cobb on 11/13/23.
//

import Foundation
import AgoraRtcKit

/// ``AgoraManager`` is a class that provides an interface to the Agora RTC Engine Kit.
/// It conforms to the `ObservableObject` and `AgoraRtcEngineDelegate` protocols.
///
/// Use AgoraManager to set up and manage Agora RTC sessions, manage the client's role,
/// and control the client's connection to the Agora RTC server.
open class AgoraManager: NSObject, ObservableObject, AgoraRtcEngineDelegate {
    /// 📲 The Agora App ID for the session.
    public let appId: String
    /// 🎭 The client's role in the session.
    public var role: AgoraClientRole = .audience {
        didSet { updateClientRole() }
    }
    /// 🔢 Integer ID of the local user.
    @Published public var localUserId: UInt = 0
    /// 📞 The Agora RTC Engine Kit for the session.
    public internal(set) var agoraEngine: AgoraRtcEngineKit!

    @available(*, deprecated, renamed: "agoraEngine")
    public var engine: AgoraRtcEngineKit { self.agoraEngine }

    /// 🧍‍♂️ The set of all users in the channel.
    @Published public var allUsers: Set<UInt> = []

    /// 🚀 Initializes and configures the Agora RTC Engine Kit.
    ///
    /// - Returns: The configured AgoraRtcEngineKit instance.
    open func engineSetup() -> AgoraRtcEngineKit {
        let eng = AgoraRtcEngineKit.sharedEngine(withAppId: appId, delegate: self)
        eng.enableVideo()
        eng.setClientRole(role)
        let version = AgoraRtcEngineKit.getSdkVersion()
        print ("Agora Video SDK version:" + version)
        return eng
    }

    private func initializeAgoraEngine() {
        agoraEngine = engineSetup()
    }

    /// 🔄 Updates the client's role in the Agora RTC Engine Kit.
    open func updateClientRole() {
        agoraEngine.setClientRole(role)
    }

    /// 🏁 Initializes a new instance of `AgoraManager` with the specified app ID and client role.
    ///
    /// - Parameters:
    ///   - appId: The Agora App ID for the session.
    ///   - role: The client's role in the session. The default value is `.audience`.
    public init(appId: String, role: AgoraClientRole = .audience) {
        self.appId = appId
        self.role = role
        super.init()
        self.initializeAgoraEngine()
    }

    /// 🚪 Joins a channel, starting the connection to an RTC session.
    /// - Parameters:
    ///   - channel: Name of the channel to join.
    ///   - token: Token to join the channel, this can be nil for a weak security testing session.
    ///   - uid: User ID of the local user. This can be 0 to allow the engine to automatically assign an ID.
    ///   - info: Info is currently unused by RTC, it is reserved for future use.
    /// - Returns: 0 if no error joining channel, &lt; 0 if there was an error.
    @discardableResult
    open func joinChannel(
        _ channel: String, token: String? = nil, uid: UInt = 0, info: String? = nil
    ) -> Int32 {
        self.agoraEngine.joinChannel(byToken: token, channelId: channel, info: info, uid: uid)
    }

    /// 🚪 Leaves the channel and stops the preview for the session.
    ///
    /// - Parameters:
    ///   - leaveChannelBlock: An optional closure that will be called when the client leaves the channel.
    ///     The closure takes an `AgoraChannelStats` object as its parameter.
    ///   - destroyEngine: A flag indicating whether to destroy the Agora RTC Engine Kit after leaving the channel.
    ///     The default value is `true`.
    ///
    /// - Returns: The result of leaving the channel. Returns 0 if there is no error, and a negative value if there was an error.
    @discardableResult
    open func leaveChannel(
        leaveChannelBlock: ((AgoraChannelStats) -> Void)? = nil,
        destroyEngine: Bool = true
    ) -> Int32 {
        let leaveErr = self.agoraEngine.leaveChannel(leaveChannelBlock)
        self.agoraEngine.stopPreview()
        defer { if destroyEngine { AgoraRtcEngineKit.destroy() } }
        self.allUsers.removeAll()
        return leaveErr
    }

    // MARK: - AgoraRtcEngineDelegate

    /// 📞 The local user has successfully joined the channel.
    /// - Parameters:
    ///   - engine: The Agora RTC engine kit object.
    ///   - channel: The channel name.
    ///   - uid: The ID of the user joining the channel.
    ///   - elapsed: The time elapsed (ms) from the user calling `joinChannel` until this method is called.
    ///
    /// If the client's role is `.broadcaster`, this method also adds the broadcaster's userId (``localUserId``) to the ``allUsers`` set.
    open func rtcEngine(
        _ engine: AgoraRtcEngineKit, didJoinChannel channel: String,
        withUid uid: UInt, elapsed: Int
    ) {
        self.localUserId = uid
        if self.role == .broadcaster {
            self.allUsers.insert(uid)
        }
        print ("user did joined channel: " + String(uid))
    }

    /// 📞 A remote user has joined the channel.
    ///
    /// - Parameters:
    ///   - engine: The Agora RTC engine kit object.
    ///   - uid: The ID of the user joining the channel.
    ///   - elapsed: The time elapsed (ms) from the user calling `joinChannel` until this method is called.
    ///
    /// This method adds the remote user to the `allUsers` set.
    open func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinedOfUid uid: UInt, elapsed: Int) {
        self.allUsers.insert(uid)
        print ("user uid joined channel: " + String(uid))
    }

    /// 📞 A remote user has left the channel.
    ///
    /// - Parameters:
    ///   - engine: The Agora RTC engine kit object.
    ///   - uid: The ID of the user who left the channel.
    ///   - reason: The reason why the user left the channel.
    ///
    /// This method removes the remote user from the `allUsers` set.
    open func rtcEngine(_ engine: AgoraRtcEngineKit, didOfflineOfUid uid: UInt, reason: AgoraUserOfflineReason) {
        self.allUsers.remove(uid)
        print ("user left channel: " + String(uid))
    }
}
