# Referral System Backend

Backend API for referral system. Users can generate codes, apply them and get rewards.

## Setup

Requirements:
- Python 3.10+
- Django, DRF

```bash
git clone <repo>
cd referralsys

python -m venv venv
venv\Scripts\activate

pip install django djangorestframework djangorestframework-simplejwt
```

Run migrations:
```bash
python manage.py migrate
python manage.py createsuperuser
```

**Important** - need to add reward config in shell:
```bash
python manage.py shell
```
```python
from rewards.models import RewardConfig
RewardConfig.objects.create(reward_type='SIGNUP', reward_value=100, reward_unit='POINTS', is_active=True)
exit()
```

Start:
```bash
python manage.py runserver
```

## APIs

Base url: `http://127.0.0.1:8000/api`

Need to add token in header for most APIs: `Authorization: Bearer <token>`

### Register/Login

Register:
```
POST /api/users/register/
{"username": "test", "password": "test123"}
```

Login:
```
POST /api/users/login/
{"username": "test", "password": "test123"}

returns: {"access": "token...", "refresh": "..."}
```

### Referral stuff

Generate code:
```
POST /api/referral/generate/
returns: {"referral_code": "SVH-ABCD12"}
```

Apply code:
```
POST /api/referral/apply/
{"referral_code": "SVH-ABCD12"}
```

Get summary:
```
GET /api/referral/analytics/summary/
```

List:
```
GET /api/referral/analytics/list/
```

Timeline:
```
GET /api/referral/analytics/timeline/
```

### Rewards

Check rewards:
```
GET /api/rewards/summary/
GET /api/rewards/history/
```

Admin credit:
```
POST /api/rewards/admin/credit/<id>/
```

## How it works

When user applies someone's referral code, system creates a PENDING reward for the referrer. Admin can credit it later.

Rewards are stored in RewardLedger table. Values come from RewardConfig.

## Database

Used 4 tables:
- User (django default)
- Referral (codes and tracking)
- RewardConfig (reward settings)
- RewardLedger (reward records)

## Structure

```
users/      -> auth
referrals/  -> referral logic
rewards/    -> rewards
```

Separated into 3 apps for clean code.

## Validations

- cant use own code
- cant apply referral twice
- code must be valid
- admin only for credit API

## Testing

1. Register user1, login, generate code
2. Register user2, apply user1's code
3. Check user1 rewards - should show pending

curl example:
```bash
curl -X POST http://127.0.0.1:8000/api/users/register/ -H "Content-Type: application/json" -d '{"username":"test","password":"test123"}'
```

Can also test in Postman.

## Issues I faced

Migration problems - had to delete db.sqlite3 and migrations folder multiple times. Make sure to:
1. Set AUTH_USER_MODEL in settings
2. Run makemigrations users first
3. Then referrals, then rewards
4. Then migrate

Also initially added referral_code in User model which caused circular dependency. Had to remove it.

## Notes

- Referral codes format: SVH-XXXXXX (6 chars)
- get_or_create used for idempotent code generation
- Analytics calculated dynamically
- Using SQLite for now, can switch to postgres later

## Production

Would need to:
- Use PostgreSQL
- Set DEBUG=False
- Environment variables for secrets
- gunicorn for deployment

Thats it. Check code for more details.
