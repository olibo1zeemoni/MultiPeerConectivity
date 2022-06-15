//
//  ViewController.swift
//  Project25
//
//  Created by Olibo moni on 28/02/2022.
//

import MultipeerConnectivity
import UIKit

class ViewController: UICollectionViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate, MCSessionDelegate, MCBrowserViewControllerDelegate, MCNearbyServiceAdvertiserDelegate {
    
    
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        let ac = UIAlertController(title: title, message: "\(peerID.displayName) wants to connect", preferredStyle: .alert)

            ac.addAction(UIAlertAction(title: "Allow", style: .default, handler: { [weak self] _ in
                invitationHandler(true, self?.mcSession)
            }))

            ac.addAction(UIAlertAction(title: "Decline", style: .cancel, handler: { _ in
                invitationHandler(false, nil)
            }))

            present(ac, animated: true)
    }
    
   
    
    
    var images = [UIImage]()
    var peerID: MCPeerID?
    var mcSession: MCSession?
    //var mcAdvertiserAssistant: MCAdvertiserAssistant?
    var mcAdAssistant: MCNearbyServiceAdvertiser?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Selfie Share"
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .camera, target: self, action: #selector(importPicture))
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(showConnectionPrompt))
        
        peerID = MCPeerID(displayName: UIDevice.current.name)
        
        mcSession = MCSession(peer: peerID!, securityIdentity: nil, encryptionPreference: .required)
        mcSession?.delegate = self
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageView", for: indexPath)
        if let imageView = cell.viewWithTag(1000) as? UIImageView {
            imageView.image = images[indexPath.item]
        }
        
        return cell
            
    }
    
    
    @objc func importPicture(){
        let picker = UIImagePickerController()
        picker.allowsEditing = true
        picker.delegate = self
        present(picker, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[.editedImage] as? UIImage else { return }
        dismiss(animated: true)
        images.insert(image, at: 0)
        collectionView.reloadData()
        
        guard let mcSession = mcSession else {
            return
        }
        
        if mcSession.connectedPeers.count > 0 {
            if let imageData = image.pngData() {
                do {
                    try mcSession.send(imageData, toPeers: mcSession.connectedPeers, with: .reliable)
                } catch {
                    let ac = UIAlertController(title: "Send Error", message: error.localizedDescription, preferredStyle: .alert)
                    ac.addAction(UIAlertAction(title: "Ok", style: .default))
                    present(ac, animated: true)
                    
                }
            }
        }

        
    }
    
    
    @objc func showConnectionPrompt(){
        let ac = UIAlertController(title: "Connect to others", message: nil, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "host a session", style: .default, handler: { action in
            self.startHosting(action: action)
        }))
        ac.addAction(UIAlertAction(title: "join a session", style: .default, handler: { action in
            self.joinSession(action: action)
        }))
        ac.addAction(UIAlertAction(title: "Send a message", style: .default, handler: sendMessage))
        ac.addAction(UIAlertAction(title: "show connected devices", style: .default, handler: showConnectedDevices))
        ac.addAction(UIAlertAction(title: "Dismiss", style: .cancel))
        
        present(ac, animated: true)
    }
    
    func startHosting(action: UIAlertAction){
        guard mcSession != nil else { return }

        //mcAdvertiserAssistant = MCAdvertiserAssistant(serviceType: "zm-project25", discoveryInfo: nil, session: mcSession)
       // mcAdvertiserAssistant?.start()
        mcAdAssistant = MCNearbyServiceAdvertiser(peer: peerID!, discoveryInfo: nil, serviceType: "zm-project25" )
        mcAdAssistant?.delegate = self
        mcAdAssistant?.startAdvertisingPeer()
    }
    
    func joinSession(action: UIAlertAction){
        guard let mcSession = mcSession else { return }
        let mcBrowser = MCBrowserViewController(serviceType: "zm-project25", session: mcSession)
        mcBrowser.delegate = self
        present(mcBrowser, animated: true)
        
    }
    
    @objc func showConnectedDevices(action: UIAlertAction){
        //guard mcSession != nil else { return }
        let connectedDevices = mcSession?.connectedPeers.map{ $0.displayName}.joined(separator: " , ")
        let ac = UIAlertController(title: "Connected Devices", message: connectedDevices, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "Dismiss", style: .cancel))
        present(ac, animated: true)
    }
    
   @objc func sendMessage(action: UIAlertAction){
       let ac = UIAlertController(title: "Send Message", message: nil, preferredStyle: .alert)
       ac.addTextField()
       ac.addAction(UIAlertAction(title: "Send", style: .default, handler: { [weak self, weak ac] action in
           guard let text = ac?.textFields?.first?.text else { return}
           guard let mcSession = self?.mcSession else { return }
           do {
               try mcSession.send(Data(text.utf8), toPeers: mcSession.connectedPeers, with: .reliable)
           } catch {
               let ac = UIAlertController(title: "Failed to send Message", message: nil, preferredStyle: .alert)
               ac.addAction(UIAlertAction(title: "Ok", style: .default))
               self?.present(ac, animated: true)
           }
          

       }))
       present(ac, animated: true)
    }
    
    //three session states
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state {
        
        case .connecting:
            print("Connecting \(peerID.displayName)")
        case .connected:
            print("Connected \(peerID.displayName)")
        case .notConnected:
            DispatchQueue.main.async {
                            [weak self] in
                            let ac = UIAlertController(title: "\(peerID.displayName) has disconnected", message: nil, preferredStyle: .alert)
                            ac.addAction(UIAlertAction(title: "OK", style: .default))
                            self?.present(ac, animated: true)

                        }
            print("Not Connected \(peerID.displayName)")
        @unknown default:
            print("Unknown state \(peerID.displayName)")
        }
    }
    
   
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        DispatchQueue.main.async { [weak self] in
            if let image = UIImage(data: data) {
                self?.images.insert(image, at: 0)
                self?.collectionView.reloadData()
            }
            
             let text = String(decoding: data, as: UTF8.self)
            let ac = UIAlertController(title: "\(text)", message: nil, preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "Dismiss", style: .cancel))
            self?.present(ac, animated: true)
            
            
        }
    }
    
    
    //not required
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
       
    }
    
    //not required
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
    
    }
    
    //not required
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
    }
    
    func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
        dismiss(animated: true)
    }
    
    func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
        dismiss(animated: true)
    }


}

