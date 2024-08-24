//
//  ChatItemClipShape.swift
//  SimpleX (iOS)
//
//  Created by Levitating Pineapple on 04/07/2024.
//  Copyright © 2024 SimpleX Chat. All rights reserved.
//

import SwiftUI
import SimpleXChat

/// Modifier, which provides clipping mask for ``ChatItemWithMenu`` view 
/// and it's previews: (drag interaction, context menu, etc.)
/// Supports [Dynamic Type](https://developer.apple.com/documentation/uikit/uifont/scaling_fonts_automatically)
/// by retaining pill shape, even when ``ChatItem``'s height is less that twice its corner radius
struct ChatItemClipped: ViewModifier {
    @AppStorage(DEFAULT_CHAT_ITEM_ROUNDNESS) private var roundness = defaultChatItemRoundness
    @AppStorage(DEFAULT_CHAT_ITEM_TAIL) private var isTailEnabled = true

    let chatItem: ChatItem?
    let isTailVisible: Bool

    init() {
        chatItem = nil
        isTailVisible = false
    }

    init(_ chatItem: ChatItem, isTailVisible: Bool) {
        self.chatItem = chatItem
        self.isTailVisible = isTailVisible
    }

    fileprivate func itemShape() -> ChatItemShape {
        if let chatItem {
            switch chatItem.content {
            case
                .sndMsgContent,
                .rcvMsgContent,
                .rcvDecryptionError,
                .rcvGroupInvitation,
                .sndGroupInvitation,
                .sndDeleted,
                .rcvDeleted,
                .rcvIntegrityError,
                .sndModerated,
                .rcvModerated,
                .rcvBlocked,
                .invalidJSON: isTailEnabled
                ? .bubble(
                    padding: chatItem.chatDir.sent ? .trailing : .leading,
                    isTailVisible: Self.hidesTail(chatItem.content.msgContent)
                    ? false
                    : isTailVisible
                )
                : .roundRect(maxRadius: ChatBubble.maxRadius)
            default: .roundRect(maxRadius: 8)
            }
        } else {
            .roundRect(maxRadius: 8)
        }
    }
    
    // Tail is hidden for images and video without any text
    private static func hidesTail(_ msgContent: MsgContent?) -> Bool {
        if let msgContent, msgContent.isImageOrVideo && msgContent.text.isEmpty {
            true
        } else {
            false
        }
    }

    func body(content: Content) -> some View {
        let shape = ChatBubble(roundness: roundness, shapePath: itemShape())
        content
            .contentShape(.dragPreview, shape)
            .contentShape(.contextMenuPreview, shape)
            .clipShape(shape)
    }
}

struct ChatTailPadding: ViewModifier {
    @AppStorage(DEFAULT_CHAT_ITEM_TAIL) private var tailEnabled = true
    let chatItem: ChatItem

    func body(content: Content) -> some View {
        if tailEnabled {
            content.padding(
                chatItem.chatDir.sent ? .trailing : .leading,
                ChatBubble.tailSize
            )
        } else {
            content
        }
    }
}

struct ChatBubble: Shape {
    static let tailSize: Double = 8
    static let maxRadius: Double = 16
    fileprivate let roundness: Double
    fileprivate let shapePath: ChatItemShape

    func path(in rect: CGRect) -> Path {
        switch shapePath {
        case .bubble(let padding, let isTailVisible):
            let rMax = min(Self.maxRadius, min(rect.width, rect.height) / 2)
            let r = roundness * rMax
            let tailHeight = rect.height - (Self.tailSize + (rMax - Self.tailSize) * roundness)
            var path = Path()
            path.addArc(
                center: CGPoint(x: r + Self.tailSize, y: r),
                radius: r,
                startAngle: .degrees(270),
                endAngle: .degrees(180),
                clockwise: true
            )
            if isTailVisible {
                path.addLine(
                    to: CGPoint(x: Self.tailSize, y: tailHeight)
                )
                path.addQuadCurve(
                    to: CGPoint(x: 0, y: rect.height),
                    control: CGPoint(x: Self.tailSize, y: tailHeight + r * 0.64)
                )
            } else {
                path.addArc(
                    center: CGPoint(x: r + Self.tailSize, y: rect.height - r),
                    radius: r,
                    startAngle: .degrees(180),
                    endAngle: .degrees(90),
                    clockwise: true
                )
            }
            path.addArc(
                center: CGPoint(x: rect.width - r, y: rect.height - r),
                radius: r,
                startAngle: .degrees(90),
                endAngle: .degrees(0),
                clockwise: true
            )
            path.addArc(
                center: CGPoint(x: rect.width - r, y: r),
                radius: r,
                startAngle: .degrees(0),
                endAngle: .degrees(270),
                clockwise: true
            )
            return switch padding {
            case .leading: path
            case .trailing: path
                    .scale(x: -1, y: 1, anchor: .center)
                    .path(in: rect)
            }
        case let .roundRect(radius):
            return Path(roundedRect: rect, cornerRadius: radius * roundness)
        }
    }
}

fileprivate enum ChatItemShape {
    case bubble(padding: HorizontalEdge, isTailVisible: Bool)
    case roundRect(maxRadius: Double)
}
