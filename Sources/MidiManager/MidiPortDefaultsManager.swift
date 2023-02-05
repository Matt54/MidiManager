import CoreMIDI

public class MidiPortDefaultsManager {
    private static func getKeyForID(id: MIDIUniqueID, isInput: Bool) -> String {
        let prefix = isInput ? "Input_" : "Output_"
        return prefix + String(id)
    }
    
    public static func removePortDefault(id: MIDIUniqueID, isInput: Bool) {
        UserDefaults.standard.removeObject(forKey: getKeyForID(id: id, isInput: isInput))
    }
    
    public static func setDefaultConnectionForPort(id: MIDIUniqueID, isOn: Bool, isInput: Bool = true) {
        UserDefaults.standard.set(isOn, forKey: getKeyForID(id: id, isInput: isInput))
    }
    
    public static func doesKeyExistForPort(id: MIDIUniqueID, isInput: Bool = true) -> Bool {
        return UserDefaults.standard.object(forKey: getKeyForID(id: id, isInput: isInput)) != nil
    }
    
    public static func getDefaultConnectionForPort(id: MIDIUniqueID, isInput: Bool = true) -> Bool {
        return UserDefaults.standard.bool(forKey: getKeyForID(id: id, isInput: isInput))
    }
}
