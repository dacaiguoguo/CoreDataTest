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


    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    TextField("Enter Filter Value", text: $filterValue)
                        .padding(10)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onSubmit {
                            applyFilter()
                        }
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
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
                List {
                    ForEach(items) { item in
                        NavigationLink {
                            Text("Item at \(item.name ?? "")")
                        } label: {
                            Text("\(item.name ?? "")")
                        }
                    }
                    .onDelete(perform: deleteItems)
                }
            }
            .navigationTitle("拆字字典").navigationBarTitleDisplayMode(.inline)
            .onAppear{addAllItem()}
        }.navigationViewStyle(StackNavigationViewStyle())
    }

    private func addAllItem() {
        DispatchQueue.global().async {
            if items.count == 0 {
                // 调用函数来读取文件和拆分文本
                let lines = readTextFileAndSplitByNewline()
                DispatchQueue.main.async {
                    lines.forEach { element in
                        let newItem = Item(context: viewContext)
                        newItem.timestamp = Date()
                        newItem.name = element.content
                        newItem.url = getUrl(element)
                        viewContext.insert(newItem)
                    }
                }
                // 保存实体
                do {
                    try viewContext.save()
                } catch {
                    // Replace this implementation with code to handle the error appropriately.
                    // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                    let nsError = error as NSError
                    fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
                }
            } else {
                print("Error counting records")
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

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { items[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
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