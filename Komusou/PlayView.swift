//
//  PlayView.swift
//  Komusou
//
//  Created by gurrium on 2022/03/05.
//

import SwiftUI

struct PlayView: View {
    @State
    var isSettingsPresented = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            WorldView(speedSensor: KomusouApp.speedSensor, cadenceSensor: KomusouApp.cadenceSensor)
                .edgesIgnoringSafeArea(.all)
            Button {
                isSettingsPresented = true
            } label: {
                Image(systemName: "gearshape")
                    .resizable()
                    .padding(8)
                    .frame(width: 44, height: 44)
                    .foregroundColor(.black)
            }
        }
        .sheet(isPresented: $isSettingsPresented) {
            SettingsView()
        }
    }
}

struct PlayView_Previews: PreviewProvider {
    static var previews: some View {
        PlayView()
    }
}
