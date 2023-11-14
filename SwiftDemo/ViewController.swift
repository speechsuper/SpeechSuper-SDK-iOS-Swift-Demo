import UIKit

import AVFoundation

var engine: OpaquePointer?
class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    var mp3Path: String?
    var wavPath: String?
    var audioName: String?
    var audioRecorder: AVAudioRecorder?
    var audioQueue: AudioQueueRef?
    var isRunning: Bool = false
    var nativeTypeArray: [String] = []

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.tableFooterView = UIView.init()
        //init engine
        var paramDic: [String: Any] = [:]
        paramDic["appKey"] = "Insert your appKey here"
        paramDic["secretKey"] = "Insert your secretKey here"
        
        if let resourcePath = Bundle.main.path(forResource: "native.res", ofType: nil) {
            paramDic["native"] = resourcePath
        }
        
        if let resourcePathCN = Bundle.main.path(forResource: "native_cn.res", ofType: nil) {
            paramDic["native_cn"] = resourcePathCN
        }
        
        let logDic: [String: Any] = [
            "enable": 1,
            "output": (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString).appendingPathComponent("sdkLog.txt"),
            "level": 1
        ]
        paramDic["sdkLog"] = logDic

        if let jsonData = try? JSONSerialization.data(withJSONObject: paramDic, options: .prettyPrinted) {
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print(jsonString)
                var cfg = Array<CChar>(repeating: 0, count: 4096)
                _ = jsonString.getCString(&cfg, maxLength: 4096, encoding: .utf8)
                engine = skegn_new(&cfg)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 6;
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identify:String = "cellIdentify"
        var cell = tableView.dequeueReusableCell(withIdentifier:identify)
        if cell == nil {
            cell = UITableViewCell.init(style: UITableViewCellStyle.default, reuseIdentifier: identify)
            switch indexPath.row {
                case 0:
                    cell?.textLabel?.text = "word.eval"
                case 1:
                    cell?.textLabel?.text = "sent.eval"
                case 2:
                    cell?.textLabel?.text = "para.eval"
                case 3:
                    cell?.textLabel?.text = "word.eval.cn"
                case 4:
                    cell?.textLabel?.text = "sent.eval.cn"
                case 5:
                    cell?.textLabel?.text = "para.eval.cn"
                default:
                    break
            }
        }
        return cell!
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44.0
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //选择评测模式
        let testVC:TestViewController = self.storyboard?.instantiateViewController(withIdentifier: "TestVC") as! TestViewController
        
        switch indexPath.row {
            case 0:
                testVC.testType = "word.eval";
            case 1:
                testVC.testType = "sent.eval";
            case 2:
                testVC.testType = "para.eval";
            case 3:
                testVC.testType = "word.eval.cn";
            case 4:
                testVC.testType = "sent.eval.cn";
            case 5:
                testVC.testType = "para.eval.cn";
            default:
                break
        }
        
        self.navigationController?.pushViewController(testVC, animated: true)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}