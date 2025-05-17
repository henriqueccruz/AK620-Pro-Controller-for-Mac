//
//  SystemMonitor.swift
//  DeepCool
//
//  Created by Henrique Cruz on 08/02/25.
//

import Foundation
import IOKit

/// Classe que monitora e atualiza informações do sistema.
class SystemMonitor: ObservableObject {
    @Published var cpuFrequency: Double = 0.0       // Em GHz
    @Published var cpuUsage: Double = 0.0           // Em porcentagem
    @Published var cpuTemperature: Double = 0.0     // Em °C
    @Published var cpuFanSpeed: Double = 0.0        // Em RPM
    @Published var cpuTDP: Double = 0.0             // Em Watts (valor fixo ou de lookup)
    
    // Propriedades para cálculo do uso da CPU
    private var previousCPUInfo: [UInt32]? = nil
    private var previousNumCPUInfo: mach_msg_type_number_t = 0
    
    private var pgMonitor: PowerGadgetMonitor?
    private var timer: Timer?
    
    init() {
        if let monitor = PowerGadgetMonitor() {
            self.pgMonitor = monitor
        } else {
            print("Falha ao inicializar o Power Gadget Monitor")
        }
        startMonitoring()
    }
    
    func startMonitoring() {
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self, let monitor = self.pgMonitor else { return }
            if monitor.updateSamples() {
                if let freq = monitor.getRequestFrequency() {
                    self.cpuFrequency = freq / 1000
                }
                if let power = monitor.getPackagePower() {
                    self.cpuTDP = power
                }
                if let temp = monitor.getPackageTemperature() {
                    self.cpuTemperature = temp
                }
                if let util = monitor.getIAUtilization() {
                    self.cpuUsage = util
                }
                print("Atualização: Core Req = \(self.cpuFrequency) GHz, Package Power = \(self.cpuTDP) W, Package Temp = \(self.cpuTemperature) °C, CPU Util = \(self.cpuUsage)%")
            }
        }
    }

}

extension SystemMonitor {
    /// Cria o pacote de comando para atualização do HUD conforme o protocolo:
    /// - D0: Header (U8) – valor fixo (16)
    /// - D1–D7: Comando (7 bytes) – valores fixos (exemplo: [104, 1, 4, 13, 1, 2, 8])
    /// - D8–D9: TDP (U16, bigEndian)
    /// - D10: Unidade de Temperatura (U8) – 0 para Celsius
    /// - D11–D14: CPU Temperature (F32, bigEndian)
    /// - D15: CPU Usage (U8)
    /// - D16–D17: CPU Frequency (U16, bigEndian) – multiplicado por 1000 (em MHz)
    /// - D18: Checksum (U8) – soma dos bytes de D1 até D17, módulo 256
    /// - D19: Termination byte (U8) – valor fixo 22
    func createHUDCommand() -> Data {
        var bytes = [UInt8](repeating: 0, count: 20)
        
        // D0: Header
        bytes[0] = 16
        
        // D1–D7: Comando – ajuste conforme o protocolo (exemplo fixo)
        let comando: [UInt8] = [104, 1, 4, 13, 1, 2, 8]
        for i in 0..<min(7, comando.count) {
            bytes[1 + i] = comando[i]
        }
        
        // D8–D9: TDP (U16, bigEndian) – valor fixo sem escala
        let tdp: UInt16 = UInt16(self.cpuTDP)
        let tdpBE = tdp.bigEndian
        withUnsafeBytes(of: tdpBE) { ptr in
            bytes[8] = ptr[0]
            bytes[9] = ptr[1]
        }
        
        // D10: Unidade de Temperatura (U8) – 0 para Celsius
        bytes[10] = 0
        
        // D11–D14: CPU Temperature (F32, bigEndian)
        let cpuTempF32: Float32 = Float32(self.cpuTemperature)
        let cpuTempBitsBE = cpuTempF32.bitPattern.bigEndian
        withUnsafeBytes(of: cpuTempBitsBE) { ptr in
            bytes[11] = ptr[0]
            bytes[12] = ptr[1]
            bytes[13] = ptr[2]
            bytes[14] = ptr[3]
        }
        
        // D15: CPU Usage (U8)
        let cpuUsageValue: UInt8 = UInt8(min(max(self.cpuUsage, 0.0), 100.0))
        bytes[15] = cpuUsageValue
        
        // D16–D17: CPU Frequency (U16, bigEndian)
        // Se self.cpuFrequency está em GHz, multiplicamos por 1000 para converter para MHz.
        let cpuFreqValue: UInt16 = UInt16(floor(self.cpuFrequency * 1000))
        let cpuFreqBE = cpuFreqValue.bigEndian
        withUnsafeBytes(of: cpuFreqBE) { ptr in
            bytes[16] = ptr[0]
            bytes[17] = ptr[1]
        }
        
        // D18: Checksum (U8) – soma dos bytes de D1 até D17, módulo 256
        let checksumSum = bytes[1...17].reduce(0) { $0 + Int($1) }
        let checksum = UInt8(checksumSum % 256)
        bytes[18] = checksum
        
        // D19: Termination byte – valor fixo 22
        bytes[19] = 22
        
        return Data(bytes)
    }
}
