import random
import string

from django.utils import timezone
from django.db.models import Count

from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, IsAdminUser
from rest_framework import status

from .models import Referral
from .serializers import ReferralSerializer
from rewards.models import RewardConfig, RewardLedger
import logging
referral_logger = logging.getLogger("referral")
kpi_logger = logging.getLogger("kpi")
admin_logger = logging.getLogger("admin")
error_logger = logging.getLogger("error")


# -------------------------------------------------
# Helper function to generate referral code
# -------------------------------------------------
def generate_referral_code():
    """
    Generates a simple referral code.
    Example format: SVH-AB12CD
    """
    return "SVH-" + ''.join(
        random.choices(string.ascii_uppercase + string.digits, k=6)
    )


# -------------------------------------------------
# Generate Referral Code API
# -------------------------------------------------
class GenerateReferralCodeView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        """
        Generates a referral code for the logged-in user.
        If the user already has one, returns the same code.
        This keeps the operation idempotent.
        """

        referral, created = Referral.objects.get_or_create(
            referred_by=request.user,
            defaults={
                'referral_code': generate_referral_code()
            }
        )

        return Response(
            {"referral_code": referral.referral_code},
            status=status.HTTP_200_OK
        )


# -------------------------------------------------
# Apply Referral Code API
# -------------------------------------------------
class ApplyReferralCodeView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        """
        Allows a user to apply a referral code.
        Handles validations like:
        - Invalid code
        - Self referral
        - Referral reuse
        """

        code = request.data.get("referral_code")

        if not code:
            return Response(
                {"error": "Referral code is required"},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Check if referral code exists
        try:
            referral = Referral.objects.get(referral_code=code)
        except Referral.DoesNotExist:
            return Response(
                {"error": "Invalid referral code"},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Prevent self-referral
        if referral.referred_by == request.user:
            return Response(
                {"error": "You cannot use your own referral code"},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Prevent using referral more than once
        if Referral.objects.filter(referral_code_used=request.user).exists():
            return Response(
                {"error": "Referral code already used"},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Apply referral
        referral.referral_code_used = request.user
        referral.referral_used_at = timezone.now()
        referral.save()

        # ---------------------------------------------
        # Create PENDING reward for the referrer
        # ---------------------------------------------
        config = RewardConfig.objects.filter(
            reward_type='SIGNUP',
            is_active=True
        ).first()

        if config:
            RewardLedger.objects.create(
                user=referral.referred_by,
                referral=referral,
                reward_type=config.reward_type,
                reward_value=config.reward_value,
                reward_unit=config.reward_unit,
                status='PENDING'
            )

        return Response(
            {"message": "Referral applied successfully"},
            status=status.HTTP_200_OK
        )


# -------------------------------------------------
# Referral Summary API
# -------------------------------------------------
class ReferralSummaryView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        """
        Returns referral summary for the logged-in user:
        - Total referrals
        - Successful referrals
        - Conversion rate
        """

        total_referrals = Referral.objects.filter(
            referred_by=request.user
        ).count()

        successful_referrals = Referral.objects.filter(
            referred_by=request.user,
            referral_code_used__isnull=False
        ).count()

        conversion_rate = "0%"
        if total_referrals > 0:
            conversion_rate = f"{int((successful_referrals / total_referrals) * 100)}%"

        referral = Referral.objects.filter(
            referred_by=request.user
        ).first()

        return Response({
            "my_referral_code": referral.referral_code if referral else None,
            "total_referrals": total_referrals,
            "successful_referrals": successful_referrals,
            "conversion_rate": conversion_rate
        })


# -------------------------------------------------
# Referral List API
# -------------------------------------------------
class ReferralListView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        """
        Returns list of referrals created by the user
        with their current status.
        """

        referrals = Referral.objects.filter(referred_by=request.user)
        serializer = ReferralSerializer(referrals, many=True)
        return Response(serializer.data)


# -------------------------------------------------
# Referral Timeline API
# -------------------------------------------------
class ReferralTimelineView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        """
        Returns referral count grouped by date.
        Used for analytics timeline.
        """

        timeline = (
            Referral.objects
            .filter(referred_by=request.user)
            .extra(select={'date': "date(referred_at)"})
            .values('date')
            .annotate(count=Count('id'))
            .order_by('date')
        )

        return Response(timeline)
# -------------------------------------------------
# Admin: Top Referrers API
# -------------------------------------------------
class TopReferrersView(APIView):
    permission_classes = [IsAdminUser]

    def get(self, request):
        """
        Returns top referrers by successful referral count.
        Admin only endpoint.
        """
        
        top_referrers = (
            Referral.objects
            .filter(referral_code_used__isnull=False)
            .values('referred_by')
            .annotate(successful_referrals=Count('id'))
            .order_by('-successful_referrals')
        )
        
        return Response(top_referrers)


