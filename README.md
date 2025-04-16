# Lien - Mindful Connection Keeper

Lien is an iOS application designed to help users mindfully nurture and maintain their important personal relationships. It focuses on visualizing time, tracking interactions, and providing gentle reminders to connect with friends, family, and colleagues.

Inspired by concepts of time perception and the value of human connection, Lien aims for a clean, minimalist, and thoughtful user experience.

## Key Features

*   **Onboarding:** Simple setup process to capture user's age and life expectancy for personalized time perspectives.
*   **Contact Management:** Add, edit, and delete contacts, storing essential details like name, birthday, relationship type, desired contact frequency, and social links.
*   **Interaction Logging:** Record interactions (meetings, calls, messages) with contacts, including optional notes about the context or topic discussed. View interaction history per contact.
*   **Reach Out Suggestions:** Home screen highlights contacts who are due or overdue for interaction based on their set frequency.
*   **Tagging & Filtering:** Assign custom tags to contacts and filter the contact list based on these tags.
*   **Relationship Health:** Visual indicators (colored dots) in the contact list and detail view show the status of your connection frequency (Recent, Approaching, Due).
*   **Time Perspective:** 
    *   Visualizes the user's life progress based on age and life expectancy.
    *   Shows remaining weeks and potential future interactions with individual contacts.
    *   Provides broader life perspective stats (e.g., remaining weekends, seasons).
*   **Inspirational Quotes:** Displays relevant quotes about connection, time, and life on the home screen.
*   **Minimalist Design:** Clean, divider-based layout with adaptive light/dark mode support.

## Technology Stack

*   **UI:** SwiftUI
*   **State Management:** Combine (`ObservableObject`)
*   **Persistence:** `UserDefaults` (for onboarding status and contact data serialization)
*   **Language:** Swift

## Setup

1.  Clone the repository.
2.  Open the `Lien.xcodeproj` file in Xcode.
3.  Build and run the project on a simulator or physical device (iOS).

## Future Considerations

*   Adding input fields for Anniversaries.
*   Implementing formal Contact Groups.
*   Refining the derivation of stats (e.g., `meetingCount`) directly from `interactionHistory`.
*   More robust data persistence (e.g., Core Data, SwiftData).
*   iCloud Sync.

## License

MIT License 