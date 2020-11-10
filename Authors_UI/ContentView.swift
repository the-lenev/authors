//
//  ContentView.swift
//  Authors_UI
//
//  Created by Ivan on 09.11.2020.
//  Copyright © 2020 Ivan. All rights reserved.
//

import SwiftUI
import Alamofire

struct Author: Decodable, Hashable {
    var id: Int
    var firstName = ""
    var lastName = ""
    var fullName: String {
        return "\(self.firstName) \(self.lastName)"
    }
}

struct ContentView: View {
    @State private var authors = [Author]()

    var body: some View {
        NavigationView {
            MasterView(authors: $authors)
                .navigationBarTitle(Text("Search"))
            DetailView()
        }.navigationViewStyle(DoubleColumnNavigationViewStyle())
    }
}

struct MasterView: View {
    @Binding var authors: [Author]
    @State private var searchText = ""
    @State private var showCancelButton = false
    @State private var showAlert = false
    @State private var selectedIndex = 0
    private let searchTypes = ["firstName", "lastName"]

    var body: some View {
        List {
            HStack {
                TextField("Enter author name", text: $searchText
                    ,onEditingChanged: { isEnding in
                        self.showCancelButton = true
                    }
                    ,onCommit: {
                        self.authors.removeAll(keepingCapacity: true)
                        if !self.searchText.isEmpty {
                            // Alamofire
                            if let url = URL(string: "https://reststop.randomhouse.com/resources/authors") {
                                let searchParam = self.searchTypes[self.selectedIndex]
                                let params = ["start": "0", "max": "3", "expandLevel": "1", searchParam : self.searchText]
                                let headers:HTTPHeaders = ["Accept": "application/json"]
                                Alamofire.request(url, method: .get, parameters: params, encoding: URLEncoding.default, headers: headers).responseJSON {(response) in
                                    self.searchText = ""
                                    self.showCancelButton = false
                                    guard response.result.isSuccess else {
                                       print("Error: \(String(describing: response.result.error))")
                                       return
                                    }
                                    guard let value = response.result.value as? [String: AnyObject]
                                       ,let rows = value["author"] as? [[String: Any]]
                                       else {
                                            print("Error: no authors found")
                                            self.showAlert = true
                                            return
                                    }
                                    for item in rows {
                                        let authorId = Int(item["authorid"] as! String)!
                                        let authorFirst = (item["authorfirst"] ?? "") as! String
                                        let authorLast = (item["authorlast"] ?? "") as! String
                                        self.authors.append(Author(id: authorId, firstName: authorFirst, lastName: authorLast))
                                    }
                                    print(self.authors)
                                }
                            }
                        }
                    }
                )
                .alert(isPresented: $showAlert, content: {
                    Alert(title: Text("No authors found"))
                })
                if self.showCancelButton {
                    Button(action: {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        self.showCancelButton = false
                        self.searchText = ""
                        
                    },
                    label: {Text("Cancel")})
                    .foregroundColor(Color(.blue))
                }
            }
            
            Picker(selection: $selectedIndex, label: Text("Search type")) {
                ForEach(0..<self.searchTypes.count) { index in
                    Text(self.searchTypes[index]).tag(index)
                }
            }.pickerStyle(SegmentedPickerStyle())

            ForEach(self.authors, id: \.self) { author in
                NavigationLink(
                    destination: DetailView(selectedAuthor: author)
                ) {
                    Text(author.fullName)
                }
            }
        }
    }
}

struct DetailView: View {
    var selectedAuthor: Author?

    var body: some View {
        Group {
            if selectedAuthor != nil {
                Text(selectedAuthor!.fullName)
            } else {
                Text("Detail view content goes here")
            }
        }.navigationBarTitle(Text("Author"))
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
