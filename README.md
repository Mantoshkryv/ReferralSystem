# Referral System API

Backend API for user referrals and rewards. Built with Django + DRF.

## What it does

Users can generate referral codes, share them with friends. When someone signs up using a referral code, the referrer gets reward points. There's also analytics to see how many people used your code.

## Setup

You need Python 3.10+

```bash
git clone <repo-url>
cd referralsys

python -m venv venv
venv\Scripts\activate  # windows
source venv/bin/activate  # mac/linux

pip install django djangorestframework djangorestframework-simplejwt
```

Run migrations:
```bash
python manage.py migrate
```

Create admin user:
```bash
python manage.py createsuperuser
```

**Important:** Add reward config before testing. Open shell and run:
```bash
python manage.py shell
```
```python
from rewards.models import RewardConfig
RewardConfig.objects.create(reward_type='SIGNUP', reward_value=100, reward_unit='POINTS', is_active=True)
exit()
```

Start server:
```bash
python manage.py runserver
```

## APIs

Base URL: `http://127.0.0.1:8000/api`

### Auth

Register:
```
POST /api/users/register/
{"username": "test", "password": "pass123"}
```

Login (get JWT token):
```
POST /api/users/login/
{"username": "test", "password": "pass123"}

Returns: {"access": "token...", "refresh": "token..."}
```

Use token in headers: `Authorization: Bearer <token>`

### Referrals

Generate your code:
```
POST /api/referral/generate/
Returns: {"referral_code": "SVH-A1B2C3"}
```

Apply someone's code:
```
POST /api/referral/apply/
{"referral_code": "SVH-A1B2C3"}
```

Analytics:
```
GET /api/referral/analytics/summary/
GET /api/referral/analytics/list/
GET /api/referral/analytics/timeline/
```

### Rewards

Check your rewards:
```
GET /api/rewards/summary/
GET /api/rewards/history/
```

Admin credit reward:
```
POST /api/rewards/admin/credit/<id>/
(admin only)
```

## How it works

When user B applies user A's referral code:
1. Referral table gets updated with user B's info
2. A PENDING reward is created for user A
3. Admin can later credit the reward to make it active

Reward amounts come from RewardConfig table, not hardcoded.

## Database

- **User**: Django's built-in user model
- **Referral**: stores codes and tracks who used them
- **RewardConfig**: defines reward amounts (configurable)
- **RewardLedger**: tracks all reward transactions

Foreign keys link everything together.

## Testing

Quick test flow:

1. Register user1, login, generate referral code
2. Register user2, login, apply user1's code
3. Check user1's rewards - should see PENDING reward
4. Admin can credit it

Example with curl:
```bash
# Register
curl -X POST http://127.0.0.1:8000/api/users/register/ -H "Content-Type: application/json" -d '{"username":"john","password":"test123"}'

# Login
curl -X POST http://127.0.0.1:8000/api/users/login/ -H "Content-Type: application/json" -d '{"username":"john","password":"test123"}'

# Generate code (add token from login)
curl -X POST http://127.0.0.1:8000/api/referral/generate/ -H "Authorization: Bearer <token>"
```

## Notes

- Referral codes format: SVH-XXXXXX (6 random chars)
- User can only apply one referral code
- Can't use your own code
- Generating code multiple times returns same code
- SQLite for local dev, can switch to PostgreSQL
- JWT tokens expire in 5 min

## Structure

```
referralsys/
├── users/       - auth stuff
├── referrals/   - referral logic
├── rewards/     - reward system
└── referral_system/  - settings
```

Kept it simple with 3 apps instead of putting everything in one place.

## Issues I ran into

Had migration issues initially because of custom user model. Fixed by deleting db and migrations, then recreating in correct order (users first, then referrals, then rewards).

Make sure AUTH_USER_MODEL is set before first migration.

## Production

For production you'd want to:
- Use PostgreSQL instead of SQLite
- Set DEBUG=False
- Use environment variables for secrets
- Deploy with gunicorn or similar
- Add CORS if there's a frontend

## Validation

- Self-referral blocked
- Duplicate referral blocked  
- Proper error messages
- Admin endpoints check permissions

Analytics are calculated on-the-fly, not stored.

---

That's pretty much it. Check the code for implementation details.
