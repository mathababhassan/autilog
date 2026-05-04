# AutiLog

A care coordination mobile app for parents of children with autism and their therapists.
Built with Flutter and Firebase.

---

## Getting Started

### Prerequisites
- Flutter SDK installed
- Firebase CLI installed
- Android Studio or VS Code

### Setup
1. Clone the repository
   git clone https://github.com/mathababhassan/autilog.git

2. Install dependencies
   flutter pub get

3. Run the app
   flutter run

---

## Git Workflow

### Branching
Never push directly to main. Always create a branch for your work.

Branch naming convention:
- feature/login-screen
- feature/parent-registration
- feature/child-profile
- feature/therapist-profile

Create a branch:
   git checkout -b feature/your-feature-name

### Committing
Write clear commit messages that describe what you did.

Good examples:
- "implement login screen UI"
- "add Firebase auth sign-in call"
- "fix validation on registration form"

Bad examples:
- "fix"
- "update"
- "done"

Commit your changes:
   git add .
   git commit -m "your message here"

### Pushing
Push your branch to GitHub:
   git push origin feature/your-feature-name

### Pull Requests
After pushing, go to GitHub and open a Pull Request into main.
The Scrum Master will review and approve before merging.
Do not merge your own pull request.

---

## Branch Structure
- main — stable, production-ready code only
- feature/* — individual feature branches
