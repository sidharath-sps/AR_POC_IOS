//
//  UIKitExtensions.swift
//  AugmentedRealityAppPOC
//
//  Created by Sharandeep Singh on 11/06/24.
//

import UIKit
import Compression
import NVActivityIndicatorView

extension Date {
    
    /// Helps to generate the time stamp based on date
    /// - Returns: Time Stamp of type String
    func getTimeStamp() -> String {
        let dateFormatter = DateFormatter()
        //FIXME: - Remove Constant from here keep it in separate file
        dateFormatter.dateFormat = "yyyyMMddHHmmssSSS"
        return dateFormatter.string(from: self)
    }
}


extension Data {
    
    /// This method helps to compress the data to manage the size of large data
    /// - Returns: Compressed data which is optional
    func compress() -> Data? {
        var sourceBuffer = [UInt8](self)
        let sourceSize = self.count
        
        let destinationBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: sourceSize)
        let destinationSize = compression_encode_buffer(
            destinationBuffer,
            sourceSize,
            &sourceBuffer,
            sourceSize,
            nil,
            COMPRESSION_ZLIB
        )
        
        guard destinationSize != 0 else {
            return nil
        }
        
        return Data(bytes: destinationBuffer, count: destinationSize)
    }
    
    /// Helps to convert data to it's original form which is compressed using compress() method
    /// - Returns: Compressed data which is optional
    func decompress() -> Data? {
        var sourceBuffer = [UInt8](self)
        let sourceSize = self.count
        
        let destinationBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: sourceSize * 2)
        let destinationSize = compression_decode_buffer(
            destinationBuffer,
            sourceSize * 2,
            &sourceBuffer,
            sourceSize,
            nil,
            COMPRESSION_ZLIB
        )
        
        guard destinationSize != 0 else {
            return nil
        }
        
        return Data(bytes: destinationBuffer, count: destinationSize)
    }
}


extension UIViewController {
    
    /// This struct helps to store views with in this extension so that these views can be easily accessed from
    ///  any other method with in the scope. These views are required for startLoading and stopLoading.
    private struct LoaderProperties {
        static var loadingView: NVActivityIndicatorView?
        static var backgroundView: UIView?
    }
    
    /// This method can be used to freeze the screen and show a loader to give illusion to user that data is loading
    func startLoading() {
        setupActivityIndicatorView()
        LoaderProperties.loadingView?.startAnimating()
    }
    
    /// This method helps to setup ui for loader, which we display using startLoading() mehtod
    private func setupActivityIndicatorView() {
        guard LoaderProperties.backgroundView == nil, LoaderProperties.loadingView == nil else { return }
        
        let backgroundView = UIView()
                
        backgroundView.backgroundColor = UIColor(white: 0, alpha: 0.5)
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backgroundView)
        NSLayoutConstraint.activate([
            backgroundView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor)
        ])
        LoaderProperties.backgroundView = backgroundView
        
        var loadingView: NVActivityIndicatorView
        let size: CGFloat = 50.0
        let frame = CGRect(
            x: (view.frame.width - size) / 2,
            y: (view.frame.height - size) / 2,
            width: size,
            height: size
        )

        loadingView = NVActivityIndicatorView(
            frame: frame,
            type: .ballPulseSync,
            color: .brandPink,
            padding: 0
        )
        
        backgroundView.addSubview(loadingView)
        LoaderProperties.loadingView = loadingView
    }
    
    /// This method can be used to dismiss loader which is started displaying using startLoading() method
    func stopLoading() {
        LoaderProperties.loadingView?.stopAnimating()
        LoaderProperties.backgroundView?.removeFromSuperview()
        
        LoaderProperties.loadingView = nil
        LoaderProperties.backgroundView = nil
    }
    
    /// Helps to show alerts to the user, this method can be called directly form ViewControllers
    /// - Parameters:
    ///   - type: The type of alert we want to display
    ///   - completion: An optional call back method. Called when user taps on "OK" button
    func showAlert(ofType type: Alerts, completion: (() -> Void)? = nil) {
        let alertMessage = AlertMessages.giveMessage(ofType: type)
        let title = alertMessage.title
        let message = alertMessage.message
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let alertAction = UIAlertAction(title: "OK", style: .cancel) { _ in
            completion?()
        }
        
        alertController.addAction(alertAction)
        
        present(alertController, animated: true)
    }
    
    /// Dismisses the keyboard if user touches outside the keyboard
    func dismissKeyboardWhenTouchedAround() {
        let tapRecogniser = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapRecogniser.cancelsTouchesInView = false
        view.addGestureRecognizer(tapRecogniser)
    }
    
    /// Called when keyboard needs to dismiss
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    func showToast(ofType type: Alerts, duration: TimeInterval = 2.0) {
        let message = AlertMessages.giveMessage(ofType: type).message
        
        // Create a container view for the toast
        let toastContainer = UIView()
        toastContainer.backgroundColor = UIColor.lightGray.withAlphaComponent(0.9)
        toastContainer.layer.cornerRadius = 10
        toastContainer.clipsToBounds = true
        
        // Create a label for the message
        let toastLabel = UILabel()
        toastLabel.text = message
        toastLabel.textColor = .black
        toastLabel.textAlignment = .center
        toastLabel.font = UIFont.systemFont(ofSize: 14)
        toastLabel.numberOfLines = 0
        
        // Add the label to the container
        toastContainer.addSubview(toastLabel)
        toastLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Set constraints for the label within the container
        NSLayoutConstraint.activate([
            toastLabel.leadingAnchor.constraint(equalTo: toastContainer.leadingAnchor, constant: 10),
            toastLabel.trailingAnchor.constraint(equalTo: toastContainer.trailingAnchor, constant: -10),
            toastLabel.topAnchor.constraint(equalTo: toastContainer.topAnchor, constant: 10),
            toastLabel.bottomAnchor.constraint(equalTo: toastContainer.bottomAnchor, constant: -10)
        ])
        
        // Add the container to the view controller's view
        self.view.addSubview(toastContainer)
        toastContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // Set constraints for the container view at the top of the view controller's view
        NSLayoutConstraint.activate([
            toastContainer.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            toastContainer.widthAnchor.constraint(lessThanOrEqualTo: self.view.widthAnchor, constant: -40),
            toastContainer.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: -40)
        ])
        
        // Set initial transparency and animate
        toastContainer.alpha = 0.0
        UIView.animate(withDuration: 0.5, delay: 0.0, options: .curveEaseOut, animations: {
            toastContainer.alpha = 1.0
        }) { _ in
            UIView.animate(withDuration: 0.5, delay: duration, options: .curveEaseIn, animations: {
                toastContainer.alpha = 0.0
            }) { _ in
                toastContainer.removeFromSuperview()
            }
        }
    }
}


extension UIView {
    
    /// Unhides the view with animation
    func showWithAnimation() {
        isHidden = false
        UIView.animate(withDuration: 0.2) { self.alpha = 1 }
    }
    
    /// Hides the view with animation
    func hideWithAnimation() {
        UIView.animate(withDuration: 0.2, animations: { self.alpha = 0 }) { _ in
            self.isHidden = true
        }
    }
}


extension UITextView {
    
    /// Check if text view is empty or not
    /// - Returns: True if text view is not empty otherwise returns false
    func isNotEmpty() -> Bool {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return false
        }
        
        return true
    }
    
    /// Sets text view empty
    func setEmpty() {
        text = ""
    }
}
