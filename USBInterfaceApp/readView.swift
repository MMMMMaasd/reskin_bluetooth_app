//
//  readView.swift
//  USBInterfaceApp
//
//  Created by 卞泽宇 on 2024/5/27.
//

import SwiftUI
import UIKit
import CoreBluetooth
import BackgroundTasks
import UserNotifications
import Foundation

struct ReadView : View{
    @StateObject var arViewModel = ARViewModel()
    @StateObject var cameraModel = CameraViewModel()
    @EnvironmentObject var appStatus : AppInformation
    //let deviceViewModel = DeviceView()
    @ObservedObject var sharedBluetoothManager =  BluetoothManager()
    @ObservedObject private var bluetoothManager = BluetoothManager()
    @State private var isReading = false
    private let timerInterval: TimeInterval = 0.1
    @State private var recordingTimer: Timer?
    @State private var showSheet = false
    @State var showingAlert : Bool = false
    @Environment(\.scenePhase) private var phase
    @State private var fileSetNames = ["", "", "", "", ""]
    @State var showingExporter = false
    @State var showingSelectSheet = false
    @State var exportFileName = ""
    var body : some View{
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        ZStack{
            /*
            CameraView(cameraModel: cameraModel)
                .frame(width: 350.0, height: 450.0)
                .environmentObject(cameraModel)
                .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
                .padding(.bottom, 250.0)
             */
            ARViewContainer(session: arViewModel.session)
                .edgesIgnoringSafeArea(.all)
                .frame(width: 350.0, height: 550.0)
                .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
                .padding(.bottom, 100.0)
             
            
            
            /*
            Text("press to read data")
                .font(.title)
                .fontWeight(.medium)
                .padding(.bottom, 170.0)
                .padding(.top, 450)
             */
            Button(action: toggleRecording) {
                if isReading {
                    if(appStatus.sharedBluetoothManager.ifConnected){
                        Image(systemName: "stop.circle")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 80)
                            .frame(width: 80)
                            .multilineTextAlignment(.center)
                    }
                } else {
                    Image(systemName: "dot.scope")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 80)
                        .frame(width: 80)
                        .multilineTextAlignment(.center)
               }
            }
            .padding(.top, 580.0)
            .buttonStyle(.bordered)
            
            .alert(isPresented: $showingAlert){
                Alert(title: Text("Warning")
                    .foregroundColor(.red),
                      message: Text("No available bluetooth device connected, you need to connect to a device first!"),
                      dismissButton: .destructive(Text("Ok")){
                    showingAlert = false
                    }
                )
            }
            
            Button(action: {showingExporter.toggle()}){
                Text("save AR data")
                    .font(.footnote)
                    .frame(width: 80.0, height: 35.0)
            }
            .padding(.trailing, 250.0)
            .padding(.top, 600.0)
            .buttonStyle(.bordered)
            
            Button(action:{
                arViewModel.switchCamera()
            }){
                Image(systemName: "arrow.triangle.2.circlepath")
                    .resizable()
                    .frame(height: 35)
                    .frame(width: 39)
            }
            .padding(.leading, 250)
            .padding(.top, 600)
            .buttonStyle(.bordered)
        }
        .frame(width: 10.0, height: 10.0)
        /*
        .actionSheet(isPresented: $showingSelectSheet){
            ActionSheet(title: Text("Choose Export Option"), buttons: [
                .default(Text("Save RGB Video File (.mp4)"), action: {
                    //saveFile(targetIndex: 0)
                    exportFileName = fileSetNames[0]
                    showingExporter = true
                }),
                .default(Text("Save Depth Video File (.mp4)"), action: {
                    //saveFile(targetIndex: 1)
                    exportFileName = fileSetNames[1]
                    showingExporter = true
                }),
                .cancel()
            ])
        }
         */
        .fileExporter(isPresented: $showingExporter, document: DocumentaryFolder(files: createDocumentaryFolderFiles(paths: paths, fileSetNames: fileSetNames)), contentType: .folder, defaultFilename: fileSetNames[2]) { result in
            switch result {
            case .success(let url):
                print("Saved to \(url)")
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
        .ignoresSafeArea()
        
        /*
        .onAppear{
            arViewModel.startSession()
        }
         */
        /*.sheet(isPresented: $showSheet){
         List(sharedBluetoothManager.peripherals, id: \.name) { peripheral in
             singleBLEPeripheral(peripheral: peripheral, bluetoothManager: sharedBluetoothManager)
         }
     }*/
    }
    
    private func saveFile(targetIndex: Int){
        exportFileName = fileSetNames[targetIndex]
        showingSelectSheet.toggle()
    }
    func toggleRecording() {
        if(appStatus.sharedBluetoothManager.ifConnected){
            isReading = !isReading
            //cameraModel.isRecording = !cameraModel.isRecording
            arViewModel.isOpen = !arViewModel.isOpen
            if isReading && arViewModel.isOpen{
                startRecording()
                //cameraModel.startRecording()
                /*
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd-HH:mm:ss"
                let currentDateTime = dateFormatter.string(from: Date())
                fileName = "AR \(currentDateTime).mp4"
                do {
                    try createFile(fileName: fileName)
                    print("File saved successfully at \(fileName)")
                    let url = getDocumentsDirect().appendingPathComponent(fileName)
                } catch {
                    print("Error saving file: \(error)")
                    return
                }
                 */
                fileSetNames = arViewModel.startSession()
                print(fileSetNames)
            } else {
                stopRecording()
                //cameraModel.stopRecording()
                arViewModel.pauseSession()
            }
        }else{
            showingAlert = true
        }
    }
    
    func startRecording() {
        isReading = true
        let timer = Timer.scheduledTimer(withTimeInterval: timerInterval, repeats: true) { _ in
            //appStatus.SharedDataString += sharedBluetoothManager.recordSingleData() ?? ""
            //appStatus.SharedDataString = sharedBluetoothManager.recordString
            appStatus.sharedBluetoothManager.recordSingleData()
        }
        recordingTimer = timer
    }
    
    func stopRecording() {
        if let timer = recordingTimer {
            timer.invalidate()
            isReading = false
        }
    }
    
    
    func getDocumentsDirect() -> URL{
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        print(paths[0].path)
        return paths[0]
    }
    
    func createFile(fileName: String) throws {
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            let fileURL = documentsURL[0].appendingPathComponent(fileName)
            try FileManager.default.createFile(atPath: fileURL.path, contents: nil, attributes: nil)
    }
    
    
    func createDocumentaryFolderFiles(paths: [URL], fileSetNames: [String]) -> [FileElement] {
        do {
            let rgbFile = FileElement.videoFile(VideoFile(url: (paths[0].appendingPathComponent(fileSetNames[0]))))
            let depthFile = FileElement.videoFile(VideoFile(url: (paths[0].appendingPathComponent(fileSetNames[1]))))
            // let text1 = FileElement.textFile(TextFile(url: "path/to/example.txt"))
            let rgbImageFolder = FileElement.directory(SubLevelDirectory(url: (paths[0].appendingPathComponent(fileSetNames[3]))))
            let depthImageFolder = FileElement.directory(SubLevelDirectory(url: (paths[0].appendingPathComponent(fileSetNames[4]))))
            return [rgbFile, depthFile, rgbImageFolder, depthImageFolder]
        } catch {
            print("Out of Index")
        }
    }

    

}
    
    
    
    #Preview {
        ReadView()
            .environmentObject(AppInformation())
    }
    
