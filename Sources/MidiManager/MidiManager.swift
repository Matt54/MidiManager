import AudioKit
import CoreMIDI
import UtilityAndBeyond
import SwiftUI

public class MidiManager: ObservableObject {
    @Environment(\.isPreview) var isPreview
    
    public let midi = MIDI()
    @Published public var inputPorts = [MidiPort]()
    @Published public var outputPorts = [MidiPort]()
    @Published public var outputChannel: MIDIChannel = 0
    
    public var ccHandler: ((_ controller: MIDIByte,_ value: MIDIByte,_ channel: MIDIChannel,_ portID: MIDIUniqueID?,_ timeStamp: MIDITimeStamp?) -> Void)?
    public var noteOnHandler: ((_ noteNumber: MIDINoteNumber,_ velocity: MIDIVelocity,_ channel: MIDIChannel,_ portID: MIDIUniqueID?,_ timeStamp: MIDITimeStamp?) -> Void)?
    public var noteOffHandler: ((_ noteNumber: MIDINoteNumber,_ velocity: MIDIVelocity,_ channel: MIDIChannel,_ portID: MIDIUniqueID?,_ timeStamp: MIDITimeStamp?) -> Void)?
    
    public var shouldPrintLogToConsole: Bool = false
    
    /// determines if a new input will be automatically connected to
    public var shouldConnectInputsAutomatically: Bool = true
    
    private var shouldOpenPorts: Bool
    
    ///  shouldOpenPorts determines if openInput/openOutput is called in startMIDI (required for bluetooth)
    ///  - defaulting to false until it is proven to be a good idea for Chordable
    public init(shouldOpenPorts: Bool = false) {
        self.shouldOpenPorts = shouldOpenPorts
        if !isPreview {
            startMIDI()
        }
    }
    
    public convenience init(withMockPorts: Bool) {
        self.init()
        if withMockPorts {
            inputPorts = [MidiPort.getMockPort(isConnected: false, isInput: true), MidiPort.getMockPort(isConnected: true, isInput: true)]
            outputPorts = [MidiPort.getMockPort(isConnected: false, isInput: false), MidiPort.getMockPort(isConnected: true, isInput: false)]
        }
    }
    
    public func startMIDI() {
        midi.addListener(self)
        
        let appName = Bundle.main.displayName
        
        if shouldOpenPorts {
            midi.openInput()
            midi.openOutput()
        }
        
        // this is what shows up in Ableton
        midi.createVirtualInputPorts(names: [appName ?? "AudioKit"])
        midi.createVirtualOutputPorts(names: [appName ?? "AudioKit"])
    }
    
    public func togglePortConnection(_ port: MidiPort) {
        port.isConnected ? disconnectPort(port: port) : connectPort(port: port)
    }
    
    public func connectPort(port: MidiPort) {
        let portCollection = port.isInput ? inputPorts : outputPorts
        
        if let index = portCollection.firstIndex(where: { port.id == $0.id }) {
            if port.isInput {
                midi.openInput(uid: port.midiUniqueID)
                inputPorts[index].isConnected = true
                print("connected input port: " + port.name)
            } else {
                midi.openOutput(uid: port.midiUniqueID)
                outputPorts[index].isConnected = true
                print("connected output port: " + port.name)
            }
            
            MidiPortDefaultsManager.setDefaultConnectionForPort(id: port.midiUniqueID, isOn: true , isInput: port.isInput)
        }
    }
    
    public func disconnectPort(port: MidiPort) {
        let portCollection = port.isInput ? inputPorts : outputPorts
        
        if let index = portCollection.firstIndex(where: { port.id == $0.id }) {
            if port.isInput {
                midi.closeInput(uid: port.midiUniqueID)
                inputPorts[index].isConnected = false
                print("disconnected input port: " + port.name)
            } else {
                midi.closeOutput(uid: port.midiUniqueID)
                outputPorts[index].isConnected = false
                print("disconnected output port: " + port.name)
            }
            
            MidiPortDefaultsManager.setDefaultConnectionForPort(id: port.midiUniqueID, isOn: false , isInput: port.isInput)
        }
    }
    
    public func sendNoteOnMessage(noteNumber: MIDINoteNumber, velocity: MIDIVelocity, channel: MIDIChannel? = nil, time: MIDITimeStamp = mach_absolute_time()) {
        if shouldPrintLogToConsole {
            logMidiIO(noteNumber: noteNumber, velocity: velocity, channel: channel ?? outputChannel, midiIOType: .sentNoteOn)
        }
        midi.sendNoteOnMessage(noteNumber: noteNumber, velocity: velocity, channel: channel ?? outputChannel, time: time, virtualOutputPorts: midi.virtualOutputs)
    }
    
    public func sendNoteOffMessage(noteNumber: MIDINoteNumber, channel: MIDIChannel? = nil, time: MIDITimeStamp = mach_absolute_time()) {
        if shouldPrintLogToConsole {
            logMidiIO(noteNumber: noteNumber, velocity: 0, channel: channel ?? outputChannel, midiIOType: .sentNoteOff)
        }
        midi.sendNoteOffMessage(noteNumber: noteNumber, channel: channel ?? outputChannel, time: time, virtualOutputPorts: midi.virtualOutputs)
    }
    
    public func sendCCMessage(control: MIDIByte, value: MIDIByte, channel: MIDIChannel = 0) {
        midi.sendControllerMessage(control, value: value, channel: channel, virtualOutputPorts: midi.virtualOutputs)
    }
    
    func logMidiIO(noteNumber: MIDINoteNumber, velocity: MIDIVelocity, channel: MIDIChannel, midiIOType: MidiNoteIOType) {
        let isNoteOff = (midiIOType == .receivedNoteOff || midiIOType == .sentNoteOff)
        print("---------------------")
        print(midiIOType.description)
        print("MidiManager DEBUG LOG: note \(noteNumber) -\(!isNoteOff ? " velocity \(velocity) -" : "") channel \(channel)")
        print("---------------------")
    }
    
    public func removeConnectedPortsFromUserDefaults() {
        for port in inputPorts {
            MidiPortDefaultsManager.removePortDefault(id: port.midiUniqueID, isInput: true)
        }
        for port in outputPorts {
            MidiPortDefaultsManager.removePortDefault(id: port.midiUniqueID, isInput: false)
        }
    }
}

enum MidiNoteIOType {
    case receivedNoteOn, receivedNoteOff, sentNoteOn, sentNoteOff

    var description: String {
        switch self {
        case .receivedNoteOn:
            return "Received Note On"
        case .receivedNoteOff:
            return "Received Note Off"
        case .sentNoteOn:
            return "Sent Note On"
        case .sentNoteOff:
            return "Sent Note Off"
        }
    }
}

extension MidiManager: MIDIListener {
    public func receivedMIDIController(_ controller: MIDIByte, value: MIDIByte, channel: MIDIChannel, portID: MIDIUniqueID?, timeStamp: MIDITimeStamp?) {
        if let handler = ccHandler {
            handler(controller, value, channel, portID, timeStamp)
        }
    }
    
    public func receivedMIDINoteOn(noteNumber: MIDINoteNumber, velocity: MIDIVelocity, channel: MIDIChannel, portID: MIDIUniqueID?, timeStamp: MIDITimeStamp?) {
        if shouldPrintLogToConsole {
            logMidiIO(noteNumber: noteNumber, velocity: velocity, channel: channel, midiIOType: .receivedNoteOn)
        }
        if let handler = noteOnHandler {
            handler(noteNumber, velocity, channel, portID, timeStamp)
        }
    }
    
    public func receivedMIDINoteOff(noteNumber: MIDINoteNumber, velocity: MIDIVelocity, channel: MIDIChannel, portID: MIDIUniqueID?, timeStamp: MIDITimeStamp?) {
        if shouldPrintLogToConsole {
            logMidiIO(noteNumber: noteNumber, velocity: velocity, channel: channel, midiIOType: .receivedNoteOff)
        }
        if let handler = noteOffHandler {
            handler(noteNumber, velocity, channel, portID, timeStamp)
        }
    }
    
    public func receivedMIDIAftertouch(noteNumber: MIDINoteNumber, pressure: MIDIByte, channel: MIDIChannel, portID: MIDIUniqueID?, timeStamp: MIDITimeStamp?) {}
    
    public func receivedMIDIAftertouch(_ pressure: MIDIByte, channel: MIDIChannel, portID: MIDIUniqueID?, timeStamp: MIDITimeStamp?) {}
    
    public func receivedMIDIPitchWheel(_ pitchWheelValue: MIDIWord, channel: MIDIChannel, portID: MIDIUniqueID?, timeStamp: MIDITimeStamp?) {}
    
    public func receivedMIDIProgramChange(_ program: MIDIByte, channel: MIDIChannel, portID: MIDIUniqueID?, timeStamp: MIDITimeStamp?) {}
    
    public func receivedMIDISystemCommand(_ data: [MIDIByte], portID: MIDIUniqueID?, timeStamp: MIDITimeStamp?) {}
    
    public func receivedMIDISetupChange() {
        print("receivedMIDISetupChange")
        
        // add any new ports
        for inputUID in midi.inputUIDs {
            let name = midi.inputName(for: inputUID) ?? "No Name"
            print(name + ": " + String(inputUID))

            if !inputPorts.contains(where: { $0.id == inputUID }) {
                let newPort = MidiPort(midiUniqueID: inputUID, name: name)
                inputPorts.append(newPort)
                
                var shouldConnectAutomatically = shouldConnectInputsAutomatically
                if MidiPortDefaultsManager.doesKeyExistForPort(id: newPort.midiUniqueID, isInput: true) {
                    shouldConnectAutomatically = MidiPortDefaultsManager.getDefaultConnectionForPort(id: newPort.midiUniqueID, isInput: true)
                }
                
                if shouldConnectAutomatically {
                    connectPort(port: newPort)
                }
            }
        }

        for destinationUID in midi.destinationUIDs {
            let name = midi.destinationName(for: destinationUID)
            print("ENDPOINT: " + name + ": " + String(destinationUID))
            
            if !outputPorts.contains(where: { $0.id == destinationUID }) {
                let newPort = MidiPort(midiUniqueID: destinationUID, name: name, isInput: false)
                outputPorts.append(newPort)
                
                // connect right away if we were previously connected
                if MidiPortDefaultsManager.getDefaultConnectionForPort(id: destinationUID, isInput: false) {
                    connectPort(port: newPort)
                }
            }
        }

        // remove any port that is no longer available
        inputPorts = inputPorts.filter { item in midi.inputUIDs.contains(where: { $0 == item.id }) }
        outputPorts = outputPorts.filter { item in midi.destinationUIDs.contains(where: { $0 == item.id }) }
    }
    
    public func receivedMIDIPropertyChange(propertyChangeInfo: MIDIObjectPropertyChangeNotification) {}
    
    public func receivedMIDINotification(notification: MIDINotification) {}
}
