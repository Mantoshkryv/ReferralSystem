# users/serializers.py

from rest_framework import serializers
from .models import User

"""
This serializer is used for user registration.
We keep it simple and readable.
"""

class RegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True)

    class Meta:
        model = User
        fields = ['id', 'username', 'password']

    def create(self, validated_data):
        # Use Django's built-in method to hash password
        user = User.objects.create_user(
            username=validated_data['username'],
            password=validated_data['password']
        )
        return user
