//
//  ContentView.swift
//  Authors_UI
//
//  Created by Ivan on 09.11.2020.
//  Copyright © 2020 Ivan. All rights reserved.
//

import SwiftUI
import Alamofire
import WebKit

struct Author: Decodable, Hashable {
    var id: Int
    var firstName = ""
    var lastName = ""
    var spotlight = ""
    var description = ""
    var worksIds = [Int]()
    var fullName: String {
        return "\(self.firstName) \(self.lastName)"
    }
    
    init(_ listParams: [String: Any]){
        self.id = Int(listParams["authorid"] as! String)!
        self.firstName = (listParams["authorfirst"] ?? "") as! String
        self.lastName = (listParams["authorlast"] ?? "") as! String
        self.spotlight = (listParams["spotlight"] ?? "") as! String
        if let attributedString = try? NSAttributedString(data: Data(self.spotlight.utf8), options: [.documentType: NSAttributedString.DocumentType.html], documentAttributes: nil) {
            self.description = attributedString.string
        }
        
        if let works = listParams["works"] as? [String: Any] {
            if let work = works["works"] as? String {
                self.worksIds.append(Int(work)!)
            } else if let workList = works["works"] as? [String] {
                for work in workList {
                    self.worksIds.append(Int(work)!)
                }
            }
        }
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
                                let params = ["start": "0", "max": "10", "expandLevel": "1", searchParam : self.searchText]
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
                                        self.authors.append(Author(item))
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
        List {
            if selectedAuthor != nil {
                Text(selectedAuthor!.fullName)
                if self.selectedAuthor!.spotlight != "" {
                    HTMLStringView(htmlContent: self.selectedAuthor!.spotlight)
                    Text(selectedAuthor!.description)
                } else {
                    Text("No description").foregroundColor(.gray)
                }
                Text("List of works:")
                if !selectedAuthor!.worksIds.isEmpty {
                    ForEach(selectedAuthor!.worksIds, id: \.self) { id in
                        Text(String(id))
                    }
                } else {
                    Text("No works").foregroundColor(.gray)
                }
            } else {
                Text("Detail view content goes here")
            }
        }.navigationBarTitle(Text("Author"))
    }
}

struct HTMLStringView: UIViewRepresentable
{
    let htmlContent: String

    func makeUIView(context: Context) -> WKWebView {
        return WKWebView()
    }
    func updateUIView(_ webView: WKWebView, context: Context) {
        DispatchQueue.main.async {
            webView.loadHTMLString(self.htmlContent, baseURL: nil)
        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
