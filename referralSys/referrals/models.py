from django.db import models

from django.db import models
from django.conf import settings

User = settings.AUTH_USER_MODEL

"""
This model stores referral information.
One referral code belongs to one user.
Another user may use that referral code.
"""

class Referral(models.Model):
    referral_code = models.CharField(max_length=20, unique=True)

    # User who owns the referral code
    referred_by = models.ForeignKey(
        User,
        related_name='referrals',
        on_delete=models.CASCADE
    )

    referred_at = models.DateTimeField(auto_now_add=True)

    # User who used the referral code (nullable)
    referral_code_used = models.ForeignKey(
        User,
        null=True,
        blank=True,
        related_name='used_referrals',
        on_delete=models.SET_NULL
    )

    referral_used_at = models.DateTimeField(null=True, blank=True)

    def __str__(self):
        return f"{self.referral_code} by {self.referred_by}"
