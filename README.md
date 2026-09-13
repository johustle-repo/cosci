# CoSci

A Flutter learning platform for coding lessons, quizzes, simulations, puzzles,
progress tracking, and admin-managed content.

## Software Prerequisites

Install the following software before setting up CoSci:

| Software | Required version | Purpose |
| --- | --- | --- |
| Git | Latest stable | Clone and manage the source code. |
| Flutter SDK | Stable with Dart `3.10.8` or newer | Build and run the Flutter application. |
| Node.js | `22 LTS` or newer | Run the local compiler gateway and Firebase tooling. |
| npm | Included with Node.js | Install JavaScript dependencies and run project scripts. |
| Google Chrome | Latest stable | Run and test the Flutter web application. |
| Firebase CLI | Latest stable | Deploy Firestore rules, indexes, and optional Cloud Functions. |
| FlutterFire CLI | Latest stable | Generate Firebase configuration for supported Flutter platforms. |

Choose one compiler setup:

| Compiler option | Additional requirements |
| --- | --- |
| Docker (recommended) | Docker Desktop with Docker Compose. The container installs C++ `g++` and OpenJDK automatically. |
| Local compiler service | A C++17-compatible `g++` compiler and a Java JDK containing both `java` and `javac`. JavaScript uses the installed Node.js runtime. |

Optional development software:

- Android Studio with the Android SDK and an emulator for Android builds.
- Visual Studio 2022 with the **Desktop development with C++** workload for
  Windows desktop builds.
- Visual Studio Code or Android Studio as the code editor.
- Java 17 or 21 when running the compiler locally. A project-local JDK may be
  placed under `.tools/jdk21/<jdk-folder>/bin`; the compiler service detects it
  automatically on Windows.

Verify the main tools in PowerShell:

```powershell
git --version
flutter doctor
dart --version
node --version
npm.cmd --version
firebase.cmd --version
```

For a local compiler installation, also verify:

```powershell
g++ --version
javac -version
java -version
```

Install the required command-line tools after Node.js and Flutter are ready:

```powershell
npm.cmd install
npm.cmd install --global firebase-tools
dart pub global activate flutterfire_cli
flutter pub get
```

Firebase project access is also required. Enable Firebase Authentication
(Email/Password), Cloud Firestore, and App Check for the platforms being used.
Deploying Cloud Functions requires a Firebase Blaze plan; the core application,
Firestore, Authentication, and the local compiler can be developed without
deploying Functions.

## Compiler Integration

CoSci includes a small self-hosted compiler gateway for C++, Java, and
JavaScript. The recommended setup packages all runtimes in one container:

```powershell
docker compose -f docker-compose.compiler.yml up -d --build
flutter run -d chrome --dart-define=COMPILER_API_URL=http://localhost:8787/api/v2/execute
```

For local development without Docker, install Node.js, `g++`, and a Java JDK,
then start the compiler and Flutter web app together with one command:

```powershell
npm.cmd run dev:web
```

This command starts the bundled compiler when needed, waits until it is ready,
and launches Chrome with the compiler and secure quiz evaluator URLs configured.
It also reuses a compiler that is already listening on port `8787`.

To run the two processes separately instead, use:

```powershell
npm.cmd run compiler:start
flutter run -d chrome --dart-define=COMPILER_API_URL=http://localhost:8787/api/v2/execute
```

Firebase Hosting only serves static web files and cannot automatically start
Node.js, `g++`, or Java processes. A deployed CoSci build therefore needs a
separately hosted HTTPS compiler service and an explicit `COMPILER_API_URL`.

The same local service also grades quizzes securely at
`http://localhost:8787/quiz/evaluate`. Localhost builds discover this endpoint
automatically. The service needs Firebase Admin credentials so it can verify
learners, read protected answer keys, and save attempts:

```powershell
$env:GOOGLE_APPLICATION_CREDENTIALS="C:\path\to\firebase-adminsdk.json"
npm.cmd run compiler:start
```

For a hosted build, provide the public HTTPS evaluator URL explicitly:

```powershell
flutter build web --dart-define=QUIZ_EVALUATOR_URL=https://your-service.example/quiz/evaluate
```

Check compiler health at:

```text
http://localhost:8787/api/v2/runtimes
```

## Trusted simulation evaluation

Hidden simulation tests are stored in the admin-only
`simulation_private_tests` collection and evaluated by the
`evaluateSimulation` Firebase Function. Configure `COMPILER_API_URL` for the
Function, deploy it, and start Flutter with both endpoints:

```powershell
cd functions
npm install
firebase functions:secrets:set COMPILER_API_URL
firebase deploy --only functions:evaluateSimulation,firestore:rules
flutter run -d chrome --dart-define=COMPILER_API_URL=https://your-compiler.example/api/v2/execute --dart-define=SIMULATION_EVALUATOR_URL=https://REGION-PROJECT.cloudfunctions.net/evaluateSimulation
```

Existing simulations that stored hidden cases in their public `testCases`
field must be opened and saved once by an administrator to migrate those cases
to the private collection.

Production deployments should host the compiler behind HTTPS with rate limits,
request-size limits, execution timeouts, and disabled outbound network access.
Compiler failures are reported as syntax/compilation errors, runtime failures
separately, and successful runs with unexpected output as possible logic errors.

### Render deployment

The repository includes a `render.yaml` Blueprint for deploying the bundled
compiler as a Docker web service. Push the complete project to GitHub, create a
Render Blueprint from that repository, and wait for the `/api/v2/runtimes`
health check to pass. Then rebuild the Flutter site with the service URL:

```powershell
$compilerOrigin = "https://cosci-compiler.onrender.com"
flutter build web --release `
  --dart-define=COMPILER_API_URL="$compilerOrigin/api/v2/execute" `
  --dart-define=QUIZ_EVALUATOR_URL="$compilerOrigin/quiz/evaluate"
firebase.cmd deploy --only hosting --project psueducode-apk
```

Replace the example origin with the exact URL assigned by Render. Keep Firebase
Admin credentials in a Render secret file if online quiz grading is enabled;
never commit the service-account JSON to Git.

Pseudocode execution is outside the implementation scope. CoSci concentrates on
the execution behavior of actual C++, Java, and JavaScript programs.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Seed Accounts

You can seed the default Firebase Authentication + Firestore accounts for:

| Role | Email | Password |
| --- | --- | --- |
| Admin | `admin@psu-educode.app` | `Admin123!` |
| Admin | `admin@psu.edu.ph` | `Admin123!` |
| Student | `student@psu-educode.app` | `Student123!` |
| Professor | `professor@psu-educode.app` | `Professor123!` |

Local MySQL/MariaDB admin account added to `psu_educode_db.users`:

| Role | Email | Password |
| --- | --- | --- |
| Admin | `admin@psu.edu.ph` | `Admin123!` |

Pass the passwords with `--dart-define`:

```powershell
flutter run -d chrome -t tool/seed_accounts.dart `
  --dart-define=PSU_ADMIN_PASSWORD=Admin123! `
  --dart-define=PSU_STUDENT_PASSWORD=Student123! `
  --dart-define=PSU_PROFESSOR_PASSWORD=Professor123!
```

The seeder will create the Firebase Auth users if they do not exist, then upsert
their Firestore role/profile/progress data.
