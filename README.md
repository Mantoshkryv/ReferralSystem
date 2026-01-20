# Referral System - Backend + Frontend

So I built this referral system for my assignment/portfolio. It's basically like those "invite a friend" features you see in apps. Took me a while to get everything working but learned a ton!

## What it does

Users can create an account, generate a unique referral code, and share it with friends. When someone uses their code, both people get reward points. The backend is Django REST API and frontend is a Flutter mobile app.

## Tech I used

**Backend:**
- Django (first time using it properly!)
- Django REST Framework for APIs
- SQLite for now (will change to PostgreSQL later)
- JWT tokens for login

**Frontend:**
- Flutter (also first time making a full app)
- http package for API calls
- shared_preferences to save login token

## Setup Instructions

### Backend Setup

First make sure you have Python installed (I used 3.10)

```bash
# Clone the repo
git clone <repo-link>
cd referral-system/backend

# Make virtual environment (trust me, this saves headaches)
python -m venv venv

# Activate it
# Windows users:
venv\Scripts\activate
# Mac/Linux:
source venv/bin/activate

# Install stuff
pip install -r requirements.txt
```

Now setup the database:

```bash
# Run migrations
python manage.py makemigrations
python manage.py migrate

# Create admin account
python manage.py createsuperuser
# I used: username=admin, password=admin123
```

**IMPORTANT** - You need to add reward configs or it won't work!

```bash
python manage.py shell
```

Then paste this:

```python
from rewards.models import RewardConfig

# For person who owns the code
RewardConfig.objects.create(
    reward_type='SIGNUP',
    reward_value=100,
    reward_unit='POINTS',
    is_active=True
)

# For person who uses the code  
RewardConfig.objects.create(
    reward_type='WELCOME_BONUS',
    reward_value=50,
    reward_unit='POINTS',
    is_active=True
)

exit()
```

Start the server:

```bash
python manage.py runserver 0.0.0.0:8000
```

Keep this running!

### Mobile App Setup

Open a new terminal (keep backend running in the other one!)

```bash
cd mobile_app

# Get all packages
flutter pub get
```

**SUPER IMPORTANT** - Change the API URL!

Go to `lib/config/api_config.dart` and update this:

```dart
// If using Android emulator:
static const String baseUrl = 'http://10.0.2.2:8000/api';

// If using real phone (replace with YOUR laptop's IP):
// Find it with: ipconfig (Windows) or ifconfig (Mac)
// static const String baseUrl = 'http://192.168.1.XXX:8000/api';
```

Run the app:

```bash
flutter run
```

## How to test it

1. Open the app, click Register
2. Make user "alice" with password "test123"
3. Login as alice
4. Go to Referrals tab, click "Generate Code"
5. You'll get something like SVH-AB12CD
6. Click Copy button
7. Logout
8. Register new user "bob" 
9. Login as bob
10. You'll see a green card saying "Have a Referral Code?"
11. Paste alice's code and click Apply
12. Success! Check Rewards tab - should show 50 points
13. Logout and login back as alice
14. Check her Rewards - should show 100 points

## API Endpoints

Base URL: `http://127.0.0.1:8000/api`

**Auth:**
- POST `/users/register/` - sign up
- POST `/users/login/` - get JWT token

**Referrals:**
- POST `/referrals/generate/` - make your code
- POST `/referrals/apply/` - use someone's code
- GET `/referrals/analytics/summary/` - your stats
- GET `/referrals/analytics/list/` - all your referrals

**Rewards:**
- GET `/rewards/summary/` - total points
- GET `/rewards/history/` - list of rewards

All need token in header except register/login:
```
Authorization: Bearer <your-token>
```

## Database Tables

Made 4 tables:

1. **User** - extended Django's user model, added referral_code field
2. **Referral** - stores who referred who
3. **RewardConfig** - settings for reward amounts (100 points, 50 points etc)
4. **RewardLedger** - actual reward records for each user

## Project Structure

```
backend/
├── users/       - login, register stuff
├── referrals/   - referral code logic
├── rewards/     - reward tracking
└── config/      - django settings

mobile_app/
├── lib/
│   ├── models/      - data models
│   ├── services/    - API calls
│   ├── screens/     - UI screens
│   └── config/      - API urls
└── pubspec.yaml
```

## Problems I faced

**Problem 1:** Migration errors everywhere

At first I messed up the migration order and had to delete db.sqlite3 like 5 times. Finally figured out you need to run makemigrations for users FIRST, then referrals, then rewards.

**Problem 2:** Mobile app couldn't connect to backend

Spent 2 hours on this! Issue was I was using `localhost:8000` in the Flutter app but that doesn't work with Android emulator. Had to use `10.0.2.2:8000` instead.

**Problem 3:** Rewards weren't getting created

Turns out I forgot to add WELCOME_BONUS to the reward_type choices in the model. Added it and ran migrations again.

**Problem 4:** Getting duplicate referral records

My initial code was creating a NEW referral record when someone applied a code, THEN updating the old one. So I had 2 records for every referral! Fixed it by only updating the existing record.

**Problem 5:** App showing user IDs instead of names

Backend was sending user IDs but Flutter expected usernames. Had to update the serializers to include actual username fields.

## What I learned

- Django ORM is pretty cool, especially the filter() and aggregate() stuff
- JWT tokens are way better than session cookies for mobile apps
- Always validate user input! (like checking if someone's using their own referral code)
- CORS is important - had to add django-cors-headers
- Flutter's setState is simple but gets messy for bigger apps
- Database indexes actually matter for performance
- Writing good API documentation helps A LOT

## Things I want to add later

- Push notifications when someone uses your code
- Leaderboard to see top referrers
- Referral code QR codes
- Email verification
- Better error messages
- Dark mode in the app
- Charts for referral stats

## Requirements files

**Backend (requirements.txt):**
```
Django==4.2.7
djangorestframework==3.14.0
djangorestframework-simplejwt==5.3.0
django-cors-headers==4.3.1
```

**Frontend (pubspec.yaml):**
```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.1.0
  shared_preferences: ^2.2.2
  share_plus: ^7.2.1
```

## Common Issues

**"Connection refused" in app:**
- Check backend is running: `python manage.py runserver 0.0.0.0:8000`
- Check API URL in `api_config.dart`
- If using real phone, make sure laptop and phone are on same WiFi

**"Invalid referral code":**
- Make sure you applied the backend fixes
- Code is case-sensitive!

**Rewards not showing:**
- Did you create the RewardConfig entries? Run the shell commands from setup

**App crashes:**
- Try `flutter clean` then `flutter pub get`
- Restart the app

## Running in production

Haven't deployed this yet but here's what needs to be done:

1. Switch to PostgreSQL instead of SQLite
2. Set DEBUG=False in Django settings
3. Add environment variables for secrets
4. Use gunicorn instead of Django's dev server
5. Setup nginx as reverse proxy
6. Get SSL certificate for HTTPS
7. Build Flutter app as release APK
8. Update API URL to production domain

## Testing with curl

If you want to test backend without the app:

```bash
# Register
curl -X POST http://127.0.0.1:8000/api/users/register/ \
  -H "Content-Type: application/json" \
  -d '{"username":"test","password":"test123"}'

# Login
curl -X POST http://127.0.0.1:8000/api/users/login/ \
  -H "Content-Type: application/json" \
  -d '{"username":"test","password":"test123"}'

# Save the "access" token from response, then:

# Generate code
curl -X POST http://127.0.0.1:8000/api/referrals/generate/ \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

## Notes

- Referral codes are in format SVH-XXXXXX (6 random chars)
- Rewards start as PENDING, admin has to approve them
- Users can only use one referral code (has_used_referral flag)
- Can't refer yourself (validation in place)
- Deleted a lot of test data while debugging so user IDs might start from like 10 instead of 1

## File structure

```
.
├── README.md (this file)
├── backend/
│   ├── users/
│   │   ├── models.py
│   │   ├── views.py
│   │   ├── serializers.py
│   │   └── urls.py
│   ├── referrals/
│   │   ├── models.py
│   │   ├── views.py
│   │   ├── serializers.py
│   │   └── urls.py
│   ├── rewards/
│   │   ├── models.py
│   │   ├── views.py
│   │   ├── serializers.py
│   │   └── urls.py
│   ├── config/
│   │   ├── settings.py
│   │   └── urls.py
│   ├── manage.py
│   └── requirements.txt
└── mobile_app/
    ├── lib/
    │   ├── main.dart
    │   ├── config/
    │   │   └── api_config.dart
    │   ├── models/
    │   │   ├── user.dart
    │   │   ├── referral.dart
    │   │   └── reward.dart
    │   ├── services/
    │   │   ├── auth_service.dart
    │   │   └── api_service.dart
    │   └── screens/
    │       ├── login_screen.dart
    │       ├── register_screen.dart
    │       ├── home_screen.dart
    │       ├── referral_screen.dart
    │       └── rewards_screen.dart
    └── pubspec.yaml
```

## Credits

Learned a lot from:
- Django docs (especially the REST framework part)
- Flutter documentation
- Stack Overflow (obviously)
- YouTube tutorials on JWT authentication

## Contact

If something's broken or you have questions, open an issue or email me at [your-email]

## License

MIT - do whatever you want with it

---

Built this while learning Django and Flutter. It's not perfect but it works! Feel free to suggest improvements.
