//
//  SettingView.swift
//  CoreDataTest
//
//  Created by yanguo sun on 2023/10/19.
//

import SwiftUI

struct Channel: Decodable {
    var channelID:String = ""
    var name:String = ""
    var link:String = ""
}

extension Channel: Identifiable {
    var id: String {
        channelID
    }
}

public struct SettingView: View {

    let channelLocalDataList:[Channel] = [Channel(channelID: "1", name: "关于 拆字字典app", link: "https://dacaiguoguo.github.io/ChaiziPrivacyPolicy.html"),
                                          Channel(channelID: "2", name: "联系：dacaiguoguo@163.com", link: "mailto:dacaiguoguo@163.com")]

    public var body: some View {

        List {
            Section(content: {
                ForEach(channelLocalDataList) { channel in
                    Link(LocalizedStringKey(channel.name), destination: URL(string: channel.link)!)
                        .foregroundColor(.blue)
                        .font(.headline)
                }
            })

        }.navigationTitle("关于")
            .navigationBarTitleDisplayMode(.inline)
    }
}


struct SettingView_Previews: PreviewProvider {
    static var previews: some View {
        SettingView()
    }
}
