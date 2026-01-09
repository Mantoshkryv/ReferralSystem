# referrals/serializers.py

from rest_framework import serializers
from .models import Referral

"""
Serializer used for referral analytics and listing.
"""

class ReferralSerializer(serializers.ModelSerializer):
    status = serializers.SerializerMethodField()

    class Meta:
        model = Referral
        fields = [
            'referral_code',
            'referral_code_used',
            'referral_used_at',
            'status'
        ]

    def get_status(self, obj):
        if obj.referral_code_used:
            return "SUCCESS"
        return "PENDING"
