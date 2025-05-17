//
//  ContentView.swift
//  DeepCool
//
//  Created by Henrique Cruz on 08/02/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var deviceManager = DeepcoolDeviceManager()
    @StateObject private var systemMonitor = SystemMonitor()
    @State private var commandTimer: Timer? = nil
    
    var body: some View {
        ZStack {
            // Fundo moderno com gradiente
            LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.black]), startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                
                Text("DeepCool Digital HUD")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.top, 40)
                
                Spacer()
                
                // Exibição dos valores em "cards" estilizados
                HStack(spacing: 20) {
                    MetricView(title: "CPU Frequency", value: String(format: "%.2f GHz", systemMonitor.cpuFrequency))
                    MetricView(title: "CPU Usage", value: String(format: "%.1f %%", systemMonitor.cpuUsage))
                }
                HStack(spacing: 20) {
                    MetricView(title: "Temperature", value: String(format: "%.1f °C", systemMonitor.cpuTemperature))
                    MetricView(title: "TDP", value: "\(Int(systemMonitor.cpuTDP)) W")
                }
                
                Spacer()
                
                Text("Commands are sent every 250ms")
                    .font(.footnote)
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.bottom, 20)
            }
            .padding()
        }
        .onAppear {
            startSendingCommands()
        }
        .onDisappear {
            stopSendingCommands()
        }
    }
    
    func startSendingCommands() {
        commandTimer?.invalidate()
        commandTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            let commandData = systemMonitor.createHUDCommand()
            deviceManager.sendCommand(commandData)
        }
    }
    
    func stopSendingCommands() {
        commandTimer?.invalidate()
        commandTimer = nil
    }
}

struct MetricView: View {
    var title: String
    var value: String
    var body: some View {
        VStack {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
            Text(value)
                .font(.title)
                .foregroundColor(.white)
        }
        .padding()
        .frame(minWidth: 120)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.black.opacity(0.4)))
    }
}
