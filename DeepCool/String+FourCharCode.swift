//
//  Untitled.swift
//  DeepCool
//
//  Created by Henrique Cruz on 08/02/25.
//

import Foundation

// Se o tipo FourCharCode já estiver definido em outro lugar, você pode omitir essa linha;
// caso contrário, defina-o assim:
public typealias FourCharCode = UInt32

extension String {
    public var fourCharCode: FourCharCode {
        var result: FourCharCode = 0
        for char in self.utf8 {
            result = (result << 8) | FourCharCode(char)
        }
        return result
    }
    
    /// Remove sequências de escape ANSI da string.
    func removingANSIEscapeCodes() -> String {
        // O padrão regex abaixo captura códigos ANSI.
        // Explicação breve:
        // \u{001B} ou \x1B corresponde ao caractere ESC.
        // \[[0-?]*[ -/]*[@-~] corresponde à sequência que segue o ESC.
        let pattern = "\u{001B}\\[[0-?]*[ -/]*[@-~]"
        if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
            let range = NSRange(location: 0, length: self.utf16.count)
            return regex.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: "")
        }
        return self
    }
}
