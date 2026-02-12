from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.response import Response
from rest_framework import status
from rest_framework_simplejwt.tokens import RefreshToken
from django.contrib.auth.models import User
from django.conf import settings
import requests as py_requests
from google.oauth2 import id_token
from google.auth.transport import requests as google_requests
from .models import Todo
from .serializers import TodoSerializer


def _verify_google_token(token):
    """
    Try to verify as ID token first (Flutter sends this).
    If that fails, try as access token (Next.js implicit flow sends this).
    Returns dict with email, name, picture.
    """
    # 1) Try as ID token
    try:
        idinfo = id_token.verify_oauth2_token(token, google_requests.Request())
        return {
            'email': idinfo['email'],
            'name': idinfo.get('name', ''),
            'picture': idinfo.get('picture', ''),
        }
    except ValueError:
        pass

    # 2) Try as access token — call Google's userinfo endpoint
    resp = py_requests.get(
        'https://www.googleapis.com/oauth2/v3/userinfo',
        headers={'Authorization': f'Bearer {token}'},
        timeout=10,
    )
    if resp.status_code == 200:
        data = resp.json()
        return {
            'email': data['email'],
            'name': data.get('name', ''),
            'picture': data.get('picture', ''),
        }

    raise ValueError('Invalid Google token')


@api_view(['POST'])
@permission_classes([AllowAny])
def google_login(request):
    """
    Receive a Google token (ID token or access token), verify it,
    create/get user, return JWT.
    """
    token = request.data.get('token')
    if not token:
        return Response({'error': 'Token is required'}, status=status.HTTP_400_BAD_REQUEST)

    try:
        info = _verify_google_token(token)
        email = info['email']
        name = info['name']
        picture = info['picture']

        # Create or get the Django user
        user, created = User.objects.get_or_create(
            username=email,
            defaults={
                'email': email,
                'first_name': name.split(' ')[0] if name else '',
                'last_name': ' '.join(name.split(' ')[1:]) if name else '',
            }
        )

        # Generate JWT tokens
        refresh = RefreshToken.for_user(user)

        return Response({
            'access': str(refresh.access_token),
            'refresh': str(refresh),
            'user': {
                'email': user.email,
                'name': name,
                'picture': picture,
            }
        })

    except ValueError as e:
        return Response({'error': f'Invalid token: {str(e)}'}, status=status.HTTP_401_UNAUTHORIZED)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def me(request):
    """Return current user info."""
    user = request.user
    return Response({
        'email': user.email,
        'name': f'{user.first_name} {user.last_name}'.strip(),
    })


@api_view(['GET', 'POST'])
@permission_classes([IsAuthenticated])
def todo_list(request):
    """
    GET  -> return todos for the logged-in user
    POST -> create a new todo for the logged-in user
    """
    if request.method == 'GET':
        todos = Todo.objects.filter(user=request.user).order_by('-id')
        serializer = TodoSerializer(todos, many=True)
        return Response(serializer.data)

    if request.method == 'POST':
        serializer = TodoSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save(user=request.user)
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['PUT', 'DELETE'])
@permission_classes([IsAuthenticated])
def todo_detail(request, pk):
    """
    PUT    -> update a todo (only if owned by user)
    DELETE -> delete a todo (only if owned by user)
    """
    try:
        todo = Todo.objects.get(pk=pk, user=request.user)
    except Todo.DoesNotExist:
        return Response(status=status.HTTP_404_NOT_FOUND)

    if request.method == 'PUT':
        serializer = TodoSerializer(todo, data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    if request.method == 'DELETE':
        todo.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)
