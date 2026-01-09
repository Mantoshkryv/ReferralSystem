from django.urls import path
from .views import (
    GenerateReferralCodeView,
    ApplyReferralCodeView,
    ReferralSummaryView,
    ReferralListView,
    ReferralTimelineView
)

urlpatterns = [
    path('generate/', GenerateReferralCodeView.as_view()),
    path('apply/', ApplyReferralCodeView.as_view()),
    path('analytics/summary/', ReferralSummaryView.as_view()),
    path('analytics/list/', ReferralListView.as_view()),
    path('analytics/timeline/', ReferralTimelineView.as_view()),
]
