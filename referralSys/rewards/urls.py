from django.urls import path
from .views import (
    RewardSummaryView,
    RewardHistoryView,
    CreditRewardView
)

urlpatterns = [
    path('summary/', RewardSummaryView.as_view()),
    path('history/', RewardHistoryView.as_view()),
    path('admin/credit/<int:reward_id>/', CreditRewardView.as_view()),
]
