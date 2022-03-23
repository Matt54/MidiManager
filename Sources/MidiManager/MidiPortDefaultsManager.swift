import CoreMIDI

public class MidiPortDefaultsManager {
    public static func setDefaultConnectionForPort(id: MIDIUniqueID, isOn: Bool, isInput: Bool = true) {
        let key: String
        if isInput {
            key = "Input_" + String(id)
        } else {
            key = "Output_" + String(id)
        }
        
        UserDefaults.standard.set(isOn, forKey: key)
    }
    
    public static func getDefaultConnectionForPort(id: MIDIUniqueID, isInput: Bool = true) -> Bool {
        let key: String
        if isInput {
            key = "Input_" + String(id)
        } else {
            key = "Output_" + String(id)
        }
        
        return UserDefaults.standard.bool(forKey: key)
    }
}
