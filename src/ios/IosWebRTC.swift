//
//  DemoIonic.swift
//  WebRTCDemo
//
//  Created by kishore on 13/06/18.
//  Copyright © 2018 Innotical  Solutions . All rights reserved.
//

import Foundation
// import UIKit
import AVFoundation
//import MobileCoreServices
//import Starscream
import WebRTC

let TAG: String = "SACHIN"
let SCREEN_WIDTH = UIScreen.main.bounds.width
let SCREEN_HEIGHT = UIScreen.main.bounds.height

@objc(IosWebRTC) class IosWebRTC : CDVPlugin , RTCClientDelegate  {
    
    var callView : UIView!
    var callImageView : UIImageView!
    var callLocalView : RTCEAGLVideoView!
    var callRemoteView : RTCEAGLVideoView!
    var upperNavView : UIView!
    var currentStatusLabel : UILabel!
    var doctorLabel : UILabel!
    var familyCareCallType : UILabel!
    var acceptBtn : UIImageView!
    var rejectBtn : UIImageView!
    var localMediaStream: RTCMediaStream!
    var localVideoTrack1 : RTCVideoTrack!
    var remoteVideoTrack  : RTCVideoTrack!
    var videoClient: RTCClient?
    var captureController: RTCCapturer!
    var sdpOffer = ""
    var isCallComing = false
    var isVideoCall = true
    var callBckCommand : CDVInvokedUrlCommand!
    var callTimer : Timer!
    var countSec = 0
    var countMin = 0
    var countHr = 0
    var isAccepted = false
    
    func echo(_ command: CDVInvokedUrlCommand) {
        self.callBckCommand = command
        var pluginResult = CDVPluginResult(
            status: CDVCommandStatus_ERROR,
            messageAs: "error"
        )
        let msg = command.arguments[0] as? String ?? ""
        print("Working_________________", msg)
        
        self.handleMsgFromIonic(msg: msg)
        
        pluginResult = CDVPluginResult(
            status: CDVCommandStatus_OK,
            messageAs: "stream is : " + "\(self.localVideoTrack1)"
        )
        
        self.commandDelegate!.send(
            pluginResult,
            callbackId: command.callbackId
        )
    }
    
    override func awakeFromNib() {
        setAudioOutputSpeaker()
    }
    
    func configureVideoClient() {
        let stunServer : String = "stun:172.104.169.138:443"
        let iceServers = RTCIceServer.init(urlStrings: [stunServer], username: "", credential: "")
        print(iceServers)
        let client = RTCClient.init(iceServers: [iceServers], videoCall: self.isVideoCall)
        client.delegate = self
        self.videoClient = client
        client.startConnection()
        print(TAG,"configureVideoClient")
        
    }
    func rtcClient(client: RTCClient, didCreateLocalCapturer capturer: RTCCameraVideoCapturer) {
        let settingsModel = RTCCapturerSettingsModel()
        self.captureController = RTCCapturer.init(withCapturer: capturer, settingsModel: settingsModel)
        captureController.startCapture()
    }
    func rtcClient(client : RTCClient, didReceiveError error: Error) {
        print(TAG,"didReceiveError")
    }
    func rtcClient(client : RTCClient, didGenerateIceCandidate iceCandidate: RTCIceCandidate) {
        print(TAG,"iceCandidate")
        print(iceCandidate)
        DispatchQueue.main.async {
            let candidate = ["candidate" : iceCandidate.sdp,
                             "sdpMid" : iceCandidate.sdpMid ?? "",
                             "sdpMLineIndex" : iceCandidate.sdpMLineIndex] as [String : Any]
            let dict : [String : Any] = ["type":"iceCandidate",
                                         "data" : candidate]
            self.callJS(data: dict.json)
        }
    }
    
    func rtcClient(client : RTCClient, startCallWithSdp sdp: String) {
        print(sdp)
        let dict : [String : Any] = ["type":"sdp",
                                     "data" : sdp.description]
        self.callJS(data: dict.json)
    }
    
    func rtcClient(client : RTCClient, didReceiveLocalVideoTrack localVideoTrack: RTCVideoTrack) {
        print("didReceiveLocalVideoTrack",self.isVideoCall)
        if self.isVideoCall{
            setViewOfVideo()
            localVideoTrack.add(self.callLocalView)
            self.videoClient?.makeOffer()
        }
    }
    
    
    func rtcClient(client : RTCClient, didReceiveRemoteVideoTrack remoteVideoTrack: RTCVideoTrack) {
        print("didReceiveRemoteVideoTrack")
        self.callTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(ShowTimerCount), userInfo: nil, repeats: true)
        self.isAccepted = true
        if self.isVideoCall{
             DispatchQueue.main.async {
            self.callRemoteView = RTCEAGLVideoView.init(frame: CGRect(x: 0, y: 0, width: SCREEN_WIDTH, height: SCREEN_HEIGHT))
            self.callLocalView = RTCEAGLVideoView.init(frame: CGRect(x: SCREEN_WIDTH-130, y: SCREEN_HEIGHT-280, width: 120, height: 150))
           
            self.callImageView.addSubview(self.callRemoteView)
            self.callRemoteView.addSubview(self.callLocalView)
            self.callRemoteView.bringSubview(toFront: self.callLocalView)
            self.callRemoteView.alpha = 1
             remoteVideoTrack.add(self.callLocalView)
            }
        }
        
    }
    @objc func ShowTimerCount(){
        countSec = countSec + 1
        if countSec == 60{
            countSec = 0
            countMin = countMin + 1
        }
        if countMin == 60{
            countMin = 0
            countHr = countHr + 1
        }
        self.currentStatusLabel.text = "\(countHr) :  \(countMin) :  \(countSec) "
        
    }
    func setAudioOutputSpeaker(){
        try? AVAudioSession.sharedInstance().overrideOutputAudioPort(.speaker)
    }
    
    //    func remoteView(){
    //        self.callRemoteView = RTCEAGLVideoView.init(frame: CGRect(x: 0, y: 0, width: SCREEN_WIDTH, height: SCREEN_HEIGHT))
    //        self.callImageView.isHidden = true
    //        self.callImageView.addSubview(callRemoteView)
    //        self.callImageView.bringSubview(toFront: callRemoteView)
    //    }
    //    func localView(track : RTCVideoTrack){
    //        self.callLocalView = RTCEAGLVideoView.init(frame: CGRect(x: SCREEN_WIDTH-130, y: SCREEN_HEIGHT-280, width: 120, height: 150))
    //        self.callImageView.isHidden = false
    //
    //        self.callImageView.addSubview(callLocalView)
    //        track.add(self.callLocalView)
    //        self.callImageView.bringSubview(toFront: callLocalView)
    //    }
    func setViewOfVideo(){
        if self.isVideoCall{
            self.callRemoteView = RTCEAGLVideoView.init(frame: CGRect(x: 0, y: 0, width: SCREEN_WIDTH, height: SCREEN_HEIGHT))
            self.callLocalView = RTCEAGLVideoView.init(frame: CGRect(x: SCREEN_WIDTH-130, y: SCREEN_HEIGHT-280, width: 120, height: 150))
            self.callImageView.addSubview(self.callRemoteView)
            self.callImageView.addSubview(self.callLocalView)
            self.callImageView.bringSubview(toFront: self.callLocalView)
            self.callRemoteView.alpha = 0
        }
    }

    func removeStream(){
        self.videoClient?.disconnect()
    }
}
extension IosWebRTC{
    
    func addCallerView(image:String , isCallComing : Bool, appName : String , doctorName : String , status : String , rejectStr : String , acceptStr : String) {
        self.isAccepted = false
        callView = UIView.init(frame: CGRect.init(x: 0, y: 0, width: SCREEN_WIDTH, height: SCREEN_HEIGHT))
        callView.backgroundColor = UIColor.white
        callImageView = UIImageView.init(frame: CGRect.init(x: 0, y: 0, width: SCREEN_WIDTH, height: SCREEN_HEIGHT))
        if let url = URL.init(string: image){
            downloadImage(url: url, value: "user")
        }
        callImageView.contentMode = .scaleToFill
        callView.addSubview(callImageView)
        upperNavView = UIView.init(frame: CGRect.init(x: 0, y: 0, width: SCREEN_WIDTH, height: 125))
        upperNavView.alpha = 0.78
        upperNavView.backgroundColor = UIColor.darkGray
        familyCareCallType = UILabel.init(frame: CGRect.init(x: 10, y: 25, width: SCREEN_WIDTH-10, height: 22))
        familyCareCallType.text = appName
        familyCareCallType.textColor = UIColor.white
        familyCareCallType.textAlignment = .left
        familyCareCallType.font = UIFont.systemFont(ofSize: 13)
        doctorLabel = UILabel.init(frame: CGRect.init(x: 10, y: 52, width: SCREEN_WIDTH-10, height: 30))
        doctorLabel.text = doctorName
        doctorLabel.textColor = UIColor.white
        doctorLabel.textAlignment = .left
        doctorLabel.font = UIFont.systemFont(ofSize: 16)
        currentStatusLabel = UILabel.init(frame: CGRect.init(x: 10, y: 87, width: SCREEN_WIDTH-10, height: 22))
        currentStatusLabel.text = status
        currentStatusLabel.textColor = UIColor.white
        currentStatusLabel.textAlignment = .left
        currentStatusLabel.font = UIFont.systemFont(ofSize: 13)
        upperNavView.addSubview(familyCareCallType)
        upperNavView.addSubview(doctorLabel)
        upperNavView.addSubview(currentStatusLabel)
        callView.addSubview(upperNavView)
        self.acceptBtn = UIImageView.init(frame: CGRect.init(x: SCREEN_WIDTH/2-60, y: SCREEN_HEIGHT-100, width: 60, height: 60))
        if isCallComing == true{
            rejectBtn = UIImageView.init(frame: CGRect.init(x: SCREEN_WIDTH/2+20, y: SCREEN_HEIGHT-100, width: 60, height: 60))
            self.acceptBtn.isHidden = false
        }else{
            rejectBtn = UIImageView.init(frame: CGRect.init(x: SCREEN_WIDTH/2 - 40, y: SCREEN_HEIGHT-100, width: 60, height: 60))
            callView.addSubview(acceptBtn)
            self.acceptBtn.isHidden = true
        }
        let tap1 = UITapGestureRecognizer(target: self, action: #selector(acceptCall(gestureRecognizer:)))
        acceptBtn.addGestureRecognizer(tap1)
        let tap2 = UITapGestureRecognizer(target: self, action: #selector(rejectCall(gestureRecognizer:)))
        rejectBtn.addGestureRecognizer(tap2)
        acceptBtn.backgroundColor = #colorLiteral(red: 0.1843137255, green: 0.5529411765, blue: 0.168627451, alpha: 1)
        self.acceptBtn.isUserInteractionEnabled = true
        self.rejectBtn.isUserInteractionEnabled = true
        acceptBtn.contentMode = .center
        rejectBtn.contentMode = .center
        acceptBtn.layer.cornerRadius = 30
        acceptBtn.isUserInteractionEnabled = true
        rejectBtn.backgroundColor = UIColor.red
        
        rejectBtn.layer.cornerRadius = 30
        rejectBtn.clipsToBounds = true
        callView.addSubview(rejectBtn)
        callView.addSubview(acceptBtn)
        if let url = URL.init(string: acceptStr){
            downloadImage(url: url, value: "accept")
        }
        if let url = URL.init(string: rejectStr){
            downloadImage(url: url, value: "reject")
        }
        if let appl = UIApplication.shared.delegate as? CDVAppDelegate{
            appl.window.addSubview(callView)
        }
    }
    
    @objc internal func acceptCall(gestureRecognizer: UITapGestureRecognizer) {
        print("acceptCall")
        self.rejectBtn.frame = CGRect.init(x: SCREEN_WIDTH/2+20, y: SCREEN_HEIGHT-100, width: 60, height: 60)
        UIView.animate(withDuration: 0.33) {
            self.rejectBtn.frame = CGRect.init(x: SCREEN_WIDTH/2 - 40, y: SCREEN_HEIGHT-100, width: 60, height: 60)
        }
        self.acceptBtn.isHidden = true
        if self.isCallComing{
            self.configureVideoClient()
            self.currentStatusLabel.text = "Connected"
        }
    }
    
    @objc internal func rejectCall(gestureRecognizer: UITapGestureRecognizer) {
        print("rejectCall")
        self.removeStream()
        self.callView.removeFromSuperview()
        let rejectDict : [String:Any] = ["reason" : "userReject",
                                         "isAccepted" : self.isAccepted]
        let dict : [String : Any] = ["type":"cancel",
                                     "data" : rejectDict]
        self.callJS(data: dict.json)
    }
    
    func callJS(data: String) {
        let javaScript = "cordova.plugins.IosWebRTC.callbackResult(\(data))"
        DispatchQueue.main.async {
            if let appl = UIApplication.shared.delegate as? CDVAppDelegate{
                appl.viewController.webViewEngine.evaluateJavaScript(javaScript, completionHandler: { (res, err) in
                    print("response is ", res ?? "response nil")
                    print("error is ", err ?? "error nil")
                })
            }
            print("hello", data)
        }
    }
}
extension IosWebRTC  {
    func handleMsgFromIonic(msg : String){
        let value = msg.dictionary
        if let type = value["type"] as? String{
            switch type {
            case IonicTypes.incomingCall.rawValue:
                print(IonicTypes.incomingCall.rawValue)
                if let data = value["data"] as? [String : Any] {
                    let img = data["img"] as! String
                    let name = data["name"] as! String
                    let callType = data["callType"] as! String
                    let appName = data["appName"] as! String
                    let acc = data["accept"] as! String
                    let rec = data["reject"] as! String
                    if callType == "A"{
                        self.isVideoCall = false
                    }else{
                        self.isVideoCall = true
                    }
                    self.isCallComing = true
                    self.addCallerView(image: img, isCallComing: isCallComing, appName: appName, doctorName: name, status: "Incoming Call", rejectStr: rec, acceptStr: acc)
                }
            case IonicTypes.timerReject.rawValue:
                print(IonicTypes.timerReject.rawValue)
                self.removeStream()
                self.callView.removeFromSuperview()
                // self.callTimer.invalidate()
                let rejectDict : [String:Any] = ["reason" : "userReject",
                                                 "isAccepted" : self.isAccepted]
                let dict : [String : Any] = ["type":"cancel",
                                             "data" : rejectDict]
                self.callJS(data: dict.json)
            case IonicTypes.iceCandidate.rawValue:
                if let data = value["data"] as? [String : Any] {
                    self.caseOnCandidate(dict: data)
                }
            case IonicTypes.sdp.rawValue:
                if let data = value["data"] as? String {
                    self.caseOnAnswer(sdpAns: data)
                }
            case IonicTypes.call.rawValue:
                if let data = value["data"] as? [String : Any] {
                    let img = data["img"] as! String
                    let name = data["name"] as! String
                    let callType = data["callType"] as! String
                    let appName = data["appName"] as! String
                    let acc = data["accept"] as! String
                    let rec = data["reject"] as! String
                    if callType == "A"{
                        self.isVideoCall = false
                    }else{
                        self.isVideoCall = true
                    }
                    self.isCallComing = false
                    self.addCallerView(image: img, isCallComing: isCallComing, appName: appName, doctorName: name, status: "Connecting", rejectStr: rec, acceptStr: acc)
                    self.configureVideoClient()
                }
            case IonicTypes.ringing.rawValue:
                if let data = value["data"] as? [String : Any] {
                    if let text = data["text"] as? String{
                        self.currentStatusLabel.text = text
                    }
                }
            default:
                print("No type Found")
            }
        }
    }
    
    func caseOnCandidate(dict : [String : Any]){
        let mid = dict["sdpMid"] as! String
        let index = dict["sdpMLineIndex"] as! Int
        let sdp = dict["candidate"] as! String // check what tag it is coming
        let candidate : RTCIceCandidate = RTCIceCandidate.init(sdp: sdp, sdpMLineIndex: Int32(index), sdpMid: mid)
        self.videoClient?.addIceCandidate(iceCandidate: candidate)
    }
    
    
    func caseOnAnswer(sdpAns : String) -> Void {
        self.videoClient?.handleAnswerReceived(withRemoteSDP: sdpAns)
    }
}
extension IosWebRTC{
    func getDataFromUrl(url: URL, completion: @escaping (Data?, URLResponse?, Error?) -> ()) {
        URLSession.shared.dataTask(with: url) { data, response, error in
            completion(data, response, error)
            }.resume()
    }
    func downloadImage(url: URL,value : String){
        print("Download Started")
        getDataFromUrl(url: url) { data, response, error in
            guard let data = data, error == nil else { return }
            print(response?.suggestedFilename ?? url.lastPathComponent)
            print("Download Finished")
            DispatchQueue.main.async() {
                if value == "user"{
                    self.callImageView.image = UIImage.init(data: data)
                }else if value == "accept"{
                    self.acceptBtn.image = UIImage.init(data: data)
                }
                else if value == "reject"{
                    self.rejectBtn.image = UIImage.init(data: data)
                }
            }
        }
    }
}

extension Dictionary {
    var json: String {
        let invalidJson = "Not a valid JSON"
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: self, options: .prettyPrinted)
            return String(bytes: jsonData, encoding: String.Encoding.utf8) ?? invalidJson
        } catch {
            return invalidJson
        }
    }
    func printJson() {
        print(json)
    }
}
extension String {
    var dictionary : [String : Any] {
        let dict: Dictionary<String, Any> = [:]
        if let data = self.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
            } catch {
                print(error.localizedDescription)
            }
        }
        return dict
    }
    func printDict() {
        print(dictionary)
    }
}
enum IonicTypes:String{
    case ringing = "ringing"
    case registerResponse = "registerResponse"
    case callResponse = "callResponse"
    case incomingCall = "incomingCall"
    case startCommunication = "startCommunication"
    case stopCommunication = "stopCommunication"
    case iceCandidate = "iceCandidate"
    case sdp = "sdp"
    case timerReject = "timerReject"
    case call = "call"
}

