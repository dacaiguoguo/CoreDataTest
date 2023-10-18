//
//  ContentView.swift
//  CoreDataTest
//
//  Created by yanguo sun on 2023/10/18.
//

import SwiftUI
import CoreData

struct RItem: Hashable, Identifiable {
    var id: String {
        "\(index)-\(content)"
    }
    let content: String
    let index: Int

}

func readTextFileAndSplitByNewline() -> [RItem] {
    if let filePath = Bundle.main.path(forResource: "chaizi-jt", ofType: "txt") {
        do {
            let fileContent = try String(contentsOfFile: filePath, encoding: .utf8)
            let lines = fileContent.components(separatedBy: .newlines)
            return lines.enumerated().map { (index, element) in
                RItem(content: element, index: index)
            }
        } catch {
            print("Error reading the file: \(error)")
        }
    } else {
        print("File not found")
    }
    return []
}


struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

    //    @FetchRequest(
    //        sortDescriptors: [NSSortDescriptor(keyPath: \Item.timestamp, ascending: true)],
    //        animation: .default)
    //    private var items: FetchedResults<Item>
    @FetchRequest(
        entity: Item.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Item.timestamp, ascending: true)],
        //        predicate: NSPredicate(format: "propertyName == %@", "")
        animation: .default) private var items: FetchedResults<Item>

    @State private var filterValue = ""

    func applyFilter() {
        // 更新筛选条件或执行其他操作
        items.nsPredicate = filterValue.isEmpty ? nil :NSPredicate(format: "name CONTAINS[c] %@", filterValue)
    }

    func inputView() -> some View {
        HStack {
            TextField("输入要搜索的字", text: $filterValue)
                .padding(10)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onSubmit {
                    applyFilter()
                }
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .submitLabel(.go)
            if !filterValue.isEmpty {
                Button(action: {
                    filterValue = ""
                    applyFilter()
                }) {
                    Image(systemName: "xmark.circle.fill")
                }
                .padding(10)
                .background(Color(.systemGray6))
                .cornerRadius(10)
            }
        }
    }
    var body: some View {
        NavigationView {
            VStack {
                inputView()
                ScrollView {
                    LazyVStack(alignment: .leading) {
                        ForEach(items) { item in
                            HStack{
                                Text(item.name ?? "")
                                Spacer()
                                Link("详细", destination: item.url!)
                                    .foregroundColor(.blue)
                                    .font(.subheadline)
                            }.padding()
                            Divider()
                        }
                    }
                }

            }
            .navigationTitle("拆字字典").navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing:completeStatus())
            .onAppear(perform: addAllItem)
        }.navigationViewStyle(StackNavigationViewStyle())
    }

    func completeStatus() -> some View {
        Group {
            NavigationLink("关于") {
                SettingView()
            }
        }
    }


    func readAndRemoveDuplicatesFromFile(filePath: String) {
        do {
            let fileContents = try String(contentsOfFile: filePath, encoding: .utf8)
            var uniqueLines = [String]() // 用于存储不重复的行

            let lines = fileContents.components(separatedBy: .newlines)

            for line in lines {
                if !uniqueLines.contains(line) {
                    uniqueLines.append(line)
                }
            }
            // 将不重复的行内容写回文件
            let uniqueContent = uniqueLines.joined(separator: "\n")
            try uniqueContent.write(toFile: "/Users/sunyanguo/Developer/CoreDataTest/CoreDataTest/chaizi-jt.txt", atomically: false, encoding: .utf8)

            print("重复行已经被移除并写回到文件，顺序保持不变。")
        } catch {
            print("读取文件时出错: \(error)")
        }
    }

    private func addAllItem() {
//        if let filePath = Bundle.main.path(forResource: "chaizi-jt", ofType: "txt") {
//            readAndRemoveDuplicatesFromFile(filePath: filePath)
//        }

        if UserDefaults.standard.bool(forKey: "addAllItem2") == false {
            // 调用函数来读取文件和拆分文本
            let lines = readTextFileAndSplitByNewline()
            lines.forEach { element in
                let newItem = Item(context: viewContext)
                newItem.timestamp = Date()
                newItem.name = element.content
                newItem.url = getUrl(element)
                viewContext.insert(newItem)
            }
            // 保存实体
            do {
                try viewContext.save()
                UserDefaults.standard.set(true, forKey: "addAllItem2")
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }

    private func getUrl(_ item: RItem) -> URL {
        if let firstCharacter = item.content.first {
            let characterString = String(firstCharacter)
            if let encodedCharacter = characterString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
                return URL(string: "https://dict.baidu.com/s?wd=\(encodedCharacter)")!
            }
        } else {
            print("字符串为空：\(item.index)")
        }
        return URL(string: "https://dict.baidu.com")!
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}


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


    public init(){}

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
        }.navigationTitle("TitleHelp")
            .navigationBarTitleDisplayMode(.inline)
    }
}

