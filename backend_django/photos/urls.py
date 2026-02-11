from django.urls import path

from . import views

urlpatterns = [
    path("upscale", views.UpscaleView.as_view()),
    path("bestcut", views.BestCutView.as_view()),
    path("photos", views.PhotoListView.as_view()),
    path("photos/<uuid:photo_id>", views.PhotoDetailView.as_view()),
]
