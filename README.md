# DataDay Mobile Apps

<p align="center">
  <strong>Mobile Applications by DataDay Technology Solutions</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Platform-iOS-blue.svg" alt="Platform iOS">
  <img src="https://img.shields.io/badge/Swift-5.9-orange.svg" alt="Swift 5.9">
  <img src="https://img.shields.io/badge/License-Proprietary-red.svg" alt="License">
</p>

---

## Applications

### HallPass (formerly TeacherLink)

<img src="TeacherLink/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png" width="80" height="80" alt="HallPass">

**Empowering School Communication**

A comprehensive iOS app that connects teachers, parents, and administrators for seamless school communication.

| Feature | Description |
|---------|-------------|
| Messaging | Real-time chat between teachers and parents |
| Hall Passes | Digital hall pass system with time tracking |
| Class Stories | Share classroom moments with photos |
| Points System | Gamified behavior tracking and rewards |
| Admin Dashboard | System-wide management tools |

**Tech Stack:** SwiftUI, Swift 5.9, Supabase, PostgreSQL

[View Full Documentation](TeacherLink/README.md)

---

## Quick Start

```bash
# Clone the repository
git clone https://github.com/DataDay-Technology-Solutions/mobile-apps.git

# Navigate to the app
cd mobile-apps/TeacherLink

# Open in Xcode
open TeacherLink.xcodeproj
```

---

## Repository Structure

```
mobile-apps/
├── TeacherLink/           # HallPass iOS App
│   ├── Models/            # Data models
│   ├── Views/             # SwiftUI views
│   ├── ViewModels/        # MVVM view models
│   ├── Services/          # Backend services
│   └── Resources/         # Assets and configs
├── README.md              # This file
└── supabase_schema.sql    # Database schema
```

---

## Development

### Requirements

- macOS 14.0+ (Sonoma)
- Xcode 15.0+
- iOS 17.0+ deployment target
- Supabase account (for backend services)

### Building

1. Open `TeacherLink.xcodeproj` in Xcode
2. Select your target device or simulator
3. Press `Cmd + R` to build and run

### Testing

The app includes mock data mode for development:

```swift
// TeacherLinkApp.swift
let USE_MOCK_DATA = true
```

---

## Contributing

We welcome contributions! Please read the contribution guidelines in each app's README.

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

---

## Contact

**DataDay Technology Solutions**

- Website: [datadaytech.com](https://datadaytech.com)
- Email: support@datadaytech.com
- GitHub: [@DataDay-Technology-Solutions](https://github.com/DataDay-Technology-Solutions)

---

<p align="center">
  Copyright 2024-2025 DataDay Technology Solutions. All rights reserved.
</p>
