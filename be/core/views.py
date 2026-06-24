from rest_framework import status, viewsets
from rest_framework.decorators import api_view
from rest_framework.response import Response

# Create your views here

# Example ViewSet
# class ExampleViewSet(viewsets.ModelViewSet):
#     queryset = Example.objects.all()
#     serializer_class = ExampleSerializer


@api_view(['GET'])
def health_check(request):
    """
    Simple health check endpoint
    """
    return Response({
        'status': 'ok',
        'message': 'API is running'
    })
