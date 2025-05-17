//
//  DeepcoolDeviceManager.swift
//  DeepCool
//
//  Created by Henrique Cruz on 08/02/25.
//

import Foundation
import IOKit.hid

class DeepcoolDeviceManager: ObservableObject {
    private var hidManager: IOHIDManager!  // Forçando unwrap se necessário
    @Published var device: IOHIDDevice?
    
    init() {
        setupHIDManager()
    }
    
    private func setupHIDManager() {
        hidManager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
        let matchingDict: [String: Any] = [
            kIOHIDVendorIDKey as String: 0x3633,
            kIOHIDProductIDKey as String: 0x0012
        ]
        IOHIDManagerSetDeviceMatching(hidManager, matchingDict as CFDictionary)
        let result = IOHIDManagerOpen(hidManager, IOOptionBits(kIOHIDOptionsTypeNone))
        if result != kIOReturnSuccess {
            print("Erro ao abrir o HID Manager: \(result)")
            return
        }
        
        if let deviceSet = IOHIDManagerCopyDevices(hidManager) as? Set<IOHIDDevice>,
           let foundDevice = deviceSet.first {
            self.device = foundDevice
            print("AK620 Pro conectado.")
        } else {
            print("AK620 não encontrado!")
        }
    }
    
    func sendCommand(_ command: Data) {
        guard let device = self.device else {
            print("Dispositivo indisponível para o envio de comandos")
            return
        }
        let reportID: CFIndex = 0
        command.withUnsafeBytes { (buffer: UnsafeRawBufferPointer) in
            if let pointer = buffer.bindMemory(to: UInt8.self).baseAddress {
                let result = IOHIDDeviceSetReport(device, kIOHIDReportTypeOutput, reportID, pointer, command.count)
                if result != kIOReturnSuccess {
                    print("Falha ao enviar comando: \(result)")
                } else {
                    print("Comando enviado com sucesso: \(result)")
                }
            }
        }
    }
}
