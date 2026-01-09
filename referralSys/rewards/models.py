from django.db import models
from django.conf import settings
from referrals.models import Referral

User = settings.AUTH_USER_MODEL

# stores reward settings 
class RewardConfig(models.Model):
    reward_type = models.CharField(
        max_length=20,
        choices=[
            ('SIGNUP', 'SIGNUP'),
            ('FIRST_ORDER', 'FIRST_ORDER')
        ]
    )
    reward_value = models.IntegerField()
    reward_unit = models.CharField(
        max_length=10,
        choices=[
            ('POINTS', 'POINTS'),
            ('CASH', 'CASH')
        ]
    )
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.reward_type} - {self.reward_value} {self.reward_unit}"


# tracks all reward transactions
class RewardLedger(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, db_index=True)  
    referral = models.ForeignKey(Referral, on_delete=models.CASCADE)

    reward_type = models.CharField(max_length=20)
    reward_value = models.IntegerField()
    reward_unit = models.CharField(max_length=10)

    # status can be pending, credited or revoked
    status = models.CharField(
        max_length=10,
        choices=[
            ('PENDING', 'PENDING'),
            ('CREDITED', 'CREDITED'),
            ('REVOKED', 'REVOKED')
        ]
    )

    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.user} - {self.reward_type} - {self.status}"
