//
//  FtContentView.swift
//  CoreDataTest
//
//  Created by yanguo sun on 2023/10/19.
//

import SwiftUI
import CoreData
import SafariServices


struct ChaiZiItem: Hashable, Identifiable {
    var id: String {
        "\(index)-\(content)"
    }
    let content: String
    let index: Int
}


struct ChaiZiView<T>: View where T:AbsEntity {
    @Environment(\.managedObjectContext) private var viewContext
    var filename:String
    @FetchRequest(
        entity: T.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \T.index2, ascending: true)],
        animation: .default) private var items: FetchedResults<T>

    @State private var filterValue = ""
    @State private var selectedFruit = "全部"

    var fruits = ["全部", "收藏"]

    var body: some View {
        NavigationView {
            VStack {
                pickerView()
                inputView()
                ScrollView {
                    LazyVStack(alignment: .leading) {
                        ForEach(items) { item in
                            HStack{
                                content(item)
                                Spacer()
                                Text(getPinyin(from: String((item.name?.first)!) ) ?? "")
                                Button(action: {
                                    item.isStarred.toggle()
                                    do {
                                        try viewContext.save()
                                        print("Item marked as starred.")
                                    } catch {
                                        print("Error saving context: \(error)")
                                    }

                                }) {
                                    Image(systemName: item.isStarred ? "star.fill" : "star")
                                        .foregroundColor(item.isStarred ? .yellow : .gray)
                                }
                                .frame(width: 100)
                                detailButton(item)
                            }.padding()
                            Divider()
                        }
                    }
                }
            }
            .navigationTitle("拆字字典").navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: Image("AppIconSmall"), trailing:aboutButton())
            .onAppear(perform: addAllItem)
        }.navigationViewStyle(StackNavigationViewStyle())
    }


    private func applyFilter() {
        // 更新筛选条件或执行其他操作
        // 创建第一个条件：isStarred == true
        let isStarredPredicate = NSPredicate(format: "isStarred == %d", true)
        if filterValue.isEmpty {
            items.nsPredicate = selectedFruit == "全部" ? nil : isStarredPredicate;
        } else {
            // 创建第二个条件：name 包含 "W"（不区分大小写）
            let nameContainsWPredicate = NSPredicate(format: "name CONTAINS[cd] %@", filterValue)
            if selectedFruit == "全部" {
                items.nsPredicate = nameContainsWPredicate;
            } else {
                // 创建一个复合谓词，将两个条件使用 AND 连接
                let andPredicate = NSCompoundPredicate(type: .and, subpredicates: [isStarredPredicate, nameContainsWPredicate])
                items.nsPredicate = andPredicate
            }
        }
    }

    private func pickerView() -> some View {
        Picker("", selection: $selectedFruit) {
            ForEach(fruits, id: \.self) {
                Text($0)
            }
        }.pickerStyle(SegmentedPickerStyle()).padding(.horizontal)
            .onChange(of: selectedFruit) { newValue in
                // 在选项变化时执行操作
                print("Selected fruit: \(newValue)")
                applyFilter()
            }
    }

    private func inputView() -> some View {
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
        }.padding(10)
    }

    private func detailButton(_ item:T) -> some View {
        Button("详细") {
            if let url = item.url {
                let sc = SFSafariViewController(url: url)
                UIApplication.shared.windows.first?.rootViewController?.present(sc, animated: true, completion: nil)
            }
        }.foregroundColor(.blue).font(.subheadline)
    }
    private func aboutButton() -> some View {
        Group {
            NavigationLink("关于") {
                SettingView()
            }
        }
    }

    private func content(_ item:T) -> some View {
        let str = item.name ?? " "
        var result = AttributedString(stringLiteral: String(str.first!))
        result.font = .title2.bold()
        var result2 = AttributedString("  ")
        result2.font = .headline
        var result3 = AttributedString(str.dropFirst())
        result3.font = .headline
        return Text(result + result2 + result3)
    }

    private func readTextFileAndSplitByNewline(_ resource:String) -> [ChaiZiItem] {
        if let filePath = Bundle.main.path(forResource: resource, ofType: "txt") {
            do {
                let fileContent = try String(contentsOfFile: filePath, encoding: .utf8)
                let lines = fileContent.components(separatedBy: .newlines)
                return lines.enumerated().map { (index, element) in
                    ChaiZiItem(content: element, index: index)
                }
            } catch {
                print("Error reading the file: \(error)")
            }
        } else {
            print("File not found")
        }
        return []
    }

    private func readAndRemoveDuplicatesFromFile(filePath: String) {
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
            try uniqueContent.write(toFile: "/Users/sunyanguo/Developer/CoreDataTest/CoreDataTest/\(filename).txt", atomically: false, encoding: .utf8)

            print("重复行已经被移除并写回到文件，顺序保持不变。")
        } catch {
            print("读取文件时出错: \(error)")
        }
    }

    private func deleteAllData() {
        let context = viewContext // 你的托管对象上下文
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: String(describing: T.self))

        do {
            let objects = try context.fetch(fetchRequest)
            for case let object as NSManagedObject in objects {
                context.delete(object)
            }

            try context.save()
            print("所有数据已被删除。")
        } catch {
            print("删除数据时出错: \(error)")
        }
    }

    private func getPinyin(from text: String) -> String? {
        let mutableString = NSMutableString(string: text) as CFMutableString
        CFStringTransform(mutableString, nil, kCFStringTransformToLatin, false)
        CFStringTransform(mutableString, nil, kCFStringTransformStripDiacritics, false)
        return mutableString as String
    }


    private func addAllItem() {
        //  if let filePath = Bundle.main.path(forResource: "chaizi-ft", ofType: "txt") {
        //      readAndRemoveDuplicatesFromFile(filePath: filePath)
        //  }
        // deleteAllData()
        // return;
        if filename == "chaizi-fav" {
            return;
        }

        let context = viewContext // 你的托管对象上下文
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: String(describing: T.self))

        do {
            let objects = try context.fetch(fetchRequest)
            if objects.isEmpty {
                // 调用函数来读取文件和拆分文本
                let lines = readTextFileAndSplitByNewline(filename)
                for (index, element) in lines.enumerated() {
                    let newItem = T(context: viewContext)
                    newItem.index2 = Int16(index)
                    newItem.name = element.content
                    newItem.url = getUrl(element)
                    viewContext.insert(newItem)
                }
                do {
                    try viewContext.save()
                } catch {
                    let nsError = error as NSError
                    fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
                }
            }
        } catch {
            print("添加数据时出错: \(error)")
        }
    }

    private func getUrl(_ item: ChaiZiItem) -> URL {
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

struct ChaiZiView_Previews: PreviewProvider {
    static var previews: some View {
        ChaiZiView<FtItem>(filename: "chaizi-ft")
    }
}
