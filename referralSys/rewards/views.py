from django.shortcuts import render
from django.db.models import Sum
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, IsAdminUser
from rest_framework import status

from .models import RewardLedger
from .serializers import RewardLedgerSerializer

# -------------------------------
# User Reward Summary
# -------------------------------
class RewardSummaryView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        """
        Returns total earned, pending, and credited rewards.
        Values are calculated dynamically (not stored).
        """

        pending = RewardLedger.objects.filter(
            user=request.user,
            status='PENDING'
        ).aggregate(total=Sum('reward_value'))['total'] or 0

        credited = RewardLedger.objects.filter(
            user=request.user,
            status='CREDITED'
        ).aggregate(total=Sum('reward_value'))['total'] or 0

        unit = RewardLedger.objects.filter(
            user=request.user
        ).first()

        return Response({
            "total_earned": pending + credited,
            "pending": pending,
            "credited": credited,
            "unit": unit.reward_unit if unit else "POINTS"
        })


# -------------------------------
# User Reward History
# -------------------------------
class RewardHistoryView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        """
        Returns reward transaction history for the user.
        """

        rewards = RewardLedger.objects.filter(user=request.user).order_by('-created_at')
        serializer = RewardLedgerSerializer(rewards, many=True)
        return Response(serializer.data)


# -------------------------------
# Admin: Credit Reward
# -------------------------------
class CreditRewardView(APIView):
    permission_classes = [IsAdminUser]

    def post(self, request, reward_id):
        """
        Admin can credit a pending reward.
        Only PENDING → CREDITED transition is allowed.
        """

        try:
            reward = RewardLedger.objects.get(id=reward_id)
        except RewardLedger.DoesNotExist:
            return Response(
                {"error": "Reward not found"},
                status=status.HTTP_404_NOT_FOUND
            )

        if reward.status != 'PENDING':
            return Response(
                {"error": "Only pending rewards can be credited"},
                status=status.HTTP_400_BAD_REQUEST
            )

        reward.status = 'CREDITED'
        reward.save()

        return Response(
            {"message": "Reward credited successfully"},
            status=status.HTTP_200_OK
        )
