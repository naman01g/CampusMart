# CampusMart

A college-only marketplace where verified students can buy, sell, exchange, or give away products they no longer need.

## Tech Stack

- **Mobile**: Flutter + Dart + Riverpod
- **Web**: React + TypeScript + Vite + Riverpod
- **Backend**: Firebase (Auth, Firestore, Storage, Messaging, Functions)
- **Hosting**: Firebase Hosting

## Project Structure

```
campusmart/
├── mobile/                 # Flutter mobile app
│   ├── lib/
│   │   ├── core/           # Theme, constants, firebase config, router
│   │   ├── features/       # Feature modules (auth, listings, chat, user, admin)
│   │   │   ├── auth/
│   │   │   ├── listings/
│   │   │   ├── chat/
│   │   │   ├── user/
│   │   │   ├── admin/
│   │   │   └── home/
│   │   └── shared/         # Shared models, widgets, providers
│   └── pubspec.yaml
├── web/                    # React + TypeScript web app
│   ├── src/
│   │   ├── features/       # Feature modules
│   │   ├── shared/         # Shared components, hooks, types, utils
│   │   ├── App.tsx
│   │   └── main.tsx
│   ├── package.json
│   └── vite.config.ts
├── functions/              # Firebase Cloud Functions
│   └── src/
├── firebase/               # Firebase configuration
│   ├── firestore.rules
│   ├── firestore.indexes.json
│   ├── storage.rules
│   └── firebase.json
└── README.md
```

## Design System

- **Primary**: Charcoal `#202020`
- **Accent**: Vermilion `#E4572E`
- **Background**: Warm Cream `#F6F4EF`
- **Surface**: `#FFFEFA`
- **Color Ratio**: 70% neutral, 20% charcoal, 10% vermilion

## Features

### MVP Features
- ✅ Student authentication with college email verification
- ✅ Browse listings with categories, search, filters
- ✅ Create/Edit/Delete listings (Sell, Exchange, Free)
- ✅ Real-time chat between buyers and sellers
- ✅ User profiles, my listings, favorites
- ✅ Report/Block users and listings
- ✅ Admin dashboard for moderation

### Payment Flow
- No online payments in MVP
- Buyer contacts seller → Meet on campus → Inspect → Pay directly → Seller marks as SOLD

## Getting Started

### Prerequisites
- Flutter SDK 3.12+
- Node.js 20+
- Firebase CLI
- A Firebase project

### Web App
```bash
cd web
cp .env.example .env
# Fill in your Firebase config in .env
npm install
npm run dev
```

### Mobile App
```bash
cd mobile
flutter pub get
# Configure Firebase for Android/iOS
flutter run
```

### Functions
```bash
cd functions
npm install
npm run build
firebase deploy --only functions
```

### Firebase Setup
```bash
# Deploy rules and indexes
firebase deploy --only firestore:rules,firestore:indexes,storage
```

## Security

- All authorization enforced via Firestore Security Rules
- Users can only modify their own data
- Admins have elevated privileges
- Sensitive fields protected

## Deployment

```bash
# Build web
cd web && npm run build

# Deploy everything
firebase deploy
```

## License

Private project - CampusMart