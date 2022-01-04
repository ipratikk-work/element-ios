// 
// Copyright 2021 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Foundation
import Reusable

@objc
protocol ThreadSummaryViewDelegate: AnyObject {
    func threadSummaryViewTapped(_ summaryView: ThreadSummaryView)
}

/// A view to display a summary for an `MXThread` generated by the `MXThreadingService`.
@objcMembers
class ThreadSummaryView: UIView {
    
    private enum Constants {
        static let viewHeight: CGFloat = 40
        static let viewDefaultWidth: CGFloat = 320
        static let cornerRadius: CGFloat = 4
    }
    
    @IBOutlet private weak var iconView: UIImageView!
    @IBOutlet private weak var numberOfRepliesLabel: UILabel!
    @IBOutlet private weak var lastMessageAvatarView: UserAvatarView!
    @IBOutlet private weak var lastMessageContentLabel: UILabel!
    
    private(set) var thread: MXThread!
    
    private lazy var tapGestureRecognizer: UITapGestureRecognizer = {
        return UITapGestureRecognizer(target: self, action: #selector(tapped(_:)))
    }()
    
    weak var delegate: ThreadSummaryViewDelegate?
    
    // MARK: - Setup
    
    init(withThread thread: MXThread) {
        self.thread = thread
        super.init(frame: CGRect(origin: .zero,
                                 size: CGSize(width: Constants.viewDefaultWidth,
                                              height: Constants.viewHeight)))
        loadNibContent()
        update(theme: ThemeService.shared().theme)
        configure()
    }
    
    static func contentViewHeight(forThread thread: MXThread, fitting maxWidth: CGFloat) -> CGFloat {
        return Constants.viewHeight
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        loadNibContent()
    }
    
    @nonobjc func configure(withViewModel viewModel: ThreadSummaryViewModel) {
        numberOfRepliesLabel.text = String(viewModel.numberOfReplies)
        if let avatar = viewModel.lastMessageSenderAvatar {
            lastMessageAvatarView.fill(with: avatar)
        } else {
            lastMessageAvatarView.avatarImageView.image = nil
        }
        lastMessageContentLabel.text = viewModel.lastMessageText
    }
    
    private func configure() {
        clipsToBounds = true
        layer.cornerRadius = Constants.cornerRadius
        addGestureRecognizer(tapGestureRecognizer)
        
        guard let thread = thread,
              let lastMessage = thread.lastMessage,
              let session = thread.session,
              let eventFormatter = session.roomSummaryUpdateDelegate as? MXKEventFormatter,
              let room = session.room(withRoomId: lastMessage.roomId) else {
            lastMessageAvatarView.avatarImageView.image = nil
            lastMessageContentLabel.text = nil
            return
        }
        let lastMessageSender = session.user(withUserId: lastMessage.sender)
        
        let fallbackImage = AvatarFallbackImage.matrixItem(lastMessage.sender,
                                                           lastMessageSender?.displayname)
        let avatarViewData = AvatarViewData(matrixItemId: lastMessage.sender,
                                            displayName: lastMessageSender?.displayname,
                                            avatarUrl: lastMessageSender?.avatarUrl,
                                            mediaManager: session.mediaManager,
                                            fallbackImage: fallbackImage)
        
        room.state { [weak self] roomState in
            guard let self = self else { return }
            let formatterError = UnsafeMutablePointer<MXKEventFormatterError>.allocate(capacity: 1)
            let lastMessageText = eventFormatter.string(from: lastMessage, with: roomState, error: formatterError)
            
            let viewModel = ThreadSummaryViewModel(numberOfReplies: thread.numberOfReplies,
                                                   lastMessageSenderAvatar: avatarViewData,
                                                   lastMessageText: lastMessageText)
            self.configure(withViewModel: viewModel)
        }
    }
    
    // MARK: - Action
    
    @objc
    private func tapped(_ sender: UITapGestureRecognizer) {
        guard thread != nil else { return }
        delegate?.threadSummaryViewTapped(self)
    }
}

// extension ThreadSummaryView: NibLoadable {}

extension ThreadSummaryView: NibOwnerLoadable {}

extension ThreadSummaryView: Themable {
    
    func update(theme: Theme) {
        backgroundColor = theme.colors.system
        iconView.tintColor = theme.colors.secondaryContent
        numberOfRepliesLabel.textColor = theme.colors.secondaryContent
        lastMessageContentLabel.textColor = theme.colors.secondaryContent
    }
    
}
