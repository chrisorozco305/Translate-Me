import SwiftUI
import FirebaseFirestore

struct TranslateView: View {
    
    @State private var englishWord: String = ""
    @State private var spanishWord: String = ""
    @State private var isLoading = false
    private let db = Firestore.firestore()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Translate Me")
                    .font(.largeTitle)
                
                // Text field for entering English word
                TextField("Enter English word", text: $englishWord)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                // Translate button
                Button(action: {
                    translateUsingMyMemory()  // Use MyMemory API function
                }) {
                    Text("Translate")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                .disabled(isLoading)
                
                // Box displaying the translated word
                Text(spanishWord)
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
                    .padding(.horizontal)
                
                // Navigation link to SavedTranslationsView
                NavigationLink(destination: SavedTranslationsView()) {
                    Text("View saved translations")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.opacity(0.2))
                        .foregroundColor(.blue)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
            }
            .padding()
        }
    }
    
    // Function to translate using MyMemory API and save to Firestore
    func translateUsingMyMemory() {
        guard !englishWord.isEmpty else { return }
        isLoading = true
        
        // MyMemory API URL with parameters for English to Spanish translation
        let urlString = "https://api.mymemory.translated.net/get?q=\(englishWord)&langpair=en|es"
        
        // Encode URL to handle spaces and special characters in `englishWord`
        guard let url = URL(string: urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!) else {
            print("Invalid URL")
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
            }
            
            if let error = error {
                print("Error during translation request: \(error.localizedDescription)")
                return
            }
            
            guard let data = data else {
                print("No data returned")
                return
            }
            
            // Parse the JSON response to get the translated text
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let responseData = json["responseData"] as? [String: Any],
                   let translatedText = responseData["translatedText"] as? String {
                    
                    DispatchQueue.main.async {
                        self.spanishWord = translatedText
                        self.saveTranslationToFirestore()
                    }
                } else {
                    print("Translation failed or invalid response format")
                }
            } catch {
                print("Error parsing translation response: \(error.localizedDescription)")
            }
        }.resume()
    }
    
    // Save the translated word to Firestore
    func saveTranslationToFirestore() {
        db.collection("translations").addDocument(data: [
            "englishWord": englishWord,
            "spanishWord": spanishWord
        ]) { error in
            if let error = error {
                print("Error saving translation: \(error.localizedDescription)")
            } else {
                print("Translation saved successfully!")
            }
        }
    }
}

// View for displaying saved translations with a Delete All button
struct SavedTranslationsView: View {
    @State private var savedTranslations: [String] = []
    private let db = Firestore.firestore()

    var body: some View {
        VStack {
            Text("Saved Translations")
                .font(.largeTitle)
                .padding()

            List(savedTranslations, id: \.self) { translation in
                Text(translation)
            }
            .onAppear {
                fetchSavedTranslations()
            }
            
            // Delete All button at the bottom
            Button(action: {
                deleteAllTranslations()
            }) {
                Text("Delete All Translations")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
        .padding()
    }

    // Fetch saved translations from Firestore
    func fetchSavedTranslations() {
        db.collection("translations").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching translations: \(error.localizedDescription)")
                return
            }
            
            savedTranslations = snapshot?.documents.compactMap { document in
                document.data()["spanishWord"] as? String
            } ?? []
        }
    }

    // Function to delete all documents in the translations collection
    private func deleteAllTranslations() {
        db.collection("translations").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching documents for deletion: \(error.localizedDescription)")
                return
            }
            
            // Delete each document in the translations collection
            guard let documents = snapshot?.documents else { return }
            for document in documents {
                document.reference.delete { error in
                    if let error = error {
                        print("Error deleting document: \(error.localizedDescription)")
                    } else {
                        print("Document successfully deleted!")
                    }
                }
            }
            
            // Clear the local saved translations array
            self.savedTranslations.removeAll()
        }
    }
}
