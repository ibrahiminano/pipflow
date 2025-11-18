//
//  GeneralPreferencesView.swift
//  Pipflow
//
//  General app preferences and regional settings
//

import SwiftUI

struct GeneralPreferencesView: View {
    @StateObject private var settingsService = SettingsService.shared
    @Environment(\.presentationMode) var presentationMode
    
    @State private var selectedLanguage: AppLanguage
    @State private var selectedCurrency: Currency
    @State private var selectedDateFormat: DateFormat
    @State private var selectedNumberFormat: NumberFormat
    @State private var selectedTimeZone: TimeZone
    
    init() {
        let general = SettingsService.shared.settings.general
        _selectedLanguage = State(initialValue: general.language)
        _selectedCurrency = State(initialValue: general.currency)
        _selectedDateFormat = State(initialValue: general.dateFormat)
        _selectedNumberFormat = State(initialValue: general.numberFormat)
        _selectedTimeZone = State(initialValue: general.timezone)
    }
    
    var body: some View {
        NavigationView {
            List {
                // Language Section
                Section {
                    ForEach(AppLanguage.allCases, id: \.self) { language in
                        HStack {
                            Text(language.flag)
                                .font(.title2)
                            
                            Text(language.displayName)
                                .foregroundColor(Color.Theme.text)
                            
                            Spacer()
                            
                            if selectedLanguage == language {
                                Image(systemName: "checkmark")
                                    .foregroundColor(Color.Theme.accent)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedLanguage = language
                        }
                    }
                } header: {
                    Text("Language")
                } footer: {
                    Text("App language will change after restart")
                }
                
                // Regional Settings Section
                Section {
                    // Currency Picker
                    NavigationLink(destination: CurrencyPickerView(selectedCurrency: $selectedCurrency)) {
                        HStack {
                            Text("Currency")
                            Spacer()
                            HStack {
                                Text(selectedCurrency.symbol)
                                    .font(.headline)
                                Text(selectedCurrency.displayName)
                            }
                            .foregroundColor(Color.Theme.secondaryText)
                        }
                    }
                    
                    // Date Format
                    VStack(alignment: .leading, spacing: 8) {
                        Picker("Date Format", selection: $selectedDateFormat) {
                            ForEach(DateFormat.allCases, id: \.self) { format in
                                Text(format.example).tag(format)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        
                        Text("Example: \(selectedDateFormat.example)")
                            .font(.caption)
                            .foregroundColor(Color.Theme.secondaryText)
                    }
                    
                    // Number Format
                    VStack(alignment: .leading, spacing: 8) {
                        Picker("Number Format", selection: $selectedNumberFormat) {
                            ForEach(NumberFormat.allCases, id: \.self) { format in
                                Text(format.example).tag(format)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        
                        Text("Example: \(selectedNumberFormat.example)")
                            .font(.caption)
                            .foregroundColor(Color.Theme.secondaryText)
                    }
                } header: {
                    Text("Regional Settings")
                }
                
                // Time Zone Section
                Section {
                    NavigationLink(destination: TimeZonePickerView(selectedTimeZone: $selectedTimeZone)) {
                        HStack {
                            Label("Time Zone", systemImage: "globe")
                            Spacer()
                            Text(timeZoneDisplayName)
                                .foregroundColor(Color.Theme.secondaryText)
                        }
                    }
                } header: {
                    Text("Time")
                } footer: {
                    Text("Market hours and timestamps will be displayed in this time zone")
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("General")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveChanges()
                        presentationMode.wrappedValue.dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private var timeZoneDisplayName: String {
        if let abbreviation = selectedTimeZone.abbreviation() {
            return "\(selectedTimeZone.identifier) (\(abbreviation))"
        }
        return selectedTimeZone.identifier
    }
    
    private func saveChanges() {
        settingsService.settings.general.language = selectedLanguage
        settingsService.settings.general.currency = selectedCurrency
        settingsService.settings.general.dateFormat = selectedDateFormat
        settingsService.settings.general.numberFormat = selectedNumberFormat
        settingsService.settings.general.timezone = selectedTimeZone
    }
}

// MARK: - Time Zone Picker View
struct TimeZonePickerView: View {
    @Binding var selectedTimeZone: TimeZone
    @Environment(\.presentationMode) var presentationMode
    @State private var searchText = ""
    
    var filteredTimeZones: [TimeZone] {
        let allTimeZones = TimeZone.knownTimeZoneIdentifiers.compactMap { TimeZone(identifier: $0) }
        
        if searchText.isEmpty {
            return allTimeZones.sorted { $0.identifier < $1.identifier }
        }
        
        return allTimeZones.filter { timeZone in
            timeZone.identifier.localizedCaseInsensitiveContains(searchText)
        }.sorted { $0.identifier < $1.identifier }
    }
    
    var body: some View {
        List {
            ForEach(filteredTimeZones, id: \.identifier) { timeZone in
                HStack {
                    VStack(alignment: .leading) {
                        Text(timeZone.identifier)
                            .font(.bodyLarge)
                        
                        if let offset = timeZoneOffset(for: timeZone) {
                            Text(offset)
                                .font(.caption)
                                .foregroundColor(Color.Theme.secondaryText)
                        }
                    }
                    
                    Spacer()
                    
                    if selectedTimeZone.identifier == timeZone.identifier {
                        Image(systemName: "checkmark")
                            .foregroundColor(Color.Theme.accent)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedTimeZone = timeZone
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search time zones")
        .navigationTitle("Select Time Zone")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func timeZoneOffset(for timeZone: TimeZone) -> String? {
        let seconds = timeZone.secondsFromGMT()
        let hours = seconds / 3600
        let minutes = abs(seconds % 3600) / 60
        
        if minutes == 0 {
            return String(format: "GMT%+d", hours)
        } else {
            return String(format: "GMT%+d:%02d", hours, minutes)
        }
    }
}

// MARK: - Currency Navigation View
struct CurrencyPickerView: View {
    @Binding var selectedCurrency: Currency
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        List {
            ForEach(Currency.allCases, id: \.self) { currency in
                HStack {
                    Text(currency.symbol)
                        .font(.headline)
                        .frame(width: 30)
                    
                    Text(currency.displayName)
                        .foregroundColor(Color.Theme.text)
                    
                    Spacer()
                    
                    if selectedCurrency == currency {
                        Image(systemName: "checkmark")
                            .foregroundColor(Color.Theme.accent)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedCurrency = currency
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle("Currency")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    GeneralPreferencesView()
}