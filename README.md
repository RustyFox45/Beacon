# 🏮 Gospel Beacon

**Gospel Beacon** is a cross-platform Flutter application designed to help individuals, families, and church groups prepare, organize, and share gospel-centered lesson plans and study sessions. Backed by **Supabase**, it brings together structured lesson building, hymn and scripture resource pickers, group collaboration, and recurring event scheduling in one clean, intuitive workspace.

---

## ✨ Key Features

### 📖 Interactive Lesson Builder & Templates
* **Flexible Lesson Editor:** Build custom lessons using drag-and-drop, reorderable sections (`Prayer`, `Hymn`, `Text Content`, and `Resources`).
* **Ready-to-Use Templates:** Start from a blank canvas or launch a pre-structured **Family Home Evening (FHE)** template (complete with Invocation, Hymns, Spiritual Thought, Lesson, Activity, and Benediction).
* **Built-In Hymn Search & Viewer:** Search all 341 English hymns by number or title and preview lyrics directly inside the app via an integrated WebView.
* **Web Resource Picker:** Browse Gospel Library study materials inside the app and attach rich link previews (complete with page titles and thumbnails) directly to lesson sections.
* **Smart Library Controls:** Filter lessons by ownership (*Owned by anyone*, *Owned by me*, *Not owned by me*), sort by *Last opened*, *Last modified*, or *Title*, and toggle between **List** and **Grid** views.

### 👥 Groups & Session Coordination
* **Group Management:** Create public or private study groups, customize group banners, assign `Admin` or `Member` roles, and invite members via user search or unique 6-character **Group Add Codes**.
* **Single & Recurring Events:** Schedule one-time study sessions or set up recurring events (*Weekly*, *Every 2 weeks*, or *Monthly*) with automatic occurrence generation and date-by-date navigation.
* **Lesson-to-Event Attachment:** Link specific lesson plans directly to group events or individual recurring event dates.
* **Participant & Role Tracking:** Assign event roles (e.g., Speaker, Teacher, Coordinator) and track member confirmation statuses.
* **Session Discussion:** Coordinate with group members using real-time event comment threads.

### 🔐 Authentication & User Profiles
* **Full Auth Flow:** Email/password sign-up with 6-digit OTP email verification, password recovery via OTP, and local "Remember me" convenience.
* **Custom Profiles:** Update display names, contact details, and upload profile avatars stored securely in Supabase Storage.

---

## 🛠️ Tech Stack

* **Frontend Framework:** [Flutter](https://flutter.dev/) (Dart SDK `^3.11.0`, Material 3)
* **State Management:** [Provider](https://pub.dev/packages/provider) (`ChangeNotifier` pattern across Auth, User, Group, Lesson, and Event providers)
* **Backend & Database:** [Supabase](https://supabase.com/) (`supabase_flutter` for PostgreSQL, Authentication, Row-Level Security, RPC functions, and Storage buckets)
* **Key Packages:**
  * `webview_flutter` & `metadata_fetch` — In-app study browser, hymn viewer, and OpenGraph link preview extraction
  * `flutter_dotenv` — Environment variable management
  * `image_picker` — Avatar and group banner uploads
  * `google_fonts` (*Spectral* & *Noto Sans*) & `flutter_svg` — Custom typography and vector iconography
  * `shared_preferences` — Local user preference persistence

---

## 📁 Project Structure

```text
cs456-main/
├── assets/
│   ├── icons/                 # Custom SVG & PNG UI icons
│   └── images/                # App branding, lantern icon, and FHE template imagery
├── lib/
│   ├── data/
│   │   └── hymns.dart         # Complete 341-hymn directory and URL slug mappings
│   ├── models/                # Data models (User, Group, LessonPlan, Event, EventOccurrence, etc.)
│   ├── providers/             # State management (Auth, User, Group, Lesson, Event providers)
│   ├── screens/
│   │   ├── auth/              # Login, Sign Up, OTP Verification, Password Reset, Legal docs
│   │   ├── groups/            # Group management, Member roles, Recurring sessions, Event chat
│   │   ├── lessons/           # Drag-and-drop Lesson Editor, Web Resource Picker & Viewer
│   │   ├── profile/           # User profile display and editing
│   │   └── home_screen.dart   # Main dashboard with templates and lesson library
│   ├── services/              # Supabase API & RPC abstraction layer
│   ├── theme/                 # Custom teal/gold color palette, typography, and SVG icon helpers
│   ├── utils/                 # Hymn search algorithm, toast notifications, and UI helpers
│   ├── widgets/               # Reusable UI components (HymnPicker, OccurrenceNavigator, OtpInputRow, etc.)
│   └── main.dart              # App entry point, environment initialization, and MultiProvider setup
├── supabase/
│   ├── config.toml            # Local Supabase CLI configuration
│   ├── migrations/            # PostgreSQL schema, triggers, RPCs, and RLS security policies
│   └── seed.sql               # Local development seed data
└── pubspec.yaml               # Project dependencies and asset declarations
```

---

## 🚀 Getting Started

Follow these steps to set up and run **Gospel Beacon** on your local machine.

### 1. Prerequisites
* **Flutter SDK:** Ensure you have Flutter installed (configured for Dart SDK `^3.11.0`; `.fvm` is included if you use Flutter Version Management).
* **Supabase Account / CLI:** A [Supabase](https://supabase.com/) project (or the [Supabase CLI](https://supabase.com/docs/guides/cli) for running locally).
* **Platform Tooling:** Xcode (for iOS/macOS), Android Studio (for Android), or a modern web browser (for Flutter Web).

### 2. Clone the Repository
```bash
git clone <your-repository-url>
cd cs456-main
```

### 3. Install Dependencies
```bash
flutter pub get
```

### 4. Configure Environment Variables
Create a `.env` file in the root directory of the project (alongside `pubspec.yaml`) and add your Supabase project credentials:

```env
SUPABASE_URL=https://your-project-ref.supabase.co
SUPABASE_ANON_KEY=your-supabase-anon-key
```
> **Note:** Because `.env` is bundled as a Flutter asset in `pubspec.yaml`, make sure the file exists in the project root before building or running the app.

### 5. Set Up the Supabase Database
Apply the SQL migration files located in `supabase/migrations/` to set up your tables (`profiles`, `groups`, `group_members`, `lesson_plans`, `lesson_sections`, `events`, `event_occurrences`, `event_personnel`, `event_comments`, `user_lesson_activity`), security functions, and Row-Level Security (RLS) policies:

* **Using Supabase CLI:**
  ```bash
  supabase link --project-ref your-project-ref
  supabase db push
  ```
* **Manual Setup:** Run the migration scripts in chronological order (`20260318000001` through `20260404000012`) inside your Supabase Dashboard's **SQL Editor**, and create two public storage buckets named `avatars` and `group-photos`.

### 6. Run the Application
```bash
flutter run
```
To target a specific platform (e.g., Chrome, iOS simulator, or Android emulator):
```bash
flutter devices
flutter run -d <device-id>
```

---

## 🛡️ Database & Security Highlights

* **Row-Level Security (RLS):** Every table in Supabase enforces strict RLS policies so users can only view or modify groups, events, and lessons they belong to or created.
* **Security-Definer Helper Functions:** Uses atomic RPCs (`create_group`, `upsert_lesson_activity`, `generate_event_occurrences`) and helper functions (`is_group_member`, `is_group_admin`) to prevent recursive policy lookups and ensure clean data consistency.

---

## 📄 License

This project was developed for **CS 456**. See the in-app **Terms of Service** and **Privacy Policy** screens for details on user content ownership and platform usage.
