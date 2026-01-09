from django.contrib.auth.models import AbstractUser
from django.db import models

class User(AbstractUser):
    """
    Custom user model.
    We extend AbstractUser to keep Django auth working.
    """
    referral_code = models.CharField(
        max_length=20,
        unique=True,
        null=True,
        blank=True
    )

    def __str__(self):
        return self.username
