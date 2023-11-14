import UIKit
import AVFoundation
class TestViewController: UIViewController, UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var resultLabel: UILabel!
    @IBOutlet weak var testButton: UIButton!
    
    var testType: String!
    
   
    private let wordsArray: NSArray = ["hello", "nice", "beautiful","help","you"]
    private let sentenceArray: NSArray = ["nice to meet you", "can i help you?", "waht is you name?"]
    private let paragraphArray: NSArray = ["This is my room. Near the window there is a desk. I often do my homework at it. You can see some books, some flowers in a vase, a ruler and a pen. On the wall near the desk there is a picture of a cat. There is a clock above the end of my bed. I usually put my shoe under my bed. Of course there is a chair in front of the desk. I sit there and I can see the trees and roads outside.","Mom bought me a pair of skating shoes at my fifth birthday. From then on, I developed the hobby of skating. It not only makes me stronger and stronger, but also helps me know many truths of life. I know that it is normal to fall, and if only you can get on your feet again and keep on moving, you are very good!"]
    private let wordscnArray: NSArray = ["你", "我", "花"]
    private let sentencecnArray: NSArray = ["见到你很高兴", "我喜欢跟你呆在一起", "周末我们一起去打篮球"]
    private let paragraphcnArray: NSArray = ["小草偷偷地从土里钻出来，嫩嫩的，绿绿的。园子里，田野里，瞧去，一大片一大片满是的。坐着，躺着，打两个滚，踢几脚球，赛几趟跑，捉几回迷藏。风轻悄悄的，草软绵绵的。","雨是最寻常的，一下就是三两天。可别恼。看，像牛毛，像花针，像细丝，密密地斜织着，人家屋顶上全笼着一层薄烟。树叶子却绿得发亮，小草也青得逼你的眼。傍晚时候，上灯了，一点点黄晕的光，烘托出一片安静而和平的夜。乡下去，小路上，石桥边，有撑起伞慢慢走着的人；还有地里工作的农夫，披着蓑，戴着笠的。他们的草屋，稀稀疏疏的，在雨里静默着。"]
    
    private var testArray: NSArray!
    private var testString: String?
    private var audioQueue: AudioQueueRef?
   
    private var isRunning: Bool = false
    private var coreType: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.estimatedRowHeight = 44.0
        self.textField.addTarget(self, action: #selector(textFieldDidChange(textField:)), for: UIControlEvents.editingChanged)

        switch self.testType! {
            case "word.eval":
                self.testArray = self.wordsArray;
                self.coreType = "word.eval";
            case "sent.eval":
                self.testArray = self.sentenceArray;
                self.coreType = "sent.eval";
            case "para.eval":
                self.testArray = self.paragraphArray;
                self.coreType = "para.eval";
            case "word.eval.cn":
                self.testArray = self.wordscnArray;
                self.coreType = "word.eval.cn";
            case "sent.eval.cn":
                self.testArray = self.sentencecnArray;
                self.coreType = "sent.eval.cn";
            case "para.eval.cn":
                self.testArray = self.paragraphcnArray;
                self.coreType = "para.eval.cn";
            default:
                break;
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let indexPath: IndexPath = IndexPath.init(row: 0, section: 0)
        self.tableView.selectRow(at: indexPath, animated: true, scrollPosition: UITableViewScrollPosition.bottom)
        
        self.testString = self.testArray!.firstObject as? String
        self.resultLabel.text = "Current evaluation content：\(self.testString ?? "")"
    }
    

    func startSkegn() {
        let appDic: [String: Any] = ["userId": "userId"]

        let audioDic: [String: Any] = [
            "audioType": "wav",
            "sampleRate": 16000,
            "channel": 1,
            "sampleBytes": 2
        ]
    //Start evaluating parameters
        let requestDic: [String: Any] = [
            "coreType": coreType,
            "refText": testString
        ]

        let paramDic: [String: Any] = [
            "app": appDic,
            "audio": audioDic,
            "request": requestDic,
            "coreProvideType": "native"
        ]

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: paramDic)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print(jsonString)
                // let params_char = jsonString.utf8CString
                var rv: CInt = 0
                let param:[CChar]?
                param = jsonString.cString(using: String.Encoding.utf8)
                let record_id = UnsafeMutablePointer<CChar>.allocate(capacity: 64)
                
                rv = skegn_start(engine, param, record_id, {(userdata: UnsafeRawPointer?, id: UnsafePointer<Int8>?, type: Int32, message: UnsafeRawPointer?, size: Int32) -> CInt in
                        if type == SKEGN_MESSAGE_TYPE_JSON {
                            let object: TestViewController = Unmanaged<TestViewController>.fromOpaque(userdata!).takeUnretainedValue()
                            let buflen = size + 1
                            let buf    = UnsafeMutablePointer<CChar>.allocate(capacity: Int(buflen))
                            memcpy(buf, message, Int(size))
                            buf[Int(size)] = 0 // zero terminate
                            let msgString = String(cString: buf)
                            buf.deallocate()
                                DispatchQueue.main.async(execute: {
                                    object.showResult( result: String(cString: msgString))
                            })
                        }
                        return 0
                } as skegn_callback, Unmanaged.passUnretained(self).toOpaque())

                if rv != 0 {
                    print("start fail")
                    skegn_cancel(engine)
                }
            }
        } catch {
            print("Error in JSON serialization: \(error)")
        }
    }

    func audioQueueCallback(userdata: UnsafeMutableRawPointer?, audioQueue: AudioQueueRef, buffer: AudioQueueBufferRef, startTime: UnsafePointer<AudioTimeStamp>, packetNum: UInt32, packetDesc: UnsafePointer<AudioStreamPacketDescription>?) {
        guard let userdata = userdata else { return }
        let viewController = Unmanaged<TestViewController>.fromOpaque(userdata).takeUnretainedValue()

        if packetNum > 0 {
            if viewController.isRunning {
                let audioData = Data(bytes: buffer.pointee.mAudioData, count: Int(buffer.pointee.mAudioDataByteSize))
                let audioDataCountInt32 = Int32(audioData.count)
                skegn_feed(engine, (audioData as NSData).bytes, audioDataCountInt32) // feed audio
            }
        }

        if viewController.isRunning {
            AudioQueueEnqueueBuffer(audioQueue, buffer, 0, nil)
        } else {
            AudioQueueFreeBuffer(audioQueue, buffer)
        }
    }
 
    func startRecording() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(AVAudioSessionCategoryPlayAndRecord)
            try session.setActive(true)
        } catch {
            print("Error creating session: \(error)")
            return
        }

        var rv: OSStatus = -1
        var audioFormat = AudioStreamBasicDescription()

        audioFormat.mFormatID = kAudioFormatLinearPCM
        audioFormat.mSampleRate = 16000
        audioFormat.mChannelsPerFrame = 1
        audioFormat.mBitsPerChannel = 16
        audioFormat.mFramesPerPacket = 1
        audioFormat.mBytesPerFrame = audioFormat.mChannelsPerFrame * audioFormat.mBitsPerChannel / 8
        audioFormat.mBytesPerPacket = audioFormat.mBytesPerFrame * audioFormat.mFramesPerPacket
        audioFormat.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked

        if let audioQueue = audioQueue {
            AudioQueueDispose(audioQueue, true)
            self.audioQueue = nil
        }

        let audioQueueCallback: AudioQueueInputCallback = { (userData, queue, buffer, startTime, packetCount, packetDescriptions) in
            if let userData = userData {
                let viewController = Unmanaged<TestViewController>.fromOpaque(userData).takeUnretainedValue()
                viewController.audioQueueCallback(userdata: userData, audioQueue: queue, buffer: buffer, startTime: startTime, packetNum: packetCount, packetDesc: packetDescriptions)
            }
        }

       
        rv = AudioQueueNewInput(&audioFormat, audioQueueCallback, Unmanaged.passUnretained(self).toOpaque(), nil, CFRunLoopMode.commonModes.rawValue, 0, &audioQueue)
        
        if rv != noErr {
            print("start record fail: \(rv)")
            return
        }

        self.isRunning = true
        let bytesPerFrame = audioFormat.mBytesPerFrame
        let sampleRate = audioFormat.mSampleRate
        let milliseconds = 100.0
        let bufferSize: UInt32 = UInt32(Double(bytesPerFrame) * sampleRate * milliseconds / 1000.0)

        var buffer: AudioQueueBufferRef? = nil

        for _ in 0..<5 {
            rv = AudioQueueAllocateBuffer(audioQueue!, bufferSize, &buffer)
            if rv != noErr {
                return
            }

            rv = AudioQueueEnqueueBuffer(audioQueue!, buffer!, 0, nil)
            if rv != noErr {
                return
            }
        }

        rv = AudioQueueStart(audioQueue!, nil)

        if rv != 0 {
            self.isRunning = false
        }
    }


    func stopRecord() {
        if self.isRunning, let audioQueue = self.audioQueue {
            print("complete")
            self.isRunning = false
            AudioQueueStop(audioQueue, true)
            skegn_stop(engine) // stop
        }

        if let audioQueue = self.audioQueue {
            AudioQueueDispose(audioQueue, true)
            self.audioQueue = nil
        }
        self.isRunning = false
    }
    
    // MARK: Event
    @IBAction func onClickStartTest(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected;
        if sender.isSelected {    //Start evaluation
            if (self.testString?.count != 0) {
                self.resultLabel.text = "Current evaluation content：\(self.testString ?? "")"
            }
            startRecording()
            sender.setTitle("End", for: UIControlState.normal)
            startSkegn()
        } else {    //end evaluation
            sender.setTitle("Start Record", for: UIControlState.normal)
            self.resultLabel.text = "Please wait a moment..."
            stopRecord()
            print("stop record")
        }
    }

    
    // result
    private func showResult(result: String) {
        print("result: \(result)")
        if result.contains("errId") {    //Error callback
            DispatchQueue.main.async(execute: {
                self.resultLabel.text = result
            })
        } else if result.contains("sound_intensity") {   //Sound intensity callback
            let resultData: Data = result.data(using: .utf8)!
            let resultDic: NSDictionary = try! JSONSerialization.jsonObject(with: resultData, options: .mutableContainers) as! NSDictionary
            let soundIntensity = resultDic["sound_intensity"]
            DispatchQueue.main.async(execute: {
                self.resultLabel.text = result
            })
        } else {//result callback
            let jsonData: Data = result.data(using: .utf8)!
            let jsonDic = try! JSONSerialization.jsonObject(with: jsonData, options: .mutableContainers) as! NSDictionary
            let reslutDic: NSDictionary = jsonDic["result"] as! NSDictionary
            DispatchQueue.main.async(execute: {
                self.resultLabel.text = "overall：\(String(describing: reslutDic["overall"]!))\n\nResult details:\n\(result)"
            })
        }
    }
    
    // MARK: TableView Delegate
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.testArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: TestTableViewCell = tableView.dequeueReusableCell(withIdentifier: "TestCell", for: indexPath) as! TestTableViewCell
        cell.contentLabel.text = self.testArray[indexPath.row] as? String
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.textField.text = ""
        self.testString = self.testArray[indexPath.row] as? String
        self.resultLabel.text = "Current evaluation content：\(self.testString ?? "")"
    }
    
    // MARK:UITextField
    @objc func textFieldDidChange(textField: UITextField) -> Void {
        self.testString = textField.text;
        self.resultLabel.text = "Current evaluation content：\(textField.text ?? "")"
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
