//
//  MemoViewController.swift
//  CloudNotes
//
//  Created by duckbok on 2021/06/02.
//

import UIKit

final class MemoViewController: UIViewController {

    // MARK: Property

    weak var delegate: MemoViewControllerDelegate?
    var memoData: MemoData = MemoData.sample

    var isTextViewHidden: Bool { textView.isHidden }

    private var memoInfo: MemoData.MemoInfo?

    // MARK: UI

    private let moreActionButton = UIBarButtonItem(title: Style.moreActionButtonTitle, image: Style.moreActionButtonImage, primaryAction: nil, menu: nil)

    private let textView: UITextView = {
        let textView = UITextView()
        textView.backgroundColor = Style.textViewBackgroundColor
        textView.font = Style.textViewFont
        textView.isEditable = true
        textView.isHidden = true
        textView.textContainerInset = Style.textViewTextContainerInset
        textView.translatesAutoresizingMaskIntoConstraints = false
        return textView
    }()

    // MARK: Initializer

    init() {
        super.init(nibName: nil, bundle: nil)
        navigationItem.setRightBarButton(moreActionButton, animated: true)

        NotificationCenter.default.addObserver(self, selector: #selector(textViewMoveUp), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(textViewMoveDown), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    // MARK: View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        configureTextView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureBackgroundColor(by: traitCollection.horizontalSizeClass)
    }

    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)
        configureBackgroundColor(by: newCollection.horizontalSizeClass)
    }

    // MARK: Configure

    private func configure(memoInfo: MemoData.MemoInfo) {
        self.memoInfo = memoInfo
        configureTextViewText(by: memoInfo.memo)
        resetScrollOffset()
    }

    private func configureTextView() {
        textView.delegate = self

        view.addSubview(textView)
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.topAnchor),
            textView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func configureBackgroundColor(by sizeClass: UIUserInterfaceSizeClass) {
        view.backgroundColor = (sizeClass == .compact) ? Style.compactViewBackgroundColor : Style.commonViewBackgroundColor
    }

    private func configureTextViewText(by memo: Memo) {
        guard false == memo.title.isEmpty else { return textView.text = nil }

        textView.text = memo.title + "\(Style.memoSeparator)" + memo.body
    }

    private func resetScrollOffset() {
        let topOffset = CGPoint(x: 0, y: -view.safeAreaInsets.top)
        textView.setContentOffset(topOffset, animated: false)
    }

    // MARK: Keyboard observing

    @objc private func textViewMoveUp(_ notification: NSNotification) {
        guard let userInfo = notification.userInfo,
              let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }

        let contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardFrame.size.height, right: 0)
        textView.contentInset = contentInset
        textView.scrollIndicatorInsets = contentInset
    }

    @objc private func textViewMoveDown() {
        let contentInset = UIEdgeInsets.zero
        textView.contentInset = contentInset
        textView.scrollIndicatorInsets = contentInset
    }

}

// MARK: - UITextViewDelegate

extension MemoViewController: UITextViewDelegate {

    func textViewDidChange(_ textView: UITextView) {
        guard let textViewText = textView.text,
              let seperatedMemo = separatedMemo(from: textViewText),
              let memoInfo = memoInfo else { return }

        let row: Int = memoData.indexByRecentModified(where: memoInfo.id)
        memoData.updateMemo(Memo(title: seperatedMemo.title, body: seperatedMemo.body), where: memoInfo.id)
        delegate?.memoViewController(self, didChangeMemoAt: row)
    }

    private func separatedMemo(from text: String) -> (title: String, body: String)? {
        let separatedText: [Substring] = text.split(separator: Style.memoSeparator, maxSplits: 1, omittingEmptySubsequences: true)
        guard let separatedTitle = separatedText.first else { return nil }
        let title = String(separatedTitle)
        let body = separatedText.count == 2 ? String(separatedText[1]) : String()

        return (title, body)
    }

}

// MARK: - MemoListViewControllerDelegate {

extension MemoViewController: MemoListViewControllerDelegate {

    func memoListViewControllerWillHideMemo(_ memoListViewController: MemoListViewController) {
        textView.isHidden = true
        textView.resignFirstResponder()
    }

    func memoListViewController(_ memoListViewController: MemoListViewController, willShowMemoAt row: Int) {
        configure(memoInfo: memoData.memosByRecentModified[row])
        textView.isHidden = false
        textView.resignFirstResponder()
    }

}

// MARK: - Style

extension MemoViewController {

    enum Style {
        static let moreActionButtonTitle: String = "more"
        static let moreActionButtonImage: UIImage = UIImage(systemName: "ellipsis.circle") ?? .actions

        static let textViewBackgroundColor: UIColor = .clear
        static let textViewFont: UIFont = UIFont.preferredFont(forTextStyle: .body)
        static let textViewTextContainerInset: UIEdgeInsets = UIEdgeInsets(top: 15, left: 15, bottom: 15, right: 15)

        static let commonViewBackgroundColor: UIColor = .systemBackground
        static let compactViewBackgroundColor: UIColor = .systemGray3

        static let updatedMemoRow: Int = 0

        static let memoSeparator: Character = "\n"
    }

}
