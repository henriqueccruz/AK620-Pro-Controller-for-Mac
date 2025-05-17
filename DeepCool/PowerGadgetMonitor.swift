//
//  PowerGadgetMonitor.swift
//  DeepCool
//
//  Created by Henrique Cruz on 09/02/25.
//

import Foundation

// Suponha que o seu bridging header já inclua os headers:
//   #include <IntelPowerGadget/PowerGadgetLib.h>
// E que, conforme o header, temos:
//   typedef uint64_t PGSampleID;

class PowerGadgetMonitor {
    // Usaremos PGSampleID (UInt64) para representar uma amostra.
    private var previousSample: PGSampleID? = nil
    private var currentSample: PGSampleID? = nil

    /// Inicializa o monitor e lê o primeiro sample.
    init?() {
        // Inicializa a API; PG_Initialize() retorna Bool (true se sucesso)
        let initRet = PG_Initialize()
        if !initRet {
            print("Erro ao inicializar o Intel Power Gadget")
            return nil
        }
        // Leia o primeiro sample
        var sample: PGSampleID = 0
        let ret = withUnsafeMutablePointer(to: &sample) { pointer in
            PG_ReadSample(0, pointer)
        }
        if !ret {
            print("Erro ao ler o sample inicial: \(ret)")
            return nil
        }
        currentSample = sample
    }
    
    deinit {
        // Libera as amostras retidas, se houver
        if let prev = previousSample {
            PGSample_Release(prev)
        }
        if let curr = currentSample {
            PGSample_Release(curr)
        }
        PG_Shutdown()
    }
    
    /// Atualiza as amostras:
    /// - Libera o sample anterior (se existir)
    /// - Move o sample atual para previousSample
    /// - Lê um novo sample para currentSample
    /// Retorna true se a leitura for bem-sucedida.
    func updateSamples() -> Bool {
        // Libera a amostra anterior, se existir
        if let prev = previousSample {
            PGSample_Release(prev)
        }
        // Move o sample atual para previousSample
        previousSample = currentSample
        
        // Lê um novo sample para currentSample
        var newSample: PGSampleID = 0
        let ret = withUnsafeMutablePointer(to: &newSample) { pointer in
            PG_ReadSample(0, pointer)
        }
        if !ret {
            print("Erro ao ler novo sample: \(ret)")
            return false
        }
        currentSample = newSample
        
        return true
    }
    
    /// Obtém a potência do pacote (TDP dinâmico) em Watts.
    func getPackagePower() -> Double? {
        guard let prev = previousSample, let curr = currentSample else {
            print("Amostras insuficientes para PGSample_GetPackagePower")
            return nil
        }
        var pkgPower: Double = 0.0
        var energyJoules: Double = 0.0
        let ret = PGSample_GetPackagePower(prev, curr, &pkgPower, &energyJoules)
        if !ret {
            print("Erro em PGSample_GetPackagePower: \(ret)")
            return nil
        }
        return pkgPower
    }
    
    /// Obtém a temperatura do pacote (por exemplo, a temperatura da CPU) em °C.
    func getPackageTemperature() -> Double? {
        guard let prev = previousSample, let curr = currentSample else {
            print("Amostras insuficientes para PGSample_GetPackageTemperature")
            return nil
        }
        var pkgTemp: Double = 0.0,
            minTemp: Double = 0.0,
            maxTemp: Double = 0.0
        
        let ret = PGSample_GetIATemperature(curr, &pkgTemp, &minTemp, &maxTemp)
        if !ret {
            print("Erro em PGSample_GetPackageTemperature: \(ret)")
            return nil
        }
        return maxTemp
    }
    
    /// Obtém a utilização da IA (CPU utilization) em porcentagem.
    func getIAUtilization() -> Double? {
        guard let prev = previousSample, let curr = currentSample else {
            print("Amostras insuficientes para PGSample_GetIAUtilization")
            return nil
        }
        var iaUtil: Double = 0.0
        let ret = PGSample_GetIAUtilization(prev, curr, &iaUtil)
        if !ret {
            print("Erro em PGSample_GetIAUtilization: \(ret)")
            return nil
        }
        return iaUtil
    }
    
    /// Obtém a frequência de requisição (Core Req) em GHz.
    func getRequestFrequency() -> Double? {
        guard let prev = previousSample, let curr = currentSample else {
            print("Amostras insuficientes para PGSample_GetIAFrequency")
            return nil
        }
        var reqFreq: Double = 0.0
        var minFreq: Double = 0.0
        var maxFreq: Double = 0.0
        let ret = PGSample_GetIAFrequencyRequest(curr, &reqFreq, &minFreq, &maxFreq)
        if !ret {
            print("Erro em PGSample_GetIAFrequency: \(ret)")
            return nil
        }
        return reqFreq
    }
}
