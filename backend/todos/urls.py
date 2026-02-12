from django.urls import path
from . import views

urlpatterns = [
    path('api/auth/google/', views.google_login),
    path('api/auth/me/', views.me),
    path('api/todos/', views.todo_list),
    path('api/todos/<int:pk>/', views.todo_detail),
]
