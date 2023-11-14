# SpeechSuper iOS Swift SDK Demo

## Step 1: Insert Your AppKey and SecretKey

Open the file `SwiftDemo/ViewController.swift` and insert your AppKey and SecretKey:

```swift
   paramDic["appKey"] = "Insert your appKey here"
   paramDic["secretKey"] = "Insert your secretKey here"
```

## Step 2: Customize Input Parameters

In the file `SwiftDemo/EvalTest/TestViewController.swift`, customize the input parameters according to your needs. For example:

```swift
     func startSkegn() {
  
            ...
           
        let appDic: [String: Any] = ["userId": "userId"]
        let audioDic: [String: Any] = [
            "audioType": "wav",
            "sampleRate": 16000,
            "channel": 1,
            "sampleBytes": 2
        ]
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

            ...
    }
```

## Step 3: Run the Application
Run the application and navigate to the evaluation screen by clicking the corresponding item on the screen.

## Step 4: Start Recording and Evaluating
Click the "Start Record" button to initiate the recording and evaluation process.

## Step 5: Stop Recording and View the Result
Click the "End" button to stop recording and wait for the evaluation result.


