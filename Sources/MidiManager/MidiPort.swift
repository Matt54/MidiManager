import CoreMIDI

public struct MidiPort: Identifiable {
    public var id: MIDIUniqueID { midiUniqueID }
    public let midiUniqueID: MIDIUniqueID
    public let name: String
    public var isConnected: Bool = false
    public var isInput: Bool = true
    
    public init(midiUniqueID: MIDIUniqueID, name: String, isConnected: Bool = false, isInput: Bool = true) {
        self.midiUniqueID = midiUniqueID
        self.name = name
        self.isConnected = isConnected
        self.isInput = isInput
    }
    
    public static func getMockPort(isConnected: Bool = false, isInput: Bool = true) -> MidiPort {
        let randomId = Int32.random(in: 1000000000...1999999999)
        return MidiPort(midiUniqueID: -randomId, name: "Mock Port Name", isConnected: isConnected, isInput: isInput)
    }
    
    public static func getMockPorts(isInput: Bool = false) -> [MidiPort] {
        var ports = [MidiPort]()
        for _ in 0...3 {
            let port = MidiPort.getMockPort(isConnected: Bool.random(), isInput: isInput)
            ports.append(port)
        }
        return ports
    }
}

/// WIP - don't use yet
public struct VirtualMidiPort: Identifiable {
    public var id: MIDIPortRef
    public let name: String
    public var isConnected: Bool = false
    
    public init(id: MIDIPortRef, name: String, isConnected: Bool = false) {
        self.id = id
        self.name = name
        self.isConnected = isConnected
    }
}
