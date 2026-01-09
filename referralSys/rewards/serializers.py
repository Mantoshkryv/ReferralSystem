from rest_framework import serializers
from .models import RewardLedger

"""
Serializer for reward history.
"""

class RewardLedgerSerializer(serializers.ModelSerializer):

    class Meta:
        model = RewardLedger
        fields = [
            'id',
            'reward_type',
            'reward_value',
            'reward_unit',
            'status',
            'created_at'
        ]
