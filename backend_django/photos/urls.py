from django.urls import path

from . import views

urlpatterns = [
    path("upscale/", views.UpscaleView.as_view(), name="upscale"),
    path("bestcut/", views.BestCutView.as_view(), name="bestcut"),
    path("", views.PhotoListView.as_view(), name="photo-list"),
    path("<uuid:photo_id>/", views.PhotoDetailView.as_view(), name="photo-detail"),
]
