from django.urls import path

from . import views

urlpatterns = [
    path("register/", views.RegisterView.as_view(), name="register"),
    path("token/", views.LoginView.as_view(), name="token"),
    path("token/refresh/", views.RefreshTokenView.as_view(), name="token-refresh"),
    path("logout/", views.LogoutView.as_view(), name="logout"),
]
