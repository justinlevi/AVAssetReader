//: Playground - noun: a place where people can play

import UIKit
import AVFoundation
import XCPlayground

func plotArrayInPlayground<T>(arrayToPlot:Array<T>, title:String) {
  for currentValue in arrayToPlot {
    XCPCaptureValue(title, value: currentValue)
  }
}

class SSSampleDataFilter {
  var sampleData:NSData?
  
  init(data:NSData) {
    sampleData = data
  }
  
  func filteredSamplesForSize(size:CGSize) -> [Int]{
    var filterSamples = [UInt16]()
    
    if let sampleData = sampleData {
      let sampleCount = sampleData.length
      let binSize = CGFloat(sampleCount) / size.width
      
      let stream = NSInputStream(data: sampleData)
      stream.open()
      
      var readBuffer = Array<UInt8>(count: 16 * 1024, repeatedValue: 0)
      var totalBytesRead = 0
      
      let size = sizeof(UInt16)
      while (totalBytesRead < sampleData.length) {
        let numberOfBytesRead = stream.read(&readBuffer, maxLength: size)
        let u16: UInt16 = UnsafePointer<UInt16>(readBuffer).memory

        var sampleBin = [UInt16]()
        for _ in 0..<Int(binSize) {
          sampleBin.append(u16)
        }
        
        filterSamples.append(sampleBin.maxElement()!)
        totalBytesRead += numberOfBytesRead
      }
      
      //plotArrayInPlayground(filterSamples, title: "Samples")
    }
    
    return [0]
    
  }
}

let sineURL = NSBundle.mainBundle().URLForResource("440.0-sine", withExtension: "aif")!
let asset = AVAsset(URL: sineURL)
var assetReader:AVAssetReader

do{
  assetReader = try AVAssetReader(asset: asset)
}catch{
  fatalError("Unable to read Asset: \(error) : \(__FUNCTION__).")
}

let track = asset.tracksWithMediaType(AVMediaTypeAudio).first
let outputSettings: [String:Int] =
  [ AVFormatIDKey: Int(kAudioFormatLinearPCM),
    AVLinearPCMIsBigEndianKey: 0,
    AVLinearPCMIsFloatKey: 0,
    AVLinearPCMBitDepthKey: 16,
    AVLinearPCMIsNonInterleaved: 0]

let trackOutput = AVAssetReaderTrackOutput(track: track!, outputSettings: outputSettings)

assetReader.addOutput(trackOutput)
assetReader.startReading()

var sampleData = NSMutableData()

while assetReader.status == AVAssetReaderStatus.Reading {
  if let sampleBufferRef = trackOutput.copyNextSampleBuffer() {
    if let blockBufferRef = CMSampleBufferGetDataBuffer(sampleBufferRef) {
      let bufferLength = CMBlockBufferGetDataLength(blockBufferRef)
      var data = NSMutableData(length: bufferLength)
      CMBlockBufferCopyDataBytes(blockBufferRef, 0, bufferLength, data!.mutableBytes)
      var samples = UnsafeMutablePointer<Int16>(data!.mutableBytes)
      sampleData.appendBytes(samples, length: bufferLength)
      CMSampleBufferInvalidate(sampleBufferRef)
    }
  }
}

let view = UIView(frame: CGRectMake(0, 0, 375.0, 667.0))
//view.backgroundColor = UIColor.lightGrayColor()

if assetReader.status == AVAssetReaderStatus.Completed {
  print("complete")

  let filter = SSSampleDataFilter(data: sampleData)
  let filteredSamples = filter.filteredSamplesForSize(view.bounds.size)
}

//XCPShowView("Bezier Path", view: view)
XCPSetExecutionShouldContinueIndefinitely(true)

