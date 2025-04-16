# Lien: Your Minimalist Relationship Companion

Lien is a SwiftUI application designed to help you mindfully nurture the important relationships in your life. It provides tools to track interactions, remember important dates, visualize your social network, and gain perspective on the time you share with others.

## Core Features

*   **People Management:** Add and edit details for the important people in your life, including contact info, birthdays, anniversaries, relationship type, connection frequency goals, notes, and tags.
*   **Timeline View:** A centralized view showing upcoming birthdays, anniversaries, life events, and suggestions for who to connect with next based on your desired frequency.
*   **Interaction Logging:** Record meetings, calls, or messages with individuals. Track optional details like location (for meetings) and how the interaction made you feel (Mood tracking).
*   **Relationship Health:** Automatically assesses the health of a relationship based on your connection frequency goals and last contact date. Allows manual overrides for a more personalized status.
*   **Network View:** A dynamic, force-directed graph visualizing your connections. Nodes represent people (including yourself), and lines show explicit links you create between individuals, as well as implicit links from you to everyone else (styled by relationship health).
*   **Life Events:** Log significant life events (new job, graduation, etc.) for people, which appear on their profile and the main timeline.
*   **Contact Import:** Quickly populate your list by importing contacts directly from your device's address book.
*   **Calendar Integration:** Add birthdays/anniversaries to your calendar from the timeline, or create draft calendar events to schedule connections directly from a person's profile.
*   **Time Perspective:** Visualizations showing estimated weeks and interactions remaining with individuals, based on age and life expectancy, promoting mindful connection.
*   **Splash Screen:** A custom launch screen introducing the app's concept.
*   **(Basic) Connection Goals:** Underlying structure to define connection goals (though the dedicated UI is pending).

## Purpose

In a busy world, Lien aims to be a simple, private tool to help you be more intentional about maintaining the bonds that matter most.

## Setup (If applicable)

*   Requires Xcode [Your Xcode Version] and iOS [Your Target iOS Version].
*   Remember to add `Privacy - Contacts Usage Description` and `Privacy - Calendars Usage Description` keys to your `Info.plist` for contact import and calendar features to function correctly.

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