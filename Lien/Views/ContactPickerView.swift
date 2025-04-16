import SwiftUI
import ContactsUI
import Contacts

struct ContactPickerView: UIViewControllerRepresentable {
    
    // Callback closure to pass selected contacts back to SwiftUI
    var onContactsSelected: ([CNContact]) -> Void

    func makeUIViewController(context: Context) -> CNContactPickerViewController {
        let picker = CNContactPickerViewController()
        picker.delegate = context.coordinator
        
        // Specify desired contact properties
        // Note: Requesting image data might slow down picker loading
        picker.displayedPropertyKeys = [
            CNContactGivenNameKey, 
            CNContactFamilyNameKey, 
            CNContactPhoneNumbersKey,
            CNContactEmailAddressesKey,
            CNContactBirthdayKey,
            CNContactImageDataAvailableKey, // Check availability first
            CNContactImageDataKey           // Request actual data if available
        ]
        
        // Optional: Predicate to filter contacts (e.g., only those with phone numbers)
        // picker.predicateForEnablingContact = NSPredicate(format: "phoneNumbers.@count > 0")
        
        return picker
    }

    func updateUIViewController(_ uiViewController: CNContactPickerViewController, context: Context) {
        // No update needed typically
    }

    // MARK: - Coordinator

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, CNContactPickerDelegate {
        var parent: ContactPickerView

        init(_ parent: ContactPickerView) {
            self.parent = parent
        }

        // Delegate method when multiple contacts are selected
        func contactPicker(_ picker: CNContactPickerViewController, didSelect contacts: [CNContact]) {
            print("DEBUG: Contact Picker did select \(contacts.count) contacts.")
            parent.onContactsSelected(contacts)
        }

        // Delegate method when a single contact is selected (if single selection was enabled)
        // func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
        //     print("DEBUG: Contact Picker did select single contact.")
        //     parent.onContactsSelected([contact])
        // }

        // Delegate method when the picker is cancelled
        func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
            print("DEBUG: Contact Picker cancelled.")
            // You might want to call the callback with an empty array or handle cancellation differently
            // parent.onContactsSelected([]) 
        }
    }
}

// Preview might be difficult without contact access simulation
#Preview {
    // Dummy view to present the sheet for previewing the picker UI itself
    struct PreviewContainer: View {
        @State var showPicker = true
        var body: some View {
            Text("Tap button to show picker (if needed)")
            .sheet(isPresented: $showPicker) {
                ContactPickerView { contacts in
                    print("Preview selected \(contacts.count) contacts")
                    showPicker = false
                }
            }
        }
    }
    return PreviewContainer()
} 