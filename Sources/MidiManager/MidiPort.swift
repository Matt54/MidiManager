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
}
