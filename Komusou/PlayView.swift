//
//  PlayView.swift
//  Komusou
//
//  Created by gurrium on 2022/03/05.
//

import SwiftUI

struct PlayView: View {
    var body: some View {
        ZStack(alignment: .topTrailing) {
            WorldView()
                .edgesIgnoringSafeArea(.all)
            Button {

            } label: {
                Image(systemName: "gearshape")
                    .resizable()
                    .padding(8)
                    .frame(width: 44, height: 44)
                    .foregroundColor(.black)
            }
        }
    }
}

struct PlayView_Previews: PreviewProvider {
    static var previews: some View {
        PlayView()
    }
}
