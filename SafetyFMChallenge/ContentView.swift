//
//  ContentView.swift
//  SafetyFMChallenge
//
//  Created by Gilberto Magno on 01/12/25.
//

import SwiftUI
import FoundationModels

struct ContentView: View {

    @State var selectedPersona: Persona = .child
    @State var movieTitle: String = ""
    @State var explanationText: String = "Enter a movie title and choose a persona to generate a fun fact and curiosities."
    @State var isLoading: Bool = false

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                ScrollView {
                    Text(explanationText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)
                }
                .scrollIndicators(.never)
                .frame(maxHeight: 260)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 8) {
                    Text("Tell me a fact about the movie...")
                        .font(.headline)

                    TextField("Type a movie title", text: $movieTitle)
                        .textFieldStyle(.roundedBorder)
                        .submitLabel(.go)
                        .onSubmit { Task { await generateFact() } }
                }

                Spacer(minLength: 0)

                Button(action: { Task { await generateFact() } }) {
                    if isLoading {
                        ProgressView().frame(maxWidth: .infinity)
                    } else {
                        Text("Generate Fact")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isLoading)
            }
            .padding()
            .navigationTitle("Movie Facts")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Picker("Persona", selection: $selectedPersona) {
                        ForEach(Persona.allCases) { persona in
                            Text(persona.rawValue).tag(persona)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 420)
                }
            }
        }
    }
}

#Preview {
    ContentView()
}

