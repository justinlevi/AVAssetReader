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
  
  func filteredSamplesForSize(size:CGSize) -> [Int16]{
    var filterSamples = [Int16]()
    
    size
    
    if let sampleData = sampleData {
      var sampleCount = sampleData.length
      
      var binSize = Int(CGFloat(sampleCount) / size.width)
      binSize = binSize > 2 ? binSize : 2
      
      // PRETTY SURE THE BINSIZE MUST BE A MULTIPLE OF 2 AS WELL
      
      // TEMPORARY
      //binSize = sampleCount
      
      let stream = NSInputStream(data: sampleData)
      stream.open()
      
      var readBuffer = Array<UInt8>(count: 1024 * 8, repeatedValue: 0)
      var totalBytesRead = 0
      
      
      // TEMPORARY
//      sampleCount = 5
      
//      let size = sizeof(Int16)

  
//      while (totalBytesRead < sampleCount) {
//        let numberOfBytesRead = stream.read(&readBuffer, maxLength: size)
//        let u16: Int16 = UnsafePointer<Int16>(readBuffer).memory
//        
//        var sampleBin = [Int16]()
//        for _ in 0..<Int(binSize) {
//          sampleBin.append(u16)
//        }
//        
//        filterSamples.append(sampleBin.maxElement()!)
//        totalBytesRead += numberOfBytesRead
//      }
      
      
      while (totalBytesRead < sampleCount) {
        let numberOfBytesRead = stream.read(&readBuffer, maxLength: readBuffer.count)
  
        
        // TEMPORARY
        // var sampleBin = [Int16]()
      
        // This returns the same value as reading the stream 2 bytes at a time
        // var tmpBuffer = Array<UInt8>(arrayLiteral: readBuffer[2], readBuffer[3])
        // let u16: Int16 = UnsafePointer<Int16>(tmpBuffer).memory
        
        // for var i = 0; i < numberOfBytesRead; i+=2 {
          
        // END - TEMPORARY
        
        for var i=0; i < numberOfBytesRead; i+=binSize {
          
          var sampleBin = [Int16]()
          
          // TEMPORARY
          // if i + 1 < readBuffer.count {
          //  var tmpBuffer = Array<UInt8>(arrayLiteral: readBuffer[i], readBuffer[i+1])
          //  let u16: Int16 = UnsafePointer<Int16>(tmpBuffer).memory
          //  sampleBin.append(u16)
          // }
          // END - TEMPORARY
          
          for var j = 0; j < binSize; j+=2 {
    
            if i+j+1 < readBuffer.count {
              let tmpBuffer = Array<UInt8>(arrayLiteral: readBuffer[i+j], readBuffer[i+j+1])
              let u16: Int16 = UnsafePointer<Int16>(tmpBuffer).memory
              sampleBin.append(u16)
              
              //filterSamples.append(u16)
            }
          }
          
          filterSamples.append(sampleBin.maxElement()!)
          
        }

        totalBytesRead += numberOfBytesRead
      }
    
      plotArrayInPlayground(filterSamples, title: "Samples")
  
    }
    
    
    
    return filterSamples
    
  }
}

// MP3 doesn't work
let sineURL = NSBundle.mainBundle().URLForResource("440.0-saw-0.05s", withExtension: "aif")!
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

